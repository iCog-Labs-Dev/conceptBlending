!(import! &self libs)

!(load-ascii &self atom/a.metta)



; Helper to reorder triplet
(= (reorder-triplet $triplet)
   (let ($rel $sub $obj) $triplet
        ($sub $rel $obj)
    )     
)

; Fetch RelatedTo atoms for a concept
(=(fetch-atom-RelatedTo $concept) 
     (match &self (, (RelatedTo $concept $target) (surfaceText (RelatedTo $concept $target) $text))
     (if (== N/A $text) (reorder-triplet (RelatedTo $concept $target)) 
     ($target $text))) 
)


; Fetch HasProperty atoms for a concept
(=(fetch-atom-HasProperty $concept) 
     (match &self (, (HasProperty $concept $target) (surfaceText (HasProperty $concept $target) $text)) 
     
     (if (== N/A $text) (reorder-triplet (HasProperty $concept $target)) 
     ($target $text))
)
)


; Fetch IsA atoms for a concept
(=(fetch-atom-IsA $concept) 
     (match &self (, (IsA $concept $target) (surfaceText (IsA $concept $target) $text)) 
     
     (if (== N/A $text) (reorder-triplet (IsA $concept $target)) ($target $text)))
)


; Main fetch function to get all relevant atoms for a concept
(=(main-fetch $concept)
     ((fetch-atom-RelatedTo $concept) (fetch-atom-HasProperty $concept) (fetch-atom-IsA $concept))

)

; GPT-based Algspec Builder
(=(algspec_builder $concept1 $concept2)
     (let ($context1 $context2) ((main-fetch $concept1) (main-fetch $concept2))

     (gpt_algspec_builder ($concept1 ($context1)) ($concept2 ($context2))))
    

     
)




!(algspec_builder House Boat)

