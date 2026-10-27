from __future__ import annotations

from .engine import ScoreEngine

TRIPLETS: dict[str, tuple[str, str, str]] = {

                    # capableOf — physical actions (ceiling, model is confident here)
    "dog_bark":              ("dog",         "capableOf", "bark"),
    "bird_fly":              ("bird",        "capableOf", "fly"),
    "fish_swim":             ("fish",        "capableOf", "swim"),
    "plant_grow":            ("plant",       "capableOf", "grow"),
    "fire_burn":             ("fire",        "capableOf", "burn"),
    "snake_bite":            ("snake",       "capableOf", "bite"),
    "heart_pumping_blood":   ("heart",       "capableOf", "pumping_blood"),
    "eye_see":               ("eye",         "capableOf", "see"),

                    # capableOf — cognitive (model scores mid-range, shown to be stable)
    "person_think":          ("person",      "capableOf", "think"),
    "person_reason":         ("person",      "capableOf", "reason"),
    "human_reasoning":       ("humans",      "capableOf", "reasoning"),
    "human_learn":           ("human",       "capableOf", "learn"),
    "human_learning":           ("human",       "capableOf", "learning"),
    "human_remember":        ("human",       "capableOf", "remember"),
    "human_communicate":     ("human",       "capableOf", "communicate"),

                    # capableOf — clear false (inanimate subject, animate action)
    "rock_reason":           ("rock",        "capableOf", "reasoning"),
    "stone_think":           ("stone",       "capableOf", "think"),
    "water_vote":            ("water",       "capableOf", "vote"),
    "table_walk":            ("table",       "capableOf", "walk"),  # soft false, because table has leg, leg capble walking

                    # capableOf — specificity: same action, subject gets more specific
    "human_reason_base":     ("human",       "capableOf", "reason"),
    "human_reason":     ("human",       "capableOf", "reasoning"),
    "human_baby_reasoning":("human_baby",    "capableOf", "reasoning") ,
    "smart_human_reason":    ("smart human", "capableOf", "reasoning"),
    "cat_reason":            ("cat",         "capableOf", "reasoning"),

                    # hasProperty — perceptual / physical (model is confident, near ceiling)
    "fire_hot":              ("fire",        "hasProperty", "hot"),
    "ice_cold":              ("ice",         "hasProperty", "cold"),
    "sugar_sweet":           ("sugar",       "hasProperty", "sweet"),
    "rock_hard":             ("rock",        "hasProperty", "hard"),
    "feather_light":         ("feather",     "hasProperty", "light"),
    "water_wet":             ("water",       "hasProperty", "wet"),
    "water_liquid":          ("water",       "hasProperty", "liquid"),
    "water_fluid":           ("water",       "hasProperty", "fluid"),
    "water_transparent":     ("water",       "hasProperty", "transparent"),   # not always so could be less

                    # hasProperty — abstract concepts (calibration term working)
    "time_duration":         ("time",        "hasProperty", "duration"),
    "time_irreversible":     ("time",        "hasProperty", "irreversible"),
    "time_measurable":       ("time",        "hasProperty", "measurable"),
    "time_infinite":         ("time",        "hasProperty", "infinite"),
    "evolution_variation":   ("biological_evolution",      "hasProperty", "variation"),
    "evolution_inheritance": ("biological_evolution",      "hasProperty", "inheritance"),
    "evolution_mutation":    ("biological_evolution",      "hasProperty", "mutation"),
    "opt_search_space":      ("mathematical_optimization", "hasProperty", "search_space"),
    "opt_iteration":         ("optimization",              "hasProperty", "iteration"),
    "jazz_improvisation":    ("traditional_jazz",          "hasProperty", "improvisation"),
    "progress_over_time":    ("improvement_over_time",     "hasProperty", "progress"),
    "electronic_synthesized":("electronic_music",          "hasProperty", "synthesized"),

                    # hasProperty — specificity gradient on 'smart'
    "human_smart":           ("human",       "hasProperty", "smart"),
    "cat_smart":             ("cat",         "hasProperty", "smart"),
    "people_like_einstein_smart":        ("people_like_Albert_Einstein",    "hasProperty", "smart"),
    "toddler_smart":         ("toddler",     "hasProperty", "smart"),
    "rock_smart":            ("rock",        "hasProperty", "smart"),    # false

                    # hasProperty — clear false (semantically distant)
    "time_blue":             ("time",        "hasProperty", "blue"),
    "jazz_photosynthesis":   ("traditional_jazz",          "hasProperty", "photosynthesis"),

                    # hasProperty — known soft failures kept as regression markers
    "bio_evo_telepathy":     ("biological_evolution",      "hasProperty", "telepathy"),  # ambiguous does bio_evo lead to telepathy? 
    "jazz_silence":          ("traditional_jazz",          "hasProperty", "silence"),    

                    # isA — taxonomic (model must be very strong here)
    "dog_canine":            ("dog",         "isA", "canine"),
    "eagle_bird":            ("eagle",       "isA", "bird"),
    "cat_animal":            ("cat",         "isA", "animal"),
    "cat_mammal":            ("cat",         "isA", "mammal"),
    "cat_creature":          ("cat",         "isA", "creature"),
    "cat_organism":          ("cat",         "isA", "organism"),
    "human_mammal":          ("human",       "isA", "mammal"),
    "human_primate":         ("human",       "isA", "primate"),
    "human_organism":        ("human",       "isA", "organism"),
    "water_liquid_isa":      ("water",       "isA", "liquid"),
    "gold_metal":            ("gold",        "isA", "metal"),
    "oak_tree":              ("oak",         "isA", "tree"),
    "rose_plant":            ("rose",        "isA", "plant"),

                    # isA — false (regression: water isA gas stays high, documented failure)
    "cat_vehicle":           ("cat",         "isA", "vehicle"),
    "cat_mineral":           ("cat",         "isA", "mineral"),
    "water_gasous":         ("water",       "isA", "gasous"),      # ? 

                    # usedFor — correct tool-use (model strong on concrete pairs)
    "knife_cutting":         ("knife",       "usedFor", "cutting"),
    "pen_writing":           ("pen",         "usedFor", "writing"),
    "computer_computing":    ("computer",    "usedFor", "computing"),
    "computer_communication":("computer",    "usedFor", "communication"),
    "computer_calculation":  ("computer",    "usedFor", "calculation"),
    "spoon_eating":          ("spoon",       "usedFor", "eating"),
    "glasses_seeing":        ("glasses",     "usedFor", "seeing"),
    "telescope_observing":   ("telescope",   "usedFor", "observing"),
    "umbrella_rain":         ("umbrella",    "usedFor", "protection from rain"),

                    # usedFor — false regression markers 
    "feet_eat":            ("feet",      "usedFor", "eat"),        # must be low.
    "water_burning":         ("water",       "usedFor", "burning"),    # ambigues, to burn or to counter burning

                    # causesDesire — true pairs (model very strong here)
    "hunger_eat":            ("hunger",      "causesDesire", "eat"),
    "thirst_drink":          ("thirst",      "causesDesire", "drink"),
    "fatigue_sleep":         ("fatigue",     "causesDesire", "sleep"),
    "boredom_entertainment": ("boredom",     "causesDesire", "entertainment"),
    "pain_relief":           ("pain",        "causesDesire", "relief"),
    "loneliness_company":    ("loneliness",  "causesDesire", "company"),
    "cold_warmth":           ("cold",        "causesDesire", "warmth"),
    "curiosity_explore":     ("curiosity",   "causesDesire", "explore"),

                    # causesDesire — cross-wired (ambiguous, kept for tracking)
    "hunger_sleep":          ("hunger",      "causesDesire", "sleep"),  # must be lower than eat 
    "fatigue_run":           ("fatigue",     "causesDesire", "run"),    # known failure 0.955

                    # relatedTo — best possible pairs for this model close semantic neighbours that scored well: cat_dog, cat_economy
    "cat_dog":               ("cat",         "relatedTo", "dog"),
    "knife_sword":           ("knife",        "relatedTo", "sword"),
    "rain_cloud":            ("rain",         "relatedTo", "cloud"),
    "sun_light":             ("sun",          "relatedTo", "light"),
    "school_education":      ("school",       "relatedTo", "education"),
    "hospital_medicine":     ("hospital",     "relatedTo", "medicine"),
    "piano_music":           ("piano",        "relatedTo", "music"),
    "book_reading":          ("book",         "relatedTo", "reading"),
    "war_violence":          ("war",          "relatedTo", "violence"),
    "fire_heat":             ("fire",         "relatedTo", "heat"),
    "inflation_economy":         ("inflation",        "relatedTo", "economy"), 
    "river_rain_water":           ("river",        "relatedTo", "rain_water"),   


                    # relatedTo — distant pairs (model must scores low here)
    "cat_economy":           ("cat",          "relatedTo", "economy"),
    "time_stone":            ("time",         "relatedTo", "stone"),
    "piano_surgery":         ("piano",        "relatedTo", "surgery"),
    "book_volcano":          ("book",         "relatedTo", "volcano"),

                    # relatedTo — documented soft failures kept as regression markers
    "money_economy":         ("money",        "relatedTo", "economy"), # known failure 0.62

                    # atLocation — where things are found
    "fish_ocean":            ("fish",        "atLocation", "ocean"),
    "book_library":          ("book",        "atLocation", "library"),
    "doctor_hospital":       ("doctor",      "atLocation", "hospital"),
    "student_school":        ("student",     "atLocation", "school"),
    "pilot_airplane":        ("pilot",       "atLocation", "airplane"),
                    # false
    "fish_desert":           ("fish",        "atLocation", "desert"),
    "elephant_ocean":          ("elephant",      "atLocation", "ocean"),

                    # hasA — possession / part-whole
    "dog_tail":              ("dog",         "hasA", "tail"),
    "car_engine":            ("car",         "hasA", "engine"),
    "tree_root":             ("tree",        "hasA", "root"),
    "human_heart":           ("human",       "hasA", "heart"),
    "book_page":             ("book",        "hasA", "page"),
                    # false
    "fish_leg":             ("fish",        "hasA", "leg"),
    "rock_heartbeat":        ("rock",        "hasA", "heartbeat"),

                    # madeOf — material composition
    "bread_flour":           ("bread",       "madeOf", "flour"),
    "table_wood":            ("table",       "madeOf", "wood"),
    "ring_gold":             ("ring",        "madeOf", "gold"),
    "window_glass":          ("window",      "madeOf", "glass"),
                    # false
    "bread_metal":           ("bread",       "madeOf", "metal"),
    "window_water":          ("window",      "madeOf", "water"),

                    # partOf — component membership
    "finger_hand":           ("finger",      "partOf", "hand"),
    "wheel_car":             ("wheel",       "partOf", "car"),
    "petal_flower":          ("petal",       "partOf", "flower"),
    "chapter_book":          ("chapter",     "partOf", "book"),
                    # false
    "finger_ocean":          ("finger",      "partOf", "ocean"),
    "wheel_cloud":           ("wheel",       "partOf", "cloud"),

                    # causes — event causation
    "rain_flood":            ("rain",        "causes", "flood"),
    "fire_smoke":            ("fire",        "causes", "smoke"),
    "exercise_fatigue":      ("exercise",    "causes", "fatigue"),
    "virus_illness":         ("virus",       "causes", "illness"),
                    # false
    "rain_sunshine":         ("rain",        "causes", "sunshine"), 
    "sleep_illness":         ("sleep",       "causes", "illness"),

                    # hasSubevent — activity decomposition
    "eating_chewing":        ("eating",      "hasSubevent", "chewing"),
    "sleeping_dreaming":     ("sleeping",    "hasSubevent", "dreaming"),
    "cooking_chopping":      ("cooking",     "hasSubevent", "chopping"),
    "reading_turning_pages": ("reading",     "hasSubevent", "turning pages"),
                    # false
    "eating_flying":         ("eating",      "hasSubevent", "flying"),
    "sleeping_swimming":     ("sleeping",    "hasSubevent", "swimming"),

                    # hasPrerequisite — preconditions
    "reading_literacy":      ("reading",     "hasPrerequisite", "literacy"),
    "driving_license":       ("driving",     "hasPrerequisite", "license"),
    "cooking_ingredients":   ("cooking",     "hasPrerequisite", "ingredients"),
    "swimming_water":        ("swimming",    "hasPrerequisite", "water"),
                    # false
    "reading_swimming":      ("reading",     "hasPrerequisite", "swimming"),
    "driving_cooking":       ("driving",     "hasPrerequisite", "cooking"),

                    # receivesAction — what gets done to something
    "bread_eaten":           ("bread",       "receivesAction", "eaten"),
    "car_driven":            ("car",         "receivesAction", "driven"),
    "book_read":             ("book",        "receivesAction", "read"),
    "tree_cut":              ("tree",        "receivesAction", "cut"),
                    # false
    "bread_flown":           ("bread",       "receivesAction", "flown"),
    "tree_elected":          ("tree",        "receivesAction", "elected"),

                    # antonym — opposites
    "hot_cold":              ("hot",         "antonym", "cold"),
    "light_dark":            ("light",       "antonym", "dark"),
    "fast_slow":             ("fast",        "antonym", "slow"),
    "rich_poor":             ("rich",        "antonym", "poor"),
                    # false — same-polarity pairs, not opposites
    "hot_warm":              ("hot",         "antonym", "warm"),
    "fast_quick":            ("fast",        "antonym", "quick"),

                    # synonym — same meaning
    "fast_quick":            ("fast",        "synonym", "quick"),
    "happy_joyful":          ("happy",       "synonym", "joyful"),
    "begin_start":           ("begin",       "synonym", "start"),
    "large_big":             ("large",       "synonym", "big"),
                    # false — opposites or unrelated
    "fast_slow_syn":         ("fast",        "synonym", "slow"),
    "happy_sad_syn":         ("happy",       "synonym", "sad"),

                    # desires — agent wants something
    "human_happiness":       ("human",       "desires", "happiness"),
    "child_toy":             ("child",       "desires", "toy"),
    "athlete_victory":       ("athlete",     "desires", "victory"),
    "plant_sunlight":        ("plant",       "desires", "sunlight"),
                    # false
    "rock_happiness":        ("rock",        "desires", "happiness"),
    "fire_education":        ("fire",        "desires", "education"),

                    # instanceOf — specific example of a category
    "paris_city":            ("Paris",       "instanceOf", "city"),
    "python_language":       ("Python",      "instanceOf", "programming language"),
    "beethoven_composer":    ("Beethoven",   "instanceOf", "composer"),
    "nile_river":            ("Nile",        "instanceOf", "river"),
                    # false
    "paris_ocean":           ("Paris",       "instanceOf", "ocean"),
    "nile_mountain":         ("Nile",        "instanceOf", "mountain"),

                    # locatedNear — spatial proximity
    "lamp_table":            ("lamp",        "locatedNear", "table"),   # could be low
    "stove_kitchen":         ("stove",       "locatedNear", "kitchen"),
    "pillow_bed":            ("pillow",      "locatedNear", "bed"),
    "shore_ocean":           ("shore",       "locatedNear", "ocean"),
                    # false
    "lamp_ocean":            ("lamp",        "locatedNear", "ocean"),
    "pillow_volcano":        ("pillow",      "locatedNear", "volcano"),

                    # formOf — morphological variant
    "running_run":           ("running",     "formOf", "run"),
    "better_good":           ("better",      "formOf", "good"),
    "mice_mouse":            ("mice",        "formOf", "mouse"),
    "went_go":               ("went",        "formOf", "go"),
                    # false — unrelated words
    "running_table":         ("running",     "formOf", "table"),
    "better_ocean":          ("better",      "formOf", "ocean"),

                    # createdBy — authorship / origin
    "symphony_composer":     ("symphony",    "createdBy", "composer"),
    "painting_artist":       ("painting",    "createdBy", "artist"),
    "bread_baker":           ("bread",       "createdBy", "baker"),
    "law_government":        ("law",         "createdBy", "government"),
                    # false
    "symphony_fish":         ("symphony",    "createdBy", "fish"),
    "bread_ocean":           ("bread",       "createdBy", "ocean"),

                    # distinctFrom — explicitly not the same thing
    "cat_dog_distinct":      ("cat",         "distinctFrom", "dog"),
    "water_fire_distinct":   ("water",       "distinctFrom", "fire"),
    "day_night":             ("day",         "distinctFrom", "night"),
    "truth_lie":             ("truth",       "distinctFrom", "lie"),
                    # false — same or very similar things
    "cat_feline":            ("cat",         "distinctFrom", "feline"),
    "water_liquid_dist":     ("water",       "distinctFrom", "liquid"),
}

if __name__ == "__main__":
    engine = ScoreEngine()
    for key, (src, rel, tgt) in TRIPLETS.items():
        score = engine.query(src, rel, tgt)
        print(f"{key} {score}")