!(import! &self libs)

; Helper to reorder triplet
(= (reorder-triplet $triplet)
   (let ($rel $concept $target) $triplet
      ($concept $rel $target)
   )
)

; Fetch IsA atoms for a concept
(=(fetch-atom-IsA $concept)
  (let $pairs (match &self (surfaceText (IsA $concept $target) $text)
               (if (== NA $text)
                   (reorder-triplet (IsA $concept $target))
                   ($target $text)
               )
             )
   (if (== $pairs ()) $concept $pairs)
  )
)

; Fetch RelatedTo atoms for a concept
(=(fetch-atom-RelatedTo $concept)
  (let $pairs 
                (match &self (surfaceText (RelatedTo $concept $target) $text)
                       (if (== NA $text)
                           (reorder-triplet (RelatedTo $concept $target))
                           ($target $concept)))
    (if (== $pairs ()) $concept $pairs)))

; Fetch HasProperty atoms for a concept
(=(fetch-atom-HasProperty $concept)
  (let $pairs 
                (match &self (surfaceText (HasProperty $concept $target) $text)
              
                       (if (== NA $text)
                           (reorder-triplet (HasProperty $concept $target))
                           ($target $text)))
    (if (== $pairs ()) $concept $pairs)))


; Main fetch function to get all relevant atoms for a concept
(=(main-fetch $concept)
     (collapse (unique((superpose ((fetch-atom-RelatedTo $concept) (fetch-atom-HasProperty $concept) (fetch-atom-IsA $concept))
     ))))
     
)

; GPT-based Algspec Builder

(=(algspec_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))
        (let ($generated_context) (collapse (context_preprocessing ($concept1 $context1) ($concept2 $context2)))
           (gpt_algspec_builder ($concept1 $generated_context) ($concept2 $generated_context)))
)
)



