!(import! &self libs)





; Helper to reorder triplet
(= (reorder-triplet $triplet)
   (match $triplet
      ((IsA $sub $obj) ($sub IsA $obj))
      ((RelatedTo $sub $obj) ($sub RelatedTo $obj))
      ((HasProperty $sub $obj) ($sub HasProperty $obj))
      ($triplet))
)

; Fetch IsA atoms for a concept
(=(fetch-atom-IsA $concept)
  (let $pairs (collapse
                (match &self 
                       (, (IsA $concept $target) 
                          (surfaceText (IsA $concept $target) $text))
                       (if (== NA $text)
                           (reorder-triplet (IsA $concept $target))
                           ($target $text))))
    (if (== $pairs ()) $concept $pairs)))

; Fetch RelatedTo atoms for a concept
(=(fetch-atom-RelatedTo $concept)
  (let $pairs (collapse
                (match &self 
                       (, (RelatedTo $concept $target) 
                          (surfaceText (RelatedTo $concept $target) $text))
                       (if (== NA $text)
                           (reorder-triplet (RelatedTo $concept $target))
                           ($target $text))))
    (if (== $pairs ()) $concept $pairs)))

; Fetch HasProperty atoms for a concept
(=(fetch-atom-HasProperty $concept)
  (let $pairs (collapse
                (match &self 
                       (, (HasProperty $concept $target) 
                          (surfaceText (HasProperty $concept $target) $text))
                       (if (== NA $text)
                           (reorder-triplet (HasProperty $concept $target))
                           ($target $text))))
    (if (== $pairs ()) $concept $pairs)))





; Main fetch function to get all relevant atoms for a concept
(=(main-fetch $concept)
     ((fetch-atom-RelatedTo $concept) (fetch-atom-HasProperty $concept) (fetch-atom-IsA $concept))

)

; GPT-based Algspec Builder

(=(algspec_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($x $y) (collapse (context_preprocessing ($concept1 $context1) ($concept2 $context2)))
           (gpt_algspec_builder $x $y)))
)





!(algspec_builder yacht ark)

