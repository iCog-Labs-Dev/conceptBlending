# Commonsense Truth-Value Scorer

Relational-GAT triple scorer, packaged to run standalone, with no Kaggle or
notebook dependency at inference time.

Scores a `(source, relation, target)` triple, for example
`(person, capableOf, think)`, on a continuous `[0, 1]` plausibility scale,
using a trained RGATConv encoder and a calibrated TransE-style decoder. The
output is designed to supply calibrated truth values to a `TruthValueQuantale`
component in a broader quantale and V-predicate reasoning framework, and to
support a concept-blending use case where candidate blended concepts need a
graded plausibility score rather than a binary judgment.

Training notebook:
https://www.kaggle.com/code/daveasmero/notebook5dc90117d8

Dataset:
https://www.kaggle.com/datasets/daveasmero/conceptnet-lite

For the full history of design decisions summarized below, including the
dataset labeling revisions and the reasons earlier architecture variants were
tried and dropped, see the accompanying project documentation PDF.

## Contents

| File | Purpose |
|---|---|
| `engine.py` | `ScoreEngine`, loads the model and embedder once per process, exposes `.query(source, relation, target) -> float` |
| `model_config.py` | Reads architecture dimensions from the checkpoint's saved config block |
| `model_extraction.py` | Rebuilds `GatEncoder` and `CalibratedTranslationalDecoder`, loads weights with strict key matching |
| `sentence_embedder.py` | Wraps `SentenceTransformer` for `all-mpnet-base-v2`; maps relation strings to trained ids |
| `score_utils.py` | Batch helpers: `score_all`, `score_ranked`, `print_scores` |
| `sample_usage.py` | Reference triple set and a minimal command-line smoke test |

### Required assets, place alongside the files above

```
model_weights.pt        trained checkpoint (encoder + decoder only, no embedding buffer)
rel2idx.json             relation string to id vocabulary
all-mpnet-base-v2/       local copy of the sentence-transformer model, or a Hub id
```

## Setup

```bash
pip install torch torch_geometric sentence-transformers
```

## Run the sample dataset to test

```bash
python -m extractor_v1.sample_usage
```

## Single triple

```python
from extractor_v1.engine import ScoreEngine

engine = ScoreEngine()
score = engine.query("fire", "hasProperty", "hot")
print(score)
```

## Batch scoring

```python
from extractor.light_weight_extractor.engine import ScoreEngine
from extractor.light_weight_extractor.score_utils import score_all, score_ranked, print_scores
from extractor.light_weight_extractor.sample_usage import TRIPLETS

engine = ScoreEngine()

results = score_all(engine, TRIPLETS)      # dict: name -> score
ranked = score_ranked(engine, TRIPLETS)    # sorted list of (name, score)
print_scores(engine, TRIPLETS)             # aligned printed table
```

## Custom paths

```python
engine = ScoreEngine(
    weights_path="/path/to/model_weights.pt", 
    rel_map_path="/path/to/rel2idx.json",
    mpnet_path="/path/to/all-mpnet-base-v2", # you can use the defualt sentence transformer or download the embedding manually.
)
```

## Architecture, briefly

The encoder is two stacked RGATConv layers over a minimal two-node
neighborhood, source and target connected by the edge being scored plus
self-loops, the same neighborhood scope used during training. The decoder
combines a TransE-style translational distance term with a per-relation
additive cosine-similarity calibration term in logit space, both initialized
so the model starts equivalent to a pure translational scorer and learns per
relation how much of the calibration term, if any, to use.

An earlier architecture variant used a fuller cosine-blend decoder with a
trainable embedding adapter and a per-relation logit-stretch calibration
head. It measured a stronger fix for relations that need graded semantic
judgment, at the cost of a standalone deployment package having to exactly
reproduce the training-time module structure to load the checkpoint at all.
The current decoder is the simplified successor kept for deployment: fewer
moving parts, no extra module classes for a loader to get wrong, at a small
cost in ranking headroom for the hardest relations.

## Relation vocabulary

The 28 trained relations, ids 0 to 27, match `rel2idx.json`. An unrecognized
relation string resolves to id 28, the reserved unknown slot, rather than
raising an error.

```
causesDesire   createdBy      definedAs      desires        distinctFrom
entails        etymologicallyDerivedFrom     hasPrerequisite
instanceOf     madeOf         locatedNear    antonym        atLocation
capableOf      causes         derivedFrom    etymologicallyRelatedTo
formOf         hasA           hasContext     hasProperty    hasSubevent
isA            partOf         receivesAction relatedTo
synonym        usedFor
```

## Known limitations

- The scorer only ever sees the two endpoints of the triple being scored, which bypass the need to have an atomspace or any graph to infer from.
- The weight and bais factor cosine similarity with respect to each relation should be checked and verifed(done). In the updated model normalization is applied to cosine similarity parameteres.   

- The nature of the dataset from ConceptnetLite or in general any concpet property relation scoreres online have a raw weight partly encodes which extraction pipeline produced an assertion, rather than only its truthfulness, has not been directly verified despite our model try to handle them with hard negative datasets.

## recommendations
- Increasing the size of the encoder will enhance the model performance But it will require more compuational power than we currently have. It could be done either increasing the hidden dimension from 128 to larger number upto 700 (must be divisble by the head) or by increasing the dimension of the head or both. 



- 
