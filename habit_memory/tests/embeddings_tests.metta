(= (hide $value) (empty))

!(let $import-real-embeddings (import! &self "../real_embeddings.py") (empty))
!(let $import-embeddings (import! &self ../embeddings) (empty))

!(test (embedding-provider-mode)
       sentence-transformers)

!(test (embedding-provider-name)
       sentence-transformers:all-MiniLM-L6-v2)

!(test (dot-product (1.0 2.0 3.0) (4.0 5.0 6.0))
       32.0)

!(test (vector-norm (3.0 4.0))
       5.0)

!(test (cosine-similarity (1.0 0.0) (0.0 1.0))
       0.0)

!(test (cosine-similarity (1.0 1.0) (1.0 1.0))
       0.9999999999999998)

!(test (> (habit-strength-embedding access_internet calculate_data) 0.0)
       True)

!(test (> (habit-strength-embedding access_internet carrying_groceries) 0.0)
       True)

!(test (> (habit-strength-embedding access_internet unknown_property) 0.0)
       True)
