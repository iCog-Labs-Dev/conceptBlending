#include <SWI-Prolog.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

extern char *rust_pathmap_kb(const char *command, const char *input);
extern void rust_pathmap_kb_string_free(char *pointer);

typedef struct {
    const unsigned char *pointer;
    size_t length;
} byte_slice_t;

typedef struct {
    uint8_t family;
    byte_slice_t feature;
    byte_slice_t world;
    byte_slice_t payload;
    byte_slice_t evidence;
    byte_slice_t payload_evidence;
    double strength;
    double confidence;
    double payload_strength;
    double payload_confidence;
    uint8_t flags;
} row_view_t;

typedef int (*row_visitor_t)(void *context, const row_view_t *row);

extern char *rust_pathmap_kb_visit(const char *command, const char *input,
                                   row_visitor_t visitor, void *context);

typedef struct {
    term_t groups[6];
    term_t tails[6];
    term_t flat;
    term_t flat_tail;
    predicate_t sread;
} row_context_t;

#define PARSED_CACHE_BUCKETS 4096

typedef struct parsed_cache_entry {
    struct parsed_cache_entry *next;
    size_t length;
    uint64_t hash;
    char *text;
    record_t record;
} parsed_cache_entry_t;

static parsed_cache_entry_t *parsed_cache[PARSED_CACHE_BUCKETS];
static pthread_mutex_t parsed_cache_mutex = PTHREAD_MUTEX_INITIALIZER;

static uint64_t hash_bytes(const unsigned char *bytes, size_t length)
{
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t index = 0; index < length; ++index) {
        hash ^= bytes[index];
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

static record_t cached_record(byte_slice_t value, uint64_t hash)
{
    size_t bucket = hash % PARSED_CACHE_BUCKETS;
    record_t record = NULL;
    pthread_mutex_lock(&parsed_cache_mutex);
    for (parsed_cache_entry_t *entry = parsed_cache[bucket]; entry;
         entry = entry->next) {
        if (entry->hash == hash && entry->length == value.length &&
            memcmp(entry->text, value.pointer, value.length) == 0) {
            record = entry->record;
            break;
        }
    }
    pthread_mutex_unlock(&parsed_cache_mutex);
    return record;
}

static void cache_record(byte_slice_t value, uint64_t hash, record_t record)
{
    size_t bucket = hash % PARSED_CACHE_BUCKETS;
    parsed_cache_entry_t *entry = malloc(sizeof(*entry));
    char *text = malloc(value.length);
    if (!entry || (!text && value.length != 0)) {
        free(entry);
        free(text);
        PL_erase(record);
        return;
    }
    memcpy(text, value.pointer, value.length);
    entry->length = value.length;
    entry->hash = hash;
    entry->text = text;
    entry->record = record;

    pthread_mutex_lock(&parsed_cache_mutex);
    entry->next = parsed_cache[bucket];
    parsed_cache[bucket] = entry;
    pthread_mutex_unlock(&parsed_cache_mutex);
}

static int put_atom_slice(term_t term, byte_slice_t value)
{
    if (!value.pointer) {
        return PL_put_nil(term);
    }
    return PL_put_chars(term, PL_ATOM | REP_UTF8, value.length,
                        (const char *)value.pointer);
}

static int put_parsed_slice(row_context_t *context, term_t term,
                            byte_slice_t value)
{
    if (!value.pointer) {
        return PL_put_nil(term);
    }

    uint64_t hash = hash_bytes(value.pointer, value.length);
    record_t record = cached_record(value, hash);
    if (record) {
        return PL_recorded(record, term);
    }

    term_t arguments = PL_new_term_refs(2);
    if (!PL_put_chars(arguments, PL_STRING | REP_UTF8, value.length,
                      (const char *)value.pointer) ||
        !PL_put_variable(arguments + 1) ||
        !PL_call_predicate(NULL, PL_Q_NODEBUG | PL_Q_CATCH_EXCEPTION,
                           context->sread, arguments)) {
        return FALSE;
    }
    if (!PL_put_term(term, arguments + 1)) {
        return FALSE;
    }
    record = PL_record(term);
    if (record) {
        cache_record(value, hash, record);
    }
    return TRUE;
}

static int put_list(term_t list, const term_t *items, size_t count)
{
    term_t tail = PL_new_term_ref();
    if (!PL_put_nil(list)) {
        return FALSE;
    }
    for (size_t index = count; index > 0; --index) {
        if (!PL_put_term(tail, list) ||
            !PL_cons_list(list, items[index - 1], tail)) {
            return FALSE;
        }
    }
    return TRUE;
}

static int put_tv(term_t term, double strength, double confidence)
{
    term_t items = PL_new_term_refs(3);
    return PL_put_atom_chars(items, "stv") &&
           PL_put_float(items + 1, strength) &&
           PL_put_float(items + 2, confidence) &&
           put_list(term, (term_t[]){items, items + 1, items + 2}, 3);
}

static int put_row(row_context_t *context, term_t term,
                   const row_view_t *row)
{
    static const char *tags[] = {
        "sort-row", "operation", "predicate", "axiom", "property",
        "property-world"
    };
    if (row->family >= 6) {
        return FALSE;
    }

    term_t items = PL_new_term_refs(7);
    if (!PL_put_atom_chars(items, tags[row->family])) {
        return FALSE;
    }

    if (row->family == 2 || row->family == 3) {
        if (!put_parsed_slice(context, items + 1, row->feature)) {
            return FALSE;
        }
    } else if (!put_atom_slice(items + 1, row->feature)) {
        return FALSE;
    }

    if (row->family == 1) {
        if (!put_parsed_slice(context, items + 2, row->payload) ||
            !put_tv(items + 3, row->strength, row->confidence)) {
            return FALSE;
        }
        if ((row->flags & 1) != 0) {
            if (!put_tv(items + 4, row->payload_strength,
                        row->payload_confidence)) {
                return FALSE;
            }
        } else if (!PL_put_nil(items + 4)) {
            return FALSE;
        }
        if (!put_atom_slice(items + 5, row->evidence) ||
            !put_atom_slice(items + 6, row->payload_evidence)) {
            return FALSE;
        }
        return put_list(term,
                        (term_t[]){items, items + 1, items + 2, items + 3,
                                   items + 4, items + 5, items + 6},
                        7);
    }

    if (row->family == 5) {
        if (!put_atom_slice(items + 2, row->world) ||
            !put_tv(items + 3, row->strength, row->confidence) ||
            !put_atom_slice(items + 4, row->evidence)) {
            return FALSE;
        }
        return put_list(term,
                        (term_t[]){items, items + 1, items + 2, items + 3,
                                   items + 4},
                        5);
    }

    if (!put_tv(items + 2, row->strength, row->confidence) ||
        !put_atom_slice(items + 3, row->evidence)) {
        return FALSE;
    }
    return put_list(term, (term_t[]){items, items + 1, items + 2, items + 3},
                    4);
}

static int append_row(term_t tail, term_t row)
{
    term_t pair = PL_new_term_refs(2);
    if (!PL_put_variable(pair) || !PL_put_variable(pair + 1) ||
        !PL_unify_list(tail, pair, pair + 1) || !PL_unify(pair, row)) {
        return FALSE;
    }
    return PL_put_term(tail, pair + 1);
}

static int visit_row(void *opaque_context, const row_view_t *view)
{
    row_context_t *context = (row_context_t *)opaque_context;
    term_t row = PL_new_term_ref();
    if (!put_row(context, row, view)) {
        return FALSE;
    }
    return append_row(context->tails[view->family], row) &&
           append_row(context->flat_tail, row);
}

static foreign_t pl_pathmap_kb(term_t command_term, term_t input_term,
                               term_t output_term)
{
    char *command;
    char *input;
    size_t command_length;
    size_t input_length;
    int flags = CVT_ATOM | CVT_STRING | CVT_LIST | CVT_EXCEPTION | REP_UTF8;

    if (!PL_get_nchars(command_term, &command_length, &command, flags) ||
        !PL_get_nchars(input_term, &input_length, &input, flags)) {
        return FALSE;
    }

    char *output = rust_pathmap_kb(command, input);
    if (!output) {
        return FALSE;
    }
    int unified = PL_unify_chars(output_term, PL_STRING | REP_UTF8,
                                 (size_t)-1, output);
    rust_pathmap_kb_string_free(output);
    return unified;
}

static foreign_t pl_pathmap_kb_typed(term_t command_term, term_t input_term,
                                     term_t output_term)
{
    char *command;
    char *input;
    size_t command_length;
    size_t input_length;
    int flags = CVT_ATOM | CVT_STRING | CVT_LIST | CVT_EXCEPTION | REP_UTF8;
    row_context_t context;

    if (!PL_get_nchars(command_term, &command_length, &command, flags) ||
        !PL_get_nchars(input_term, &input_length, &input, flags)) {
        return FALSE;
    }

    for (size_t family = 0; family < 6; ++family) {
        context.groups[family] = PL_new_term_ref();
        context.tails[family] = PL_new_term_ref();
        if (!PL_put_variable(context.groups[family]) ||
            !PL_put_term(context.tails[family], context.groups[family])) {
            return FALSE;
        }
    }
    context.flat = PL_new_term_ref();
    context.flat_tail = PL_new_term_ref();
    if (!PL_put_variable(context.flat) ||
        !PL_put_term(context.flat_tail, context.flat)) {
        return FALSE;
    }
    context.sread = PL_predicate("sread", 2, NULL);

    char *error = rust_pathmap_kb_visit(command, input, visit_row, &context);
    if (error) {
        PL_warning("%s", error);
        rust_pathmap_kb_string_free(error);
        return FALSE;
    }

    for (size_t family = 0; family < 6; ++family) {
        if (!PL_unify_nil(context.tails[family])) {
            return FALSE;
        }
    }
    if (!PL_unify_nil(context.flat_tail)) {
        return FALSE;
    }

    if (strcmp(command, "build-specification") == 0) {
        term_t tag = PL_new_term_ref();
        term_t result = PL_new_term_ref();
        if (!PL_put_atom_chars(tag, "specification") ||
            !put_list(result,
                      (term_t[]){tag, context.groups[0], context.groups[1],
                                 context.groups[2], context.groups[3],
                                 context.groups[4], context.groups[5]},
                      7)) {
            return FALSE;
        }
        return PL_unify(output_term, result);
    }
    return PL_unify(output_term, context.flat);
}

install_t install(void)
{
    PL_register_foreign("pathmap_kb", 3, pl_pathmap_kb, 0);
    PL_register_foreign("pathmap_kb_typed", 3, pl_pathmap_kb_typed, 0);
}
