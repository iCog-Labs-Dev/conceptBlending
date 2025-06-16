!(register-module! ../libs)
! (import! &self libs)


(= (check-against-predefined-list $item $item2 $terms_antonymity $list)
    (if (== (size-atom $list) 0 )
        0
        (if (or 
        (== ($item $item2) (car-atom $list)) 
        (or 
            (== ($item2 $item) (car-atom $list)) 
            $terms_antonymity
        )
            )    1 ; Item found
            (check-against-predefined-list $item $item2 $terms_antonymity (cdr-atom $list)) ; Recurse on the rest of the list
        )
    )
)

(= (count-trues-from-head-with-tail $head $tail_list $predefined-conflicts)
  (if (< (size-atom $tail_list) 1)
        0 
        (let* (
                ($current_tail_element (car-atom $tail_list))
                ($remaining_tail (cdr-atom $tail_list))
                ($current_add (check-against-predefined-list $head $current_tail_element (are_terms_antonyms $head $current_tail_element) $predefined-conflicts))
                ($rest_add (count-trues-from-head-with-tail $head $remaining_tail $predefined-conflicts))
            )
            (+ $current_add $rest_add)
        )
    )
)
(= (conflict-check-loop $items $predefined-conflicts)
  (if (< (size-atom $items) 2)
      0
      (let* (
          ($head (car-atom $items))
          ($tail (cdr-atom $items))
          ($head_related_trues (count-trues-from-head-with-tail $head $tail $predefined-conflicts))
          ($tail_related_trues (conflict-check-loop $tail $predefined-conflicts))
        )
        (+ $head_related_trues $tail_related_trues)
      )
  )
)

(= (properties-list (Blend $blend_name $properties $relations)) (
    let $prop_list $properties (cdr-atom $prop_list)
    )
)

(= (integration_op $blend )
    (let*(
        ($prop-list (properties-list $blend))
        ($prop_names (map-atom $prop-list $x (car-atom $x)))
        ($conflicts (conflict-check-loop $prop_names (predefined-conflicts)))
        ($conflict_ratio (/ $conflicts (pow-math (size-atom $prop_names) 0.5)))
    )
        (
            max-atom (0.0 (- 1.0 $conflict_ratio))
        )
    )
)


(= (predefined-conflicts)
    ((hot cold) (liquid solid) (alive dead) (floats metald) (floats sinks) (on off) (open close) (true false) (win lose))
)

(= (amphibious_vehicle)
    (Blend amphibious_vehicle 
    (Properties  (metal (car)) (floats (boat)) (waterproof))
    (Relations (UsedFor (transportation 1.0) (Short_HasPart (engine 0.8))))
    )
)

! (integration_op (amphibious_vehicle))