!(import! &self libs)

!(load-ascii &self atom/a.metta)


; Helper to reorder triplet
(= (reorder-triplet $triplet)
   (let ($rel $sub $obj) $triplet
        ($sub $rel $obj)
    )
        
)


(=(fetch-atom-RelatedTo $concept) 
     (match &self (, (RelatedTo $concept $target) (surfaceText (RelatedTo $concept $target) $text))
     (if (== N/A $text) (reorder-triplet (RelatedTo $concept $target)) 
     ($text))) 
)


(=(fetch-atom-HasProperty $concept) 
     (match &self (, (HasProperty $concept $target) (surfaceText (HasProperty $concept $target) $text)) 
     
     (if (== N/A $text) (reorder-triplet (HasProperty $concept $target)) 
     ($text) $concept))
)

(=(fetch-atom-IsA $concept) 
     (match &self (, (IsA $concept $target) (surfaceText (IsA $concept $target) $text)) 
     
     (if (== N/A $text) (reorder-triplet (IsA $concept $target)) ($text) $concept))
)




(=(main-fetch $concept)
     ((fetch-atom-RelatedTo $concept) (fetch-atom-HasProperty $concept) (fetch-atom-IsA $concept))

)


(=(algspec_builder $concept1 $concept2)
     (gpt_algspec_builder ((main-fetch $concept1)) ((main-fetch $concept2)))

)



!(algspec_builder House Boat)