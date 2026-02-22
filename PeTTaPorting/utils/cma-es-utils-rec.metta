
!(import! &self list-op-utils)
;! (import! &self utils/cma-utils)
; ;Evaluate expression via py-call:
;!(import! &self "utils/numpy_methods.py")

;; ============================================================================
;; PYTHON INTEROPERABILITY & NUMPY BRIDGE
;; ============================================================================

;; Evaluates a Python string in a clean dictionary context
(= (py-eval $str)
   (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

;; Inject helper functions into Python's builtins to handle *args and **kwargs
;; !(py-eval "setattr(__import__('builtins'),'apply_kwargs',(lambda f,d: f(**d))) or 0")
;; !(py-eval "setattr(__import__('builtins'),'apply_args',(lambda f,args: f(*args))) or 0")

;; Wrapper for Numpy's max function
(= (np-max $ref-point $objs-val $axis)
   (py-call (numpy_methods.np_max $ref-point $objs-val $axis)))

;; Generates samples from a Normal distribution using Numpy
(= (numpy-random-normal $rng) 
   (let* (($numpy (py-call (importlib.import_module "numpy")))
          ($np-random (py-call (getattr $numpy "random")))
          ($rand (py-call (getattr $np-random "normal")))
          ($result (py-call (builtins.apply_args $rand $rng))))
     $result))

;; Generates samples from a Dirichlet distribution
(= (np-dirichlet $alpha $size)
   (let* (($numpy (py-call (importlib.import_module "numpy")))
          ($np-random (py-call (getattr $numpy "random")))
          ($dirichlet (py-call (getattr $np-random "dirichlet"))))
     (py-call (builtins.apply_args $dirichlet ($alpha $size)))))

;; Gaussian noise generator: Normal distribution with mean 0
(= (gauss $std) 
   (numpy-random-normal (0 $std)))

;; ============================================================================
;; MATHEMATICAL UTILITIES
;; ============================================================================

;; Standard error reporting
(= (Error $atom $message) $message)

(= (make-NaN)
    (sqrt-math -2)
)
;; Applies Logarithm to every element in a vector
(= (apply-log $vector $base)
   (map-atom $vector $x (log-math $base $x)))

;; Applies Power (exponentiation) to every element in a vector
(= (apply-power $vector $power)
   (map-atom $vector $x (pow-math $x $power)))

;; Sums all elements in a list using a fold-left approach
(= (sum $list)
   (foldl-atom $list 0 $acc $x (+ $acc $x)))

;; Computes the Euclidean (L2) Norm of a vector
(= (l2-norm $vector)
   (sqrt-math (sum (apply-power $vector 2))))

;; Converts a Boolean to an integer (True -> 1, False -> 0)
(= (1or0 $bool)
   (if (== $bool True) 1 0))

;; ============================================================================
;; matrice & VECTOR GENERATION
;; ============================================================================

;; Helper: Generates a single row for an identity matrice
(= (gen-row $r $c $dim)
   (if (== $c $dim)
       () 
       (let* (($val (if (== $r $c) 1 0))
              ($tail (gen-row $r (+ $c 1) $dim)))
         (cons-atom $val $tail))))

;; Helper: Generates the rows for an identity matrice
(= (gen-matrice-rows $r $dim)
   (if (== $r $dim)
       ()
       (let* (($current-row (gen-row $r 0 $dim))
              ($rest-rows (gen-matrice-rows (+ $r 1) $dim)))
         (cons-atom $current-row $rest-rows))))

;; Generates an Identity matrice of size $dim x $dim
(= (identity-matrice $dim)
   (gen-matrice-rows 0 $dim))

;; Generates a list of size $n filled with 1s
(= (generate-toy-list $n)
    (if (<= $n 0)
        ()  
        (let $rest (generate-toy-list (- $n 1))
             (cons-atom 1 $rest))))

;; Generates a zero-initialized vector of a specific length
(= (zeros-vec $length)
    (let $toy-list (generate-toy-list $length) 
         (map-atom $toy-list $x 0)))

;; Generates a list of integers from $lb up to (but not including) $ub
(= (range $lb $ub)
   (if (>= $lb $ub)
       ()
       (let $res (range (+ $lb 1) $ub) 
            (cons-atom $lb $res))))

;; ============================================================================
;; SCALAR-VECTOR OPERATIONS
;; ============================================================================

;; Applies an operation to every element in a vector using a scalar: (f vector num)
(= (scalar-op $vector $num $op)
   (if (== (size-atom $vector) 0)
       (Error $vector (EmptyList))
       (map-atom $vector $x ($op $x $num))))

;; Applies an operation with a scalar as the first argument: (f num vector)
(= (rev-scalar-op $num $vector $op)
   (if (== (size-atom $vector) 0)
       (Error $vector (EmptyList))
       (map-atom $vector $x ($op $num $x))))

;; ============================================================================
;; VECTOR-VECTOR OPERATIONS
;; ============================================================================

;; Performs element-wise operations on two vectors (e.g., addition, subtraction)
(= (vector-op $v1 $v2 $op)
   (if (or (== $v1 ()) (== $v2 ()))
       (if (and (== $v1 ()) (== $v2 ()))
           ()
           (Error (size-atom $v1) (size-atom $v2) LengthMismatch))
       (let* (($x1 (car-atom $v1))
              ($x2 (car-atom $v2))
              ($xs1 (cdr-atom $v1))
              ($xs2 (cdr-atom $v2))
              ($head-result ($op $x1 $x2))
              ($tail-results (vector-op $xs1 $xs2 $op)))
         (cons-atom $head-result $tail-results))))

;; Computes the Inner Product (Dot Product): sum(v1 * v2)
(= (inner-product $vec1 $vec2)
   (let $product (vector-op $vec1 $vec2 *) 
        (sum $product)))

;; Computes the Outer Product: creates a matrice where M[i][j] = v1[i] * v2[j]
(= (outer-product $vec1 $vec2)
   (if (or (== $vec1 ()) (== $vec2 ()))
       ()
       (let* (($x (car-atom $vec1))
              ($xs (cdr-atom $vec1))
              ($row (scalar-op $vec2 $x *))
              ($res (outer-product $xs $vec2)))
         (cons-atom $row $res))))

;; ============================================================================
;; matrice OPERATIONS
;; ============================================================================

;; Applies an operation to each row of a matrice using elements of a vector
(= (mat-vec-op $mat $vec $op)
   (if (or (== $mat ()) (== $vec ()))
       ()
       (let* (($row (car-atom $mat))
              ($s (car-atom $vec))
              ($m-tail (cdr-atom $mat))
              ($v-tail (cdr-atom $vec))
              ($new-row (scalar-op $row $s $op))
              ($res (mat-vec-op $m-tail $v-tail $op)))
         (cons-atom $new-row $res))))

;; Performs element-wise operations between two matrices of the same shape
(= (mat-mat-eles-op $mat1 $mat2 $op)
   (if (or (== $mat1 ()) (== $mat2 ()))
       ()
       (let* (($row1 (car-atom $mat1))
              ($row2 (car-atom $mat2))
              ($tail1 (cdr-atom $mat1))
              ($tail2 (cdr-atom $mat2))
              ($new-row (vector-op $row1 $row2 $op))
              ($rest-mat (mat-mat-eles-op $tail1 $tail2 $op)))
         (cons-atom $new-row $rest-mat))))

;; Applies an operation to every element in a matrice using a single scalar
(= (mat-scalar-op $matrice $num $op)
   (if (== (size-atom $matrice) 0)
       (Error $matrice (Emptymatrice))
       (map-atom $matrice $x (scalar-op $x $num $op))))

;; ============================================================================
;; CLIPPING UTILITIES (Bounds Constraints)
;; ============================================================================

;; Clips a single number between a lower bound (lb) and upper bound (ub)
(= (num-clip $x $lb $ub)
   (superpose (
       (if (< $x $lb) $lb (empty))
       (if (> $x $ub) $ub (empty))
       (if (and (>= $x $lb) (<= $x $ub)) $x (empty))
   )))

;; Clips all elements in a vector
(= (vec-clip $vec $lb $ub)
   (map-atom $vec $x (num-clip $x $lb $ub)))

;; Clips all elements in a matrice
(= (mat-clip $matrice $lb $ub)
   (map-atom $matrice $x (vec-clip $x $lb $ub)))


;; ============================================================================
;; CHOLESKY DECOMPOSITION (A = LLᵀ)
;; ============================================================================

;; Computes the sum of L[i][k] * L[j][k] for k = 0 to (limit-1)
(= (sum-lk $L $i $j $limit)
   (if (== $limit 0)
       0.0
       (let* (($a (nth (nth $L $i) (- $limit 1)))
              ($b (nth (nth $L $j) (- $limit 1)))
              ($prod (* $a $b))
              ($rest (sum-lk $L $i $j (- $limit 1))))
         (+ $prod $rest))))

;; ----------------------------------------------------------------------------
;; matrice UPDATE UTILITIES
;; ----------------------------------------------------------------------------

;; Replaces the value at index $j in a row
(= (update-row-cell $row $j $val)
   (if (== $j 0)
       (cons-atom $val (cdr-atom $row))
       (let* (($head (car-atom $row))
              ($tail (cdr-atom $row))
              ($updated-tail (update-row-cell $tail (- $j 1) $val)))
         (cons-atom $head $updated-tail))))

;; Replaces a whole row in a matrice at index $i
(= (update-matrice-row $rows $i $new-row)
   (let* (($head (car-atom $rows))
          ($tail (cdr-atom $rows)))
     (if (== $i 0)
         (cons-atom $new-row $tail)
         (let $updated-tail (update-matrice-row $tail (- $i 1) $new-row)
           (cons-atom $head $updated-tail)))))

;; Updates a specific cell (i, j) in the matrice
(= (update-matrice-cell $rows $i $j $val)
   (let* (($row (nth $rows $i))
          ($new-row (update-row-cell $row $j $val)))
     (update-matrice-row $rows $i $new-row)))

;; ----------------------------------------------------------------------------
;; DECOMPOSITION LOOPS
;; ----------------------------------------------------------------------------

;; Inner loop: Iterates through columns $j for a fixed row $i
(= (cholesky-j-loop $A $L $i $j $n)
   (if (> $j $i)
       ;; Row $i complete, move to next row
       (cholesky-loop $A $L (+ $i 1) $n)
       (let* (($s (sum-lk $L $i $j $j))
              ($aij (nth (nth $A $i) $j))
              ($val (if (== $i $j)
                        (sqrt-math (- $aij $s))
                        (/ (- $aij $s) (nth (nth $L $j) $j))))
              ($L-updated (update-matrice-cell $L $i $j $val)))
         (cholesky-j-loop $A $L-updated $i (+ $j 1) $n))))

;; Outer loop: Iterates through rows $i
(= (cholesky-loop $A $L $i $n)
   (if (== $i $n)
       $L
       (cholesky-j-loop $A $L $i 0 $n)))

;; ----------------------------------------------------------------------------
;; INITIALIZATION & ENTRY POINT
;; ----------------------------------------------------------------------------

;; Standard nth element accessor
(= (nth $list $n)
   (if (== $n 0) 
       (car-atom $list)
       (nth (cdr-atom $list) (- $n 1))))

;; Creates an empty matrice of size $rows x $cols filled with 0s
(= (make-matrice $rows $cols)
   (if (== $rows 0)
       ()
       (let* (($cols-row (zeros-vec $cols))
              ($next (make-matrice (- $rows 1) $cols)))
         (cons-atom $cols-row $next))))

;; Main Function
(= (cholesky-decomposition $A)
   (let* (($n (size-atom $A))
          ($L (make-matrice $n $n)))
     (cholesky-loop $A $L 0 $n)))


;; ============================================================================
;; NUMERICAL VALIDATION (Inf & NaN Checkers)
;; ============================================================================

;; Checks if a vector contains an Infinity value
(= (vec-inf-checker $vec)
   (if (== $vec ()) 
       False  ;; Base case: No infinity found
       (let* (($head (car-atom $vec))
              ($tail (cdr-atom $vec))
              ($is-inf (isinf-math $head)))
         (if $is-inf 
             True 
             (vec-inf-checker $tail)))))

;; Checks if a vector contains a NaN (Not-a-Number) value
(= (vec-NaN-checker $vec)
   (if (== $vec ()) 
       False
       (let* (($head (car-atom $vec))
              ($tail (cdr-atom $vec))
              ($is-nan (isnan-math $head)))
         (if $is-nan 
             True 
             (vec-NaN-checker $tail)))))

;; Checks the numerical integrity of a matrice.
;; Returns False if any row contains NaN or Inf.
(= (Pos-definitness-checker $mat)
   (if (== $mat ())
       True  ;; All rows are clean
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ;; Identify if the current row has any numerical issues
              ($row-errors (collapse (superpose ((vec-NaN-checker $row) 
                                                 (vec-inf-checker $row))))))
         (if (== $row-errors (False False)) ;; Adjusted for standard boolean check
             (Pos-definitness-checker $rest) 
             False))))

;; ============================================================================
;; MATH UTILITIES
;; ============================================================================

;; Negates a number (multiplies by -1)
(= (-ve $number)
   (- 0.0 $number))

;; Hack to force a number into a float representation
(= (to-float $number)
   (- (+ $number 0.1) 0.1))

;; Performs division, ensuring the numerator is treated as a float
(= (div $num $denom)
   (/ (to-float $num) $denom))



;; ============================================================================
;; matrice TRANSPOSITION HELPERS
;; ============================================================================

;; Extracts the first element (head) of every row to form a new column
(= (get-heads $mat)
   (if (== $mat ())
       ()
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ($head-rest (get-heads $rest))
              ($val (car-atom $row)))
         (cons-atom $val $head-rest))))

;; Extracts the remaining elements (tail) of every row 
(= (get-tails $mat)
   (if (== $mat ())
       ()
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ($tail-rest (get-tails $rest))
              ($val (cdr-atom $row)))
         (cons-atom $val $tail-rest))))

;; Main Transpose Function: Flips a matrice over its diagonal
(= (transpose-matrice $mat)
   (if (== $mat ())
       ()
       (let $first-row (car-atom $mat)
         (if (== $first-row ())
             ()
             (let* (($head (get-heads $mat))
                    ($tail (get-tails $mat))
                    ($t (transpose-matrice $tail)))
               (cons-atom $head $t))))))

;; ============================================================================
;; RANDOM matrice GENERATION (Standard Normal)
;; ============================================================================

;; Generates a single row (vector) of size $dim filled with Gaussian values
(= (gen-gauss-row $dim)
   (if (<= $dim 0)
       ()
       (let* (($gauss (gauss 1)) ;; Assumes gauss function is available
              ($res (gen-gauss-row (- $dim 1))))
         (cons-atom $gauss $res))))

;; Generates a matrice of $lambda_ rows, each of size $dim
(= (standard-normal $dim $lambda_)
   (if (<= $lambda_ 0)
       ()
       (let* (($row (gen-gauss-row $dim))
              ($res (standard-normal $dim (- $lambda_ 1))))
         (cons-atom $row $res))))

;; ============================================================================
;; matrice MULTIPLICATION
;; ============================================================================

;; Computes the dot product of two vectors
(= (dot-product $v1 $v2)
   (sum (vector-op $v1 $v2 *)))

;; Multiplies a single row by all columns of the second matrice (M2-Transposed)
(= (row-times-matrice $row ()) ())
(= (row-times-matrice $row $m2-t)
   (let* (($col (car-atom $m2-t))
          ($rest-cols (cdr-atom $m2-t))
          ($dot (dot-product $row $col))
          ($res (row-times-matrice $row $rest-cols)))
     (cons-atom $dot $res)))

;; Recursively processes each row of M1 to perform matrice-matrice Multiplication
(= (matrice-mul-recursive () $m2-t) ())
(= (matrice-mul-recursive $m1 $m2-t)
   (let* (($row (car-atom $m1))
          ($rest-m1 (cdr-atom $m1))
          ($new-row (row-times-matrice $row $m2-t))
          ($res (matrice-mul-recursive $rest-m1 $m2-t)))
     (cons-atom $new-row $res)))

;; Main Multiplication Entry Point: Includes dimension validation
(= (mat-mat-mul $m1 $m2)
   (let* (($m1-row0 (index-atom $m1 0))
          ($m1-cols (size-atom $m1-row0))
          ($m2-rows (size-atom $m2)))
     (if (not (== $m1-cols $m2-rows))
         (Error ($m1-cols $m2-rows) DimensionMismatch)
         (let $m2-t (transpose-matrice $m2)
           (matrice-mul-recursive $m1 $m2-t)))))

;; ============================================================================
;; MULTIVARIATE NORMAL SAMPLING
;; ============================================================================

;; Internal helper: Recursively adds the mean vector to each row of the transformed samples
(= (add-mean-to-samples () $mean) ())
(= (add-mean-to-samples $samples $mean)
   (let* (($row (car-atom $samples))
          ($rest (cdr-atom $samples))
          ($new-row (vec-add $row $mean)) 
          ($res (add-mean-to-samples $rest $mean)))
     (cons-atom $new-row $res)))

;; Generates $lambda_ samples from a Multivariate Normal distribution
;; Formula: Y = mean + L * Z, where L is the Cholesky factor of the Covariance matrice
(= (random-multivariate $mean $cov-matrice $lambda_)
   (let* (
       ;; Decompose Covariance into Lower Triangular L
       ($L (cholesky-decomposition $cov-matrice))
       
       ;; Generate Standard Normal samples Z (shape: lambda x dim)
       ($Z (standard-normal (size-atom $mean) $lambda_))
       
       ;; Transform: Y = Z * L^T (matrice multiplication handles the L * Z part)
       ($LT (transpose-matrice $L))
       ($transformed (mat-mat-mul $Z $LT))
       
       ;; Shift: Add mean vector to every sample
       ($final-samples (add-mean-to-samples $transformed $mean))
   )
   $final-samples))



;; ============================================================================
;; LIST & INDEX UTILITIES
;; ============================================================================

;; Generates a list from $start to $end with a given $step
(= (range $start $end $step)
    (if (> $start $end)
        ()
        (let $next (range (+ $start $step) $end $step)
             (cons-atom $start $next))))

;; Generates 0-based indices for any given list
(= (make-indices $lst) 
   (range 0 (- (size-atom $lst) 1) 1))

;; Removes the element at the specified index $i from a list
(= (remove-index $lst $i)
   (if (== $i 0)
       (cdr-atom $lst)
       (let* (($head (index-atom $lst 0))
              ($tail (cdr-atom $lst))
              ($rest (remove-index $tail (- $i 1))))
         (cons-atom $head $rest))))

;; ============================================================================
;; VECTOR OPERATIONS
;; ============================================================================

;; Multiplies every element in vector $v by scalar $c
(= (vec-scale $c $v)
   (map-atom $v $x (* $c $x)))

;; Adds two vectors element-wise
(= (vec-add $a $b)
   (if (== (size-atom $a) 0)
       ()
       (let* (
              ($xa (car-atom $a))
              ($xb (car-atom $b))
              ($tail-a (cdr-atom $a))
              ($tail-b (cdr-atom $b))
             ($sum (+ $xa $xb))
              ($tail (vec-add $tail-a $tail-b))
              )
         (cons-atom $sum $tail)
         )))

;; ============================================================================
;; FITNESS PAIRING & SORTING (Ranking Logic)
;; ============================================================================

;; Creates pairs of (index fitness) from two separate lists
(= (pair-index-fitness $inds $fits)
   (map-atom $inds $i
     ($i (index-atom $fits $i))))

;; Helper: Recursively finds the index of the pair with the highest fitness value
(= (find-max-helper $pairs $i $max-idx $maxval)
   (if (== $i (size-atom $pairs))
       $max-idx
       (let* (($pair (index-atom $pairs $i))
              ($val (index-atom $pair 1)))
         (if (> $val $maxval)
             (find-max-helper $pairs (+ $i 1) $i $val)
             (find-max-helper $pairs (+ $i 1) $max-idx $maxval)))))

;; Returns the index within the $pairs list that holds the maximum fitness
(= (max-index $pairs)
   (let* (($first (index-atom $pairs 0))
          ($start (index-atom $first 1)))
     (find-max-helper $pairs 1 0 $start)))

;; Sorts (index fitness) pairs in descending order based on fitness
(= (sort-pairs-desc $pairs)
    (if (< (size-atom $pairs) 2)
        $pairs
        (let* (($idx (max-index $pairs))
               ($maxPair (index-atom $pairs $idx))
               ($rest (remove-index $pairs $idx))
               ($sorted-rest (sort-pairs-desc $rest)))
          (cons-atom $maxPair $sorted-rest))))

;; ============================================================================
;; EXTRACTION & SELECTION
;; ============================================================================

;; Extracts the first $mu indices from a list of sorted (index fitness) pairs
(= (extract-indices $pairs $mu)
    (if (or (== $mu 0) (== (size-atom $pairs) 0))
        ()
        (let* (($first-pair (index-atom $pairs 0))
               ($idx (index-atom $first-pair 0))
               ($rest (cdr-atom $pairs)) ;; Using cdr-atom is cleaner than remove-index 0
               ($tail (extract-indices $rest (- $mu 1))))
          (cons-atom $idx $tail))))

;; Selects full samples from a list based on a provided list of indices
(= (select-by-indices $samples $indices)
    (if (== (size-atom $indices) 0)
        ()
        (let* (($first-i (index-atom $indices 0))
               ($item (index-atom $samples $first-i))
               ($rest (select-by-indices $samples (cdr-atom $indices))))
          (cons-atom $item $rest))))

;; ============================================================================
;;  LIST & NONDETERMINISM HELPERS
;; ============================================================================



;; Merges two lists using the grounded union-atom function
(= (custom-union-atom $list1 $list2)
    (union-atom $list1 $list2))

;; Ensures all elements in a list are unique
(= (custom-unique-atom $list)
    (unique-atom $list))

;; Unionize: Recursively flattens and merges lists while ensuring uniqueness.
;; If the head is a single element, it cons onto the accumulator; 
;; if it's a list, it performs a set union.
(= (unionize () $acc) (custom-unique-atom $acc))
(= (unionize $list $acc)
   (let* (($ht (decons-atom $list))
          (($head $tail) $ht))
     (if (== (size-atom $head) 1)
         (unionize $tail (cons-atom (car-atom $head) $acc))
         (unionize $tail (custom-union-atom $head $acc)))))


;; ============================================================================
;;  Search & Extraction
;; ============================================================================

;; Checks if the second element (index 1) of a list matches $val.
;; Returns the whole list if matched, otherwise an empty list.
(= (match-val-best-nd $val $best-nd)
   (let $obj (index-atom $best-nd 1)
    (if (== $val $obj)
        $best-nd
        ())))

;; Linear search through a list of entries. Returns the first entry that matches $val.
(= (max-best-nd-helper $val $best-nds)
   (if (== $best-nds ())
      ()
      (let* (($hd (car-atom $best-nds))
             ($res (match-val-best-nd $val $hd)))
       (if (== $res ())
          (max-best-nd-helper $val (cdr-atom $best-nds))
          $res))))

;; Cleaner: Maps through a list of lists and extracts the element at $index from each.
;; This version collects ALL results into a resulting list.
(= (cleaner $lists $index)
   (if (== $lists ())
       ()  
       (let* (($hd (car-atom $lists))
              ($res (index-atom $hd $index))
              ($remaining (cleaner (cdr-atom $lists) $index)))
             (cons-atom $res $remaining))))






;; ============================================================================
;;  Invert a Lower Triangular Matrice And Compute Its Inverse Square Root
;; ============================================================================


;; --- C-inv-sqrt ---
;; High-level function to find the inverse square root of a matrix
;; Step: Cholesky -> Invert Lower -> Transpose
(= (C-inv-sqrt $matrice)
    (transpose-matrice (inverse-lmatrice (chol-decomp $matrice))))

;; --- Append ---
;; Standard tail-append to maintain row order during matrix construction
(= (append () $item) ($item))
(= (append $list $item)
   (let* (($head (car-atom $list))
          ($tail (cdr-atom $list))
          ($updated-tail (append $tail $item)))
         (cons-atom $head $updated-tail)))

;; --- Summation (Forward Substitution) ---
;; Calculates Σ (L[i][k] * Inv[k][j]) for k from j to i-1
(= (sum-prev $row $inv-matrice $i $j $k)
   (if (== $k $i)
       0.0
       (+ (* (nth $row $k) (nth (nth $inv-matrice $k) $j))
          (sum-prev $row $inv-matrice $i $j (+ $k 1)))))

;; --- build-row ---
;; Constructs a single row of the inverse matrix.
;; Uses 1/L[i][i] for diagonals and the Forward Substitution formula for others.
(= (build-row $row $inv-matrice $i $j $n)
   (if (== $j $n)
       ()
       (let* (($val (if (> $j $i)
                        0.0
                        (if (== $i $j)
                            (/ 1.0 (nth $row $i))
                            (/ (- 0.0 (sum-prev $row $inv-matrice $i $j $j)) (nth $row $i)))))
                            ($rest (build-row $row $inv-matrice $i (+ $j 1) $n)))
             (cons-atom $val $rest)
             
             )))

;; --- invert-rec ---
;; Iterates through the rows of the input matrix to build the inverse matrix
(= (invert-rec $m $inv $i $n)
   (if (== $i $n)
       $inv
       (let* (($new-row (build-row (nth $m $i) $inv $i 0 $n))
              ($updated-inv (append $inv $new-row)))
             (invert-rec $m $updated-inv (+ $i 1) $n))))


;; Dynamically determines matrix size and starts inversion
(= (inverse-lmatrice $matrice)
   (let $n (size-atom $matrice) 
        (invert-rec $matrice () 0 $n)))

