!(import! &self ../../../metta/pln/dependent-types/fullpathlcgprompt)
!(import! &self ../../../metta/pln/dependent-types/partialpathlcgprompt)
!(import! &self ../../../metta/pln/dependent-types/algebraicspecprompt)

;Create string by appending the list entries
(= (py-str-helper () $outp) $outp)
(= (py-str-helper $L $outp)
   (let* (($head (car-atom $L))
          ($tail (cdr-atom $L))
          ($outp2 (py-call (operator.add $outp (py-call (str $head))))))
     (py-str-helper $tail $outp2)))
(= (py-str $L) (py-str-helper $L ""))

;Evaluate expression via py-call:
(= (py-eval $str)
   (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

;Add to builtins a function that can call functions via keyword arguments
!(py-eval "setattr(__import__('builtins'),'apply_kwargs',(lambda f,d: f(**d))) or 0")
;Add to builtins a function that can access by index:
!(py-eval "setattr(__import__('builtins'),'index', (lambda o,i: o[i])) or 0")
;Dict helpers:
!(py-eval "setattr(__import__('builtins'),'make_openai_responses_kwargs',(lambda m,t,e,p:{'model':m,'input':p,'max_output_tokens':t,'reasoning':{'effort':e}})) or 0")
!(py-eval "setattr(__import__('builtins'),'make_openai_embedding_kwargs',(lambda x:{'model':'text-embedding-3-large','input':x})) or 0")

!(change-state! &openai_client (py-call (openai.OpenAI)))

; Function to call Google Gemini using the new google-genai SDK
(= (useGenAI $prompt-name $concept1 $concept2)
   (let* (
          ; Import google.genai
          ($prompt (py-str ($prompt-name $concept1 $concept2)))
          ($genai (py-call (importlib.import_module "google.genai")))

          ; Get the Client class
          ($Client (py-call (getattr $genai "Client")))

          ; Prepare configuration with GEMINI_API_KEY
          ($confargs-str (py-str ("{'api_key':__import__('os').getenv('GEMINI_API_KEY')}")))
          ($confargs (py-eval $confargs-str))

          ; Instantiate the client → client = genai.Client(api_key=...)
          ($client (py-call (builtins.apply_kwargs $Client $confargs)))

          ; Prepare model & prompt arguments
          ($kwargs-str (py-str ("{'model': 'gemini-2.5-flash', 'contents':\"" $prompt "\"}")))
          ($kwargs (py-eval $kwargs-str))
          ; Call client.models.generate_text(**kwargs)
          ($models (py-call (getattr $client "models")))
          ($generate (py-call (getattr $models "generate_content")))
          ($resp (py-call (builtins.apply_kwargs $generate $kwargs)))

          ; Extract text
          ($text (py-call (getattr $resp "text"))))
         $text))

(= (useGPT $prompt)
   (useGPT gpt-5.2 1000000 medium $prompt))
(= (useGPT $model $max_tokens $effort $prompt)
   (let* (($client    (get-state &openai_client))
          ($responses (py-call (getattr $client "responses")))
          ($create    (py-call (getattr $responses "create")))
          ($kwargs    (py-call (builtins.make_openai_responses_kwargs $model $max_tokens $effort $prompt)))
          ($res       (py-call (builtins.apply_kwargs $create $kwargs)))
          ($text      (py-call (getattr $res "output_text")))
          ($_ (cut)))
         $text))

; !(useGPT "hey")

; !(useGenAI lcgprompt (sea (sea -> surface-water -> watershed -> hydrologic-system -> planetary-composition)) (land (land -> land-surface -> landform -> terrain -> geosphere)))
