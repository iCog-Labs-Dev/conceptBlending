!(import! &self ../prompts/double_scope_network)

;Empty Python dictionary
(= (emptydict)
   (py-call (dict)))

;Create string by appending the list entries
(= (py-str-helper () $outp) $outp)
(= (py-str-helper $L $outp)
   (let* (($head (car-atom $L))
          ($tail (cdr-atom $L))
          ($outp2 (py-call (operator.add $outp (py-call (str $head))))))
     (py-str-helper $tail $outp2)))
(= (py-str $L) (py-str-helper $L ""))

;Add to builtins a function that can call functions via keyword arguments
!(py-call (eval "setattr(__import__('builtins'),'apply_kwargs',(lambda f,d: f(**d))) or 0" (emptydict)))
;Add to builtins a function that can access by index:
!(py-call (eval "setattr(__import__('builtins'),'index', (lambda o,i: o[i])) or 0" (emptydict)))

; Function to call Google Gemini using the new google-genai SDK
(= (useGenAI $prompt)
   (let* (
          ; Import google.genai
          ($genai (py-call (importlib.import_module "google.genai")))
          ($_ (println! $genai))

          ; Get the Client class
          ($Client (py-call (getattr $genai "Client")))

          ; Prepare configuration with GEMINI_API_KEY
          ($confargs (py-call (eval (py-str ("{'api_key':__import__('os').getenv('GEMINI_API_KEY')}"))
                                    (emptydict)
                                    (emptydict))))

          ; Instantiate the client → client = genai.Client(api_key=...)
          ($client (py-call (builtins.apply_kwargs $Client $confargs)))
          ($_ (println! $client))

          ; Prepare model & prompt arguments
          ($kwargs (py-call (eval (py-str ("{'model': 'gemini-2.5-flash', 'contents':\"" $prompt "\"}"))
                                  (emptydict)
                                  (emptydict))))
         ($_ (println! $kwargs))
          ; Call client.models.generate_text(**kwargs)
          ($models (py-call (getattr $client "models")))
          ($generate (py-call (getattr $models "generate_content")))
          ($_ (println! $generate))
          ($resp (py-call (builtins.apply_kwargs $generate $kwargs)))

          ; Extract text
          ($text (py-call (getattr $resp "text"))))
         $text))

!(useGenAI (py-str (double-scope-prompt bat@man (1 1 1 1 1 1 1 1))))

; !(fo)