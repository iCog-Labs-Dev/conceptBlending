import nltk
from nltk.corpus import wordnet as wn

try:
    wn.synsets("test")
except LookupError:
    nltk.download('wordnet')
    nltk.download('omw-1.4')


def _clean_name(synset_name):
    return synset_name.split('.')[0].replace('_', ' ')


def get_wordnet_edges(concept, limit=20, pos=None):
    """
    Returns edges in the same shape conceptnet_adapter.get_conceptnet_edges
    produces, so it's a drop-in fallback for downstream code.
    """
    synsets = wn.synsets(concept, pos=pos)
    if not synsets:
        return []

    primary = synsets[0]  # most frequent sense; WordNet orders by usage
    edges = []

    for hyper in primary.hypernyms():
        edges.append({
            "relation": "IsA",
            "start": concept,
            "end": _clean_name(hyper.name()),
            "weight": None,
            "surftext": f"{concept} is a type of {_clean_name(hyper.name())}",
        })

    for hypo in primary.hyponyms()[:5]:
        edges.append({
            "relation": "HasType",
            "start": concept,
            "end": _clean_name(hypo.name()),
            "weight": None,
            "surftext": f"{_clean_name(hypo.name())} is a type of {concept}",
        })

    for part in primary.part_meronyms():
        edges.append({
            "relation": "PartOf",
            "start": _clean_name(part.name()),
            "end": concept,
            "weight": None,
            "surftext": f"{_clean_name(part.name())} is part of {concept}",
        })

    for holo in primary.member_holonyms():
        edges.append({
            "relation": "AtLocation",
            "start": concept,
            "end": _clean_name(holo.name()),
            "weight": None,
            "surftext": f"{concept} is found among {_clean_name(holo.name())}",
        })

    for lemma in primary.lemmas():
        for related in lemma.derivationally_related_forms():
            edges.append({
                "relation": "RelatedTo",
                "start": concept,
                "end": related.name().replace('_', ' '),
                "weight": None,
                "surftext": f"{concept} is related to {related.name()}",
            })

    return edges[:limit]