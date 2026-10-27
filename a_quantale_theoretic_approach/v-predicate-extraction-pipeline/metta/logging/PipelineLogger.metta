;; Shared MeTTa facade for the structured Python pipeline event logger.

(= (pipeline-logger-py-eval $str)
    (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

!(pipeline-logger-py-eval "(lambda os,sys,importlib,builtins:(lambda root:(sys.path.insert(0,os.path.join(root,'python','storage')),setattr(builtins,'log_pipeline_event',importlib.import_module('pipeline_event_logger').log_pipeline_event),setattr(builtins,'start_pipeline',importlib.import_module('pipeline_event_logger').start_pipeline),setattr(builtins,'finish_pipeline',importlib.import_module('pipeline_event_logger').finish_pipeline),0)[-1])(os.getenv('V_PREDICATE_PIPELINE_ROOT',os.getcwd() if os.path.isdir(os.path.join(os.getcwd(),'python','storage')) else os.path.join(os.getcwd(),'v-predicate-extraction-pipeline') if os.path.isdir(os.path.join(os.getcwd(),'v-predicate-extraction-pipeline','python')) else os.path.join(os.getcwd(),'metta','pln','dependent-types','v-predicate-extraction-pipeline'))))(__import__('os'),__import__('sys'),__import__('importlib'),__import__('builtins'))")

(= (pipeline-start $subject $perspective)
    (py-call (builtins.start_pipeline $subject $perspective)))

;; Serialize details before crossing the Python boundary so lists headed by
;; registered MeTTa callables (for example, library) remain inert data.
(= (pipeline-success $stage $subject $perspective $details)
    (let $detailsText (repr $details)
        (py-call
            (builtins.log_pipeline_event
                success $stage $subject $perspective $detailsText))))

(= (pipeline-error $stage $subject $perspective $details)
    (let $detailsText (repr $details)
        (py-call
            (builtins.log_pipeline_event
                error $stage $subject $perspective $detailsText))))

(= (pipeline-finish $status $subject $perspective $details)
    (let $detailsText (repr $details)
        (py-call
            (builtins.finish_pipeline
                $status $subject $perspective $detailsText))))
