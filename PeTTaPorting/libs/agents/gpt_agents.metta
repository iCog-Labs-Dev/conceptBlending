!(import! &self libs/prompts/double_scope_network)
!(import! &self libs/prompts/mirror_network)
!(import! &self libs/prompts/simplex_network)
!(import! &self libs/prompts/network_selector)
!(import! &self libs/prompts/single_scope_network)
!(import! &self libs/prompts/vector_extraction)
!(import! &self libs/prompts/vital_relation_extraction)
!(import! &self "libs/agents/api_key_loader.py")

!(py-call (api_key_loader.get_openai_config))
;; --- vital-relation ---
(= (gpt-vital-relation $concept-pair $property-vector)
   (let $prompt (vital-relation-prompt $concept-pair $property-vector)
       (useGPT (py-str $prompt))))

;; --- network-selector ---
(= (gpt-network-selector $concept)
   (let $prompt (network-selector-prompt $concept)
       (useGPT (py-str $prompt))))

;; --- vector-extraction ---
(= (gpt-vector-extraction $concept1 $concept2 $vital-relations)
   (let $prompt (vector-extraction-prompt $concept1 $concept2 $vital-relations)
       (useGPT (py-str $prompt))))

;; --- mirror ---
(= (gpt-mirror $concept-pair $property-vector)
   (let $prompt (mirror-prompt $concept-pair $property-vector)
       (useGPT (py-str $prompt))))

;; --- simplex ---
(= (gpt-simplex $concept-pair $property-vector)
   (let $prompt (simplex-prompt $concept-pair $property-vector)
       (useGPT (py-str $prompt))))

;; --- double-scope ---
(= (gpt-double-scope $concept-pair $property-vector)
   (let $prompt (double-scope-prompt $concept-pair $property-vector)
       (useGPT (py-str $prompt))))

;; --- single-scope ---
(= (gpt-single-scope $concept-pair $property-vector)
   (let $prompt (single-scope-prompt $concept-pair $property-vector)
       (useGPT (py-str $prompt))))
