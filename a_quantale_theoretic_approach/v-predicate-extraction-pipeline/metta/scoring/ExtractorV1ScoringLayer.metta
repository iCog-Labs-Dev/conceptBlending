(= (extractor-v1-py-eval $str)
    (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

!(extractor-v1-py-eval "(lambda os,sys,importlib: (sys.path.insert(0, os.path.join(os.getenv('V_PREDICATE_PIPELINE_ROOT','.'),'python','scoring')), importlib.import_module('extractor_v1_client').register_builtins())[-1])(__import__('os'),__import__('sys'),__import__('importlib'))")

(= (score-concept-triple $source $relation $target)
    (py-call (builtins.score_concept_triple $source $relation $target)))
