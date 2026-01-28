;Empty Python dictionary
(= (emptydict)
   (py-call (dict)))


(= (py-str-helper () $outp) $outp)

(= (py-str-helper $L $outp)
   (let* (($head (car-atom $L))
          ($tail (cdr-atom $L))
          ($outp2
            (if (== $outp "")
                ;; first token → no leading space
                (py-call (operator.add $outp (py-call (str $head))))
                ;; subsequent tokens → prepend space
                (py-call (operator.add
                          (py-call (operator.add $outp " "))
                          (py-call (str $head)))))))
     (py-str-helper $tail $outp2)))

(= (py-str $L)
   (py-str-helper $L ""))

;Evaluate expression via py-call:
(= (py-eval $str)
   (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

;Add to builtins a function that can call functions via keyword arguments
!(py-eval "setattr(__import__('builtins'),'apply_kwargs',(lambda f,d: f(**d))) or 0")
;Add to builtins a function that can access by index:
!(py-eval "setattr(__import__('builtins'),'index', (lambda o,i: o[i])) or 0")


; Function to call Google Gemini using the new google-genai SDK
(= (useGenAI $prompt)
   (let* (
          ; Import google.genai
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

; !(useGenAI (py-str (double-scope-prompt bat@man (1 1 1 1 1 1 1 1))))

(= (useGPT $prompt)
   (let* (($client    (py-call (openai.OpenAI)))
          ($responses (py-call (getattr $client "responses")))
          ($create (py-call (getattr $responses "create")))
          ($mydict (py-str  ("{'model':'gpt-4o','input':\"" $prompt "\", 'temperature':0}")))
          ($kwargs (once (py-eval $mydict)))
          ($res (py-call (builtins.apply_kwargs $create $kwargs)))
          ($output (py-call (getattr $res "output")))
          ($outmsg (py-call (builtins.index $output 0))) ;0 is ResponseReasoningItem
          ($content (py-call (getattr $outmsg "content")))
          ($part (py-call (builtins.index $content 0)))
          ($text (py-call (getattr $part "text")))
          )
         $text))