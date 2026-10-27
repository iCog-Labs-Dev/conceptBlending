;; MeTTa facade for the component-local structured event logger.

(= (generalization-start $subject $perspective)
    (py-call
        (generalization_event_logger.start_generalization
            $subject $perspective)))

(= (generalization-success $stage $subject $perspective $details)
    (py-call
        (generalization_event_logger.log_generalization_event
            success $stage $subject $perspective $details)))

(= (generalization-error $stage $subject $perspective $details)
    (py-call
        (generalization_event_logger.log_generalization_event
            error $stage $subject $perspective $details)))

(= (generalization-finish $status $subject $perspective $details)
    (py-call
        (generalization_event_logger.finish_generalization
            $status $subject $perspective $details)))
