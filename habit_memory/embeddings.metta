; SentenceTransformer-backed semantic similarity.

(= (dot-product () ())
   0.0)
(= (dot-product (cons $value-a $rest-a) (cons $value-b $rest-b))
   (+ (* $value-a $value-b)
      (dot-product $rest-a $rest-b)))

(= (sum-squares ())
   0.0)
(= (sum-squares (cons $value $rest))
   (+ (* $value $value)
      (sum-squares $rest)))

(= (vector-norm $vector)
   (sqrt-math (sum-squares $vector)))

(= (cosine-similarity $vector-a $vector-b)
   (let* (($norm-a (vector-norm $vector-a))
          ($norm-b (vector-norm $vector-b)))
      (if (or (== $norm-a 0.0)
              (== $norm-b 0.0))
          0.0
          (/ (dot-product $vector-a $vector-b)
             (* $norm-a $norm-b)))))

(= (embedding-provider-name)
   (py-call (real_embeddings.provider_name)))

(= (embedding-provider-mode)
   (py-call (real_embeddings.provider_mode)))

(= (embedding-provider-error)
   (py-call (real_embeddings.provider_error)))

(= (embedding-provider-status)
   (py-call (real_embeddings.provider_status)))

(= (print-embedding-provider)
   (println! (Embedding Provider: (embedding-provider-name) Mode: (embedding-provider-mode) Status: (embedding-provider-status))))

(= (real-embedding-similarity $property-a $property-b)
   (py-call (real_embeddings.embedding_similarity $property-a $property-b)))

(= (habit-strength-embedding $property-a $property-b)
   (real-embedding-similarity $property-a $property-b))
