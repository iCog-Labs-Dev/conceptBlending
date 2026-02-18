
; !(import! &self list-op-utils)
; ;Evaluate expression via py-call:
;!(import! &self "utils/numpy_methods.py")

(=(np-max $ref-point $objs-val $axis)
    (let* (
    ($result (py-call (numpy_methods.np_max $ref-point $objs-val $axis)))
)
    $result
))




(= (py-eval $str)
   (let $dict (py-call (dict))
        (py-call (quote (eval $str $dict $dict)))))

;Add to builtins a function that can call functions via keyword arguments
;!(py-eval "setattr(__import__('builtins'),'apply_kwargs',(lambda f,d: f(**d))) or 0")

;!(py-eval "setattr(__import__('builtins'),'apply_args',(lambda f,args: f(*args))) or 0")



(=(numpy-random-normal $rng) (let*
        (
            ($numpy (py-call (importlib.import_module "numpy")))
            ($np-random (py-call (getattr $numpy "random")))
            ($rand (py-call (getattr $np-random "normal")))
            ($result (py-call (builtins.apply_args $rand $rng)))
            
        )
        $result)
)

(= (np-dirichlet $alpha $size)
    (let*
        (
            ($numpy (py-call (importlib.import_module "numpy")))
            ($np-random (py-call (getattr $numpy "random")))
            ($dirichlet (py-call (getattr $np-random "dirichlet")))

            
        )
        (py-call (builtins.apply_args $dirichlet ($alpha $size)))
))


;  !(numpy-random-normal (1 3))



(=(gauss $std) (numpy-random-normal (0 $std)))

;!(gauss 3)

(=(Error $atom $message) 
    $message)

(= (apply-log $vector $base)
    (map-atom $vector $x (log-math $base $x))
)

(= (apply-power $vector $power)
    (map-atom $vector $x (pow-math $x $power))
)

(= (sum $list)
    (foldl-atom $list 0 $acc $x (+ $acc $x))
)

(= (l2-norm $vector)
    (
        sqrt-math(
            sum (apply-power $vector 2)
        )
    )
)

; !(l2-norm (0.2 0.8))

(= (1or0 $bool)
    (if (== $bool True) 1 0)
)


##########done
;; Helper: Generate a single row (columns 0 to dim-1)
(= (gen-row $r $c $dim)
   (if (== $c $dim)
       () ;; Base Case: End of row
       (let* (
              ;; Determine value: 1 if diagonal, 0 otherwise
              ($val (if (== $r $c) 1 0))
              
              ;; Recurse for the rest of the row
              ($tail (gen-row $r (+ $c 1) $dim))
             )
         (cons-atom $val $tail)
       )
   )
)

;;Helper: Generate the matrix rows (rows 0 to dim-1)
(= (gen-matrix-rows $r $dim)
   (if (== $r $dim)
       () ;; Base Case: End of matrix
       (let* (
              ;; Build the current row
              ($current-row (gen-row $r 0 $dim))
              
              ;; Recurse for the rest of the matrix
              ($rest-rows (gen-matrix-rows (+ $r 1) $dim))
             )
         (cons-atom $current-row $rest-rows)
       )
   )
)

(= (identity-matrice $dim)
   (gen-matrix-rows 0 $dim)
)

;!(identity-matrice 3)

;; ###done
(= (generate-toy-list $n)

    (if (<= $n 0)
        ()  
        (let* 
             (($rest (generate-toy-list (- $n 1))))
             (cons-atom 1 $rest) 
        )
    )
)
;!(generate-toy-list 5)

(= (zeros-vec $length)
    (let $toy-list (generate-toy-list $length) (map-atom $toy-list $x 0))
)


; !(zeros-vec 8)

###########done
(= (range $lb $ub)
   (if (>= $lb $ub)
       ()
       (let $res (range (+ $lb 1) $ub) (cons-atom $lb $res)) ;; Base case: if lower bound meets upper bound, stop.
       ))

;; --- Test ---
;!(range 1 6)
###done
(= (scalar-op $vector $num $op)
    (
        if (== (size-atom $vector) 0)
        (Error $vector (empty)List)
        (map-atom $vector $x ($op $x $num))
    )
)
; !(scalar-op () 10 +)

(= (rev-scalar-op $num $vector $op)
    (
        if (== (size-atom $vector) 0)
        (Error $vector (empty)List)
        (map-atom $vector $x ($op $num $x))
    )
)

####################################
;; Main Recursive Function
(= (vector-op $v1 $v2 $op)
   (if (or (== $v1 ()) (== $v2 ()))
       ;; Base Case: If both are empty, we're done. 
       ;; If only one is empty, it's a length mismatch.
       (if (and (== $v1 ()) (== $v2 ()))
           ()
           (Error (size-atom $v1) (size-atom $v2) LengthMismatch))
       
       ;; Recursive Step
       (let* (($x1 (car-atom $v1))
              ($x2 (car-atom $v2))
              ($xs1 (cdr-atom $v1))
              ($xs2 (cdr-atom $v2))
              ;; Apply the operation to the heads
              ($head-result ($op $x1 $x2))
              ;; Recurse on the tails
              ($tail-results (vector-op $xs1 $xs2 $op)))
         (cons-atom $head-result $tail-results))))

;; --- Tests ---
;!(vector-op (1 2 3) (4 5 6) +)  ;; Expected: (5 7 9);

;!(vector-op (10 20) (2 5) -)    ;; Expected: (8 15)


#####done
(= (inner-product $vec1 $vec2)
    
        (let $product (vector-op $vec1 $vec2 *) 
             (sum $product)
        )
)

;!(inner-product (1 2 3) (2 3 4))

#################done
(= (mat-vec-op $mat $vec $op)
   (if (or (== $mat ()) (== $vec ()))
       () ;; Single exit point: if either is empty, return empty list
       (let* (($row (car-atom $mat))
              ($s (car-atom $vec))
              ($m-tail (cdr-atom $mat))
              ($v-tail (cdr-atom $vec))
              ($new-row (scalar-op $row $s $op))
              ($res (mat-vec-op $m-tail $v-tail $op)))
         (cons-atom $new-row $res))))
;!(mat-vec-op ((1 2 3)(4 5 6)(7 8 9)) (1 6 1) +)


##############done
(= (mat-mat-eles-op $mat1 $mat2 $op)
   (if (or (== $mat1 ()) (== $mat2 ()))
       () ;; Base case: stop when lists are empty
       (let* (($row1 (car-atom $mat1))
              ($row2 (car-atom $mat2))
              ($tail1 (cdr-atom $mat1))
              ($tail2 (cdr-atom $mat2))
              ;; Use your existing vector-op for the current rows
              ($new-row (vector-op $row1 $row2 $op))
              ;; Recurse for the remaining rows
              ($rest-mat (mat-mat-eles-op $tail1 $tail2 $op))
              )
         (cons-atom $new-row $rest-mat)
         )))

;; --- Test ---
;!(mat-mat-eles-op ((1 2) (5 9)) (( 8 7) ( 2 1)) *)
;; Output: ((9 16 21) (24 25 24) (21 16 9))
############done
;; 1. Helper: Scalar multiplication
(= (mult-scalar-vec $s ()) ())
(= (mult-scalar-vec $s $vec)
   (let* (($x (car-atom $vec))
          ($xs (cdr-atom $vec))
          ($mul (* $s $x))
          ($res (mult-scalar-vec $s $xs)))
     (cons-atom $mul $res)))

;; 2. Main Function: Unified Pattern
;; We remove the separate (= (outer-product () $vec2) ()) 
;; and handle everything inside one if-block.
(= (outer-product $vec1 $vec2)
   (if (or (== $vec1 ()) (== $vec2 ()))
       ()
       (let* (($x (car-atom $vec1))
              ($xs (cdr-atom $vec1))
              ($row (mult-scalar-vec $x $vec2))
              ($res (outer-product $xs $vec2)))
         (cons-atom $row $res))))

;; --- Test ---
;!(outer-product (1 2 3) (5 5 6))
;; Output: ((4 5 6) (8 10 12) (12 15 18))

(= (mat-scalar-op $matrice $num $op)
    (
        if (== (size-atom $matrice) 0)
        (Error $matrice (empty)Matrice)
        (map-atom $matrice $x (scalar-op $x $num $op))
    )
)

; !(mat-scalar-op ((1 2 3)(4 5 6)(7 8 9)) 10 +)

(= (num-clip $x $lb $ub)
    (superpose(
        (if (< $x $lb) $lb (empty))
        (if (> $x $ub) $ub (empty))
        (if (and (>= $x $lb) (<= $x $ub)) $x (empty))
        )
    )
)

; !(num-clip 15 0 10)


(= (vec-clip $vec $lb $ub)
    (map-atom $vec $x (num-clip $x $lb $ub))
)

(= (mat-clip $matrice $lb $ub)
    (map-atom $matrice $x (vec-clip $x $lb $ub))
)

;; --- Internal Helper 1: Handles Columns (Triangular) ---
(= (add-row-internal $row $r-idx $c-idx $lspace)
   (if (or (== $row ()) (> $c-idx $r-idx))
       ()
       (let* (($val (car-atom $row))
              ($rest (cdr-atom $row))
              ;; Creates the label l00, l10, etc.
              ($label (format-args l{}{} ($r-idx $c-idx)))
              ($void (add-atom $lspace (cell $label $val)))
              ($next-c (+ $c-idx 1)))
         (add-row-internal $rest $r-idx $next-c $lspace))))

;; --- Internal Helper 2: Handles Rows ---
(= (add-rows-recursive $mat $r-idx $lspace)
   (if (== $mat ())
       ()
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ($void (add-row-internal $row $r-idx 0 $lspace))
              ($next-r (+ $r-idx 1)))
         (add-rows-recursive $rest $next-r $lspace))))

;; --- Main Function: Only 2 Inputs ---
#######done
(= (add-lmat-to-lspace $mat $lspace)
   (add-rows-recursive $mat 0 $lspace))

;; --- Execution ---
;!(bind! &lspace (new-space))
;!(add-lmat-to-lspace ((1 2 3) (4 5 6) (7 8 9)) &lspace)
;!(let $result (collapse (match &lspace $x $x)) $result)

##### done
(= (call-lik $lspace $i $k)
    (let $label (format-args l{}{} ($i $k))
      (match $lspace (cell $label $x) $x)
   )
)
#####done
(= (call-ljk $lspace $j $k)
    (let $label (format-args l{}{} ($j $k)) 
        (match $lspace (cell $label $x) $x))
)

####done
(= (call-mkj $mspace $k $j)
(let $label (format-args l{}{} ($k $j)) (match $mspace (cell $label $x) $x))
    
)


#############done
;; 1. Recursive Helper: Iterates k from 0 to j-1
(= (cells-product-rec $i $j $lspace $k)
   (if (>= $k $j)
       () ;; Base Case: Stop when k reaches j
       (let* (
              ;; Get values from the space
              ($val-ik (call-lik $lspace $i $k))
              ($val-jk (call-ljk $lspace $j $k))
              
              ;; Calculate product
              ($prod (* $val-ik $val-jk))
              
              ;; Recurse for the next k
              ($tail (cells-product-rec $i $j $lspace (+ $k 1)))
             )
         ;; Add product to the list
         (cons-atom $prod $tail)
       )
   )
)

###done
(= (cells-product $i $j $lspace)
   (cells-product-rec $i $j $lspace 0)
)

###done
(= (inverse-product-rec $i $j $lspace $mspace $k)
   (if (>= $k $i)
       () ;; Base Case: Stop when k reaches i
       (let* (
              ;; Fetch values
              ($lik (call-lik $lspace $i $k))
              ($mkj (call-mkj $mspace $k $j))
              
              ;; Calculate product
              ($prod (* $lik $mkj))
              
              ;; Recursive call for next k
              ($tail (inverse-product-rec $i $j $lspace $mspace (+ $k 1)))
             )
         ;; Build the list
         (cons-atom $prod $tail)
       )
   )
)

##done
(= (inverse-cells-product $i $j $lspace $mspace)
   ;; Start k at j, effectively skipping all empty checks for k < j
   (inverse-product-rec $i $j $lspace $mspace $j)
)


(= (make-NaN)
    (sqrt-math -2)
)


#####################
(= (l00 $cov-matrice $lspace)
    (let* (($a0 (index-atom $cov-matrice 0))
            ($a00 (index-atom $a0 0))
           ($l00 (sqrt-math $a00))
           ;; Generate the label "l00" dynamically
           ($label (format-args l{}{} (0 0)))
           ($void (add-atom $lspace (cell $label $l00)))
           
           ) $l00)
 )
##########################

(= (l10 $cov-matrice $lspace)
    (let* (
        ($labell00 (format-args l{}{} (0 0)))
        ;; 1. Get the value of L00 from the space using dynamic label
        ($l00 (match $lspace (cell $labell00 $x) $x))
        
        ;; 2. Get A10 from the covariance matrix
        ($a1 (index-atom $cov-matrice 1))
        ($a10 (index-atom $a1 0))
        
        ;; 3. Calculate L10 = A10 / L00
        ($val (/ $a10 $l00))
        
        ;; 4. Generate the label "l10" and add to space
        ($label (format-args l{}{} (1 0)))
        ($void (add-atom $lspace (cell $label $val)))
    )
    ;; Return the calculated value
    $val)
)


################

(= (l11 $cov-matrice $lspace)
    (let* (
        ($label1 (format-args l{}{} (1 0)))
        ;; 1. Fetch L10 from the space dynamically
        ($l10 (match $lspace (cell $label1 $x) $x))
        
        ;; 2. Get A11 from the matrix
        ($a1 (index-atom $cov-matrice 1))
        ($a11 (index-atom $a1 1))
        
        ;; 3. Calculate L11 = sqrt(A11 - L10^2)
        ($val (sqrt-math (- $a11 (pow-math $l10 2))))
        
        ;; 4. Generate label "l11" and store the value
        ($label (format-args l{}{} (1 1)))
        ($void (add-atom $lspace (cell $label $val)))
    )
    ;; Return the result
    $val)
)


(= (l20 $cov-matrice $lspace)
    (let* (
        ;; 1. Retrieve l00 from space using dynamic label
        ($label1 (format-args l{}{} (0 0)))
        ($l00 (match $lspace (cell $label1 $x) $x))
        
        ;; 2. Get A20 from the matrix
        ($a2 (index-atom $cov-matrice 2))
        ($a20 (index-atom $a2 0))
        
        ;; 3. Calculate L20 = A20 / L00
        ($val (/ $a20 $l00))
        
        ;; 4. Store with dynamic label l20
        ($label (format-args l{}{} (2 0)))
        ($void (add-atom $lspace (cell $label $val)))
    )
    ;; Return the result
    $val)
)
(= (l21 $cov-matrice $lspace)
    (let* (
        ($label4 (format-args l{}{} (2 1)))
        ($label1 (format-args l{}{} (1 0)))
        ($label2 (format-args l{}{} (2 0)))
        ($label3 (format-args l{}{} (1 1)))
        ($a2 $l10 $l11 $l20) (collapse(superpose((index-atom $cov-matrice 2) (match $lspace (cell $label1 $x) $x) (match $lspace (cell $label3 $x) $x) (match $lspace (cell $label2 $x) $x))))
        ($a21 (index-atom $a2 1))
        ($l21 (/ (- $a21 (* $l20 $l10)) $l11))
        ($add (add-atom $lspace (cell $label4 $l21)))

    ) $l21
        
           
        )
    )


(= (l22 $cov-matrice $lspace)
    (let* (
        ($labell22 (format-args l{}{} (2 2)))
        ($a2 (index-atom $cov-matrice 2))
        ($a22 (index-atom $a2 2))
        ($sum (sum (cells-product 2 2 $lspace)))
        ($l22 (sqrt-math (- $a22 $sum)))
        ($add (add-atom $lspace (cell $labell22 $l22)))
    ) $l22)
)


(= (l30 $cov-matrice $lspace)
    (let* (
        ($labell00 (format-args l{}{} (0 0)))
        ($labell30 (format-args l{}{} (3 0)))
        ($a3 (index-atom $cov-matrice 3))
        ($l00 (match $lspace (cell $labell00 $x) $x))
        ($a30 (index-atom $a3 0))
        ($l30 (/ $a30 $l00))
        ($add (add-atom $lspace (cell $labell30 $l30)))
    ) $l30)
)

(= (l31 $cov-matrice $lspace)
    (let* (
        ($labell30 (format-args l{}{} (3 0)))
        ($labell10 (format-args l{}{} (1 0)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labell31 (format-args l{}{} (3 1)))
        ($a3 (index-atom $cov-matrice 3))
        (($l30 $l10 $l11) (collapse(superpose((match $lspace (cell $labell30 $x) $x) (match $lspace (cell $labell10 $x) $x) (match $lspace (cell $labell11 $x) $x)))) )
        ($a31 (index-atom $a3 1))
        ($l31 (/ (- $a31 (* $l30 $l10)) $l11))
        ($add (add-atom $lspace (cell $labell31 $l31)))
    ) $l31)
)

(= (l32 $cov-matrice $lspace)
    (let* (
        ($labell22 (format-args l{}{} (2 2)))
        ($labell32 (format-args l{}{} (3 2)))
        ($a3 (index-atom $cov-matrice 3))
        ($l22 (match $lspace (cell $labell22 $x) $x))
        ($a33 (index-atom $a3 2))
        ($l32 (/ (- $a33 (sum (cells-product 3 2 $lspace))) $l22))
        ($add (add-atom $lspace (cell $labell32 $l32)))
    ) $l32)
)

(= (l33 $cov-matrice $lspace)
    (let* (
        ($labell33 (format-args l{}{} (3 3)))
        ($a3 (index-atom $cov-matrice 3))
        ($a33 (index-atom $a3 3))
        ($sum (sum (cells-product 3 3 $lspace)))
        ($l33 (sqrt-math (- $a33 $sum)))
        ($add (add-atom $lspace (cell $labell33 $l33)))
    ) $l33)
)

(= (l40 $cov-matrice $lspace)
    (let* (
        ($labell00 (format-args l{}{} (0 0)))
        ($labell40 (format-args l{}{} (4 0)))
        ($a4 (index-atom $cov-matrice 4))
        ($l00 (match $lspace (cell $labell00 $x) $x))
        ($a40 (index-atom $a4 0))
        ($l40 (/ $a40 $l00))
        ($add (add-atom $lspace (cell $labell40 $l40)))
    ) $l40)
)

(= (l41 $cov-matrice $lspace)
    (let* (
        ($labell40 (format-args l{}{} (4 0)))
        ($labell10 (format-args l{}{} (1 0)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labell41 (format-args l{}{} (4 1)))
        ($a4 (index-atom $cov-matrice 4))
        (($l40 $l10 $l11) (collapse(superpose((match $lspace (cell $labell40 $x) $x) (match $lspace (cell $labell10 $x) $x) (match $lspace (cell $labell11 $x) $x)))) )
        ($a41 (index-atom $a4 1))
        ($l41 (/ (- $a41 (* $l40 $l10)) $l11))
        ($add (add-atom $lspace (cell $labell41 $l41)))
    ) $l41)
)

(= (l42 $cov-matrice $lspace)
    (let* (
        ($labell22 (format-args l{}{} (2 2)))
        ($labell42 (format-args l{}{} (4 2)))
        ($a4 (index-atom $cov-matrice 4))
        ($l22 (match $lspace (cell $labell22 $x) $x))
        ($a42 (index-atom $a4 2))
        ($l42 (/ (- $a42 (sum (cells-product 4 2 $lspace))) $l22))
        ($add (add-atom $lspace (cell $labell42 $l42)))
    ) $l42)
)

(= (l43 $cov-matrice $lspace)
    (let* (
        ($labell33 (format-args l{}{} (3 3)))
        ($labell43 (format-args l{}{} (4 3)))
        ($a4 (index-atom $cov-matrice 4))
        ($l33 (match $lspace (cell $labell33 $x) $x))
        ($a43 (index-atom $a4 3))
        ($l43 (/ (- $a43 (sum (cells-product 4 3 $lspace))) $l33))
        ($add (add-atom $lspace (cell $labell43 $l43)))
    ) $l43)
)

(= (l44 $cov-matrice $lspace)
    (let* (
        ($labell44 (format-args l{}{} (4 4)))
        ($a4 (index-atom $cov-matrice 4))
        ($a44 (index-atom $a4 4))
        ($sum (sum (cells-product 4 4 $lspace)))
        ($l44 (sqrt-math (- $a44 $sum)))
        ($add (add-atom $lspace (cell $labell44 $l44)))
    ) $l44)
)

(= (l50 $cov-matrice $lspace)
    (let* (
        ($labell00 (format-args l{}{} (0 0)))
        ($labell50 (format-args l{}{} (5 0)))
        ($a5 (index-atom $cov-matrice 5))
        ($l00 (match $lspace (cell $labell00 $x) $x))
        ($a50 (index-atom $a5 0))
        ($l50 (/ $a50 $l00))
        ($add (add-atom $lspace (cell $labell50 $l50)))
    ) $l50)
)

(= (l51 $cov-matrice $lspace)
    (let* (
        ($labell50 (format-args l{}{} (5 0)))
        ($labell10 (format-args l{}{} (1 0)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labell51 (format-args l{}{} (5 1)))
        ($a5 (index-atom $cov-matrice 5))
        (($l50 $l10 $l11) (collapse(superpose((match $lspace (cell $labell50 $x) $x) (match $lspace (cell $labell10 $x) $x) (match $lspace (cell $labell11 $x) $x)))) )
        ($a51 (index-atom $a5 1))
        ($l51 (/ (- $a51 (* $l50 $l10)) $l11))
        ($add (add-atom $lspace (cell $labell51 $l51)))
    ) $l51)
)

(= (l52 $cov-matrice $lspace)
    (let* (
        ($labell22 (format-args l{}{} (2 2)))
        ($labell52 (format-args l{}{} (5 2)))
        ($a5 (index-atom $cov-matrice 5))
        ($l22 (match $lspace (cell $labell22 $x) $x))
        ($a52 (index-atom $a5 2))
        ($l52 (/ (- $a52 (sum (cells-product 5 2 $lspace))) $l22))
        ($add (add-atom $lspace (cell $labell52 $l52)))
    ) $l52)
)

(= (l53 $cov-matrice $lspace)
    (let* (
        ($labell33 (format-args l{}{} (3 3)))
        ($labell53 (format-args l{}{} (5 3)))
        ($a5 (index-atom $cov-matrice 5))
        ($l33 (match $lspace (cell $labell33 $x) $x))
        ($a53 (index-atom $a5 3))
        ($l53 (/ (- $a53 (sum (cells-product 5 3 $lspace))) $l33))
        ($add (add-atom $lspace (cell $labell53 $l53)))
    ) $l53)
)

(= (l54 $cov-matrice $lspace)
    (let* (
        ($labell44 (format-args l{}{} (4 4)))
        ($labell54 (format-args l{}{} (5 4)))
        ($a5 (index-atom $cov-matrice 5))
        ($l44 (match $lspace (cell $labell44 $x) $x))
        ($a54 (index-atom $a5 4))
        ($l54 (/ (- $a54 (sum (cells-product 5 4 $lspace))) $l44))
        ($add (add-atom $lspace (cell $labell54 $l54)))
    ) $l54)
)

(= (l55 $cov-matrice $lspace)
    (let* (
        ($labell55 (format-args l{}{} (5 5)))
        ($a5 (index-atom $cov-matrice 5))
        ($a55 (index-atom $a5 5))
        ($sum (sum (cells-product 5 5 $lspace)))
        ($l55 (sqrt-math (- $a55 $sum)))
        ($add (add-atom $lspace (cell $labell55 $l55)))
    ) $l55)
)

(= (l60 $cov-matrice $lspace)
    (let* (
        ($labell00 (format-args l{}{} (0 0)))
        ($labell60 (format-args l{}{} (6 0)))
        ($a6 (index-atom $cov-matrice 6))
        ($l00 (match $lspace (cell $labell00 $x) $x))
        ($a60 (index-atom $a6 0))
        ($l60 (/ $a60 $l00))
        ($add (add-atom $lspace (cell $labell60 $l60)))
    ) $l60)
)

(= (l61 $cov-matrice $lspace)
    (let* (
        ($labell60 (format-args l{}{} (6 0)))
        ($labell10 (format-args l{}{} (1 0)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labell61 (format-args l{}{} (6 1)))
        ($a6 (index-atom $cov-matrice 6))
        (($l60 $l10 $l11) (collapse(superpose((match $lspace (cell $labell60 $x) $x) (match $lspace (cell $labell10 $x) $x) (match $lspace (cell $labell11 $x) $x)))) )
        ($a61 (index-atom $a6 1))
        ($l61 (/ (- $a61 (* $l60 $l10)) $l11))
        ($add (add-atom $lspace (cell $labell61 $l61)))
    ) $l61)
)

(= (l62 $cov-matrice $lspace)
    (let* (
        ($labell22 (format-args l{}{} (2 2)))
        ($labell62 (format-args l{}{} (6 2)))
        ($a6 (index-atom $cov-matrice 6))
        ($l22 (match $lspace (cell $labell22 $x) $x))
        ($a62 (index-atom $a6 2))
        ($l62 (/ (- $a62 (sum (cells-product 6 2 $lspace))) $l22))
        ($add (add-atom $lspace (cell $labell62 $l62)))
    ) $l62)
)

(= (l63 $cov-matrice $lspace)
    (let* (
        ($labell33 (format-args l{}{} (3 3)))
        ($labell63 (format-args l{}{} (6 3)))
        ($a6 (index-atom $cov-matrice 6))
        ($l33 (match $lspace (cell $labell33 $x) $x))
        ($a63 (index-atom $a6 3))
        ($l63 (/ (- $a63 (sum (cells-product 6 3 $lspace))) $l33))
        ($add (add-atom $lspace (cell $labell63 $l63)))
    ) $l63)
)

(= (l64 $cov-matrice $lspace)
    (let* (
        ($labell44 (format-args l{}{} (4 4)))
        ($labell64 (format-args l{}{} (6 4)))
        ($a6 (index-atom $cov-matrice 6))
        ($l44 (match $lspace (cell $labell44 $x) $x))
        ($a64 (index-atom $a6 4))
        ($l64 (/ (- $a64 (sum (cells-product 6 4 $lspace))) $l44))
        ($add (add-atom $lspace (cell $labell64 $l64)))
    ) $l64)
)

(= (l65 $cov-matrice $lspace)
    (let* (
        ($labell55 (format-args l{}{} (5 5)))
        ($labell65 (format-args l{}{} (6 5)))
        ($a6 (index-atom $cov-matrice 6))
        ($l55 (match $lspace (cell $labell55 $x) $x))
        ($a65 (index-atom $a6 5))
        ($l65 (/ (- $a65 (sum (cells-product 6 5 $lspace))) $l55))
        ($add (add-atom $lspace (cell $labell65 $l65)))
    ) $l65)
)

(= (l66 $cov-matrice $lspace)
    (let* (
        ($labell66 (format-args l{}{} (6 6)))
        ($a6 (index-atom $cov-matrice 6))
        ($a66 (index-atom $a6 6))
        ($sum (sum (cells-product 6 6 $lspace)))
        ($l66 (sqrt-math (- $a66 $sum)))
        ($add (add-atom $lspace (cell $labell66 $l66)))
    ) $l66)
)

(= (l70 $cov-matrice $lspace)
    (let* (
        ($labell00 (format-args l{}{} (0 0)))
        ($labell70 (format-args l{}{} (7 0)))
        ($a7 (index-atom $cov-matrice 7))
        ($l00 (match $lspace (cell $labell00 $x) $x))
        ($a70 (index-atom $a7 0))
        ($l70 (/ $a70 $l00))
        ($add (add-atom $lspace (cell $labell70 $l70)))
    ) $l70)
)

(= (l71 $cov-matrice $lspace)
    (let* (
        ($labell70 (format-args l{}{} (7 0)))
        ($labell10 (format-args l{}{} (1 0)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labell71 (format-args l{}{} (7 1)))
        ($a7 (index-atom $cov-matrice 7))
        (($l70 $l10 $l11) (collapse(superpose((match $lspace (cell $labell70 $x) $x) (match $lspace (cell $labell10 $x) $x) (match $lspace (cell $labell11 $x) $x)))) )
        ($a71 (index-atom $a7 1))
        ($l71 (/ (- $a71 (* $l70 $l10)) $l11))
        ($add (add-atom $lspace (cell $labell71 $l71)))
    ) $l71)
)

(= (l72 $cov-matrice $lspace)
    (let* (
        ($labell22 (format-args l{}{} (2 2)))
        ($labell72 (format-args l{}{} (7 2)))
        ($a7 (index-atom $cov-matrice 7))
        ($l22 (match $lspace (cell $labell22 $x) $x))
        ($a72 (index-atom $a7 2))
        ($l72 (/ (- $a72 (sum (cells-product 7 2 $lspace))) $l22))
        ($add (add-atom $lspace (cell $labell72 $l72)))
    ) $l72)
)

(= (l73 $cov-matrice $lspace)
    (let* (
        ($labell33 (format-args l{}{} (3 3)))
        ($labell73 (format-args l{}{} (7 3)))
        ($a7 (index-atom $cov-matrice 7))
        ($l33 (match $lspace (cell $labell33 $x) $x))
        ($a73 (index-atom $a7 3))
        ($l73 (/ (- $a73 (sum (cells-product 7 3 $lspace))) $l33))
        ($add (add-atom $lspace (cell $labell73 $l73)))
    ) $l73)
)

(= (l74 $cov-matrice $lspace)
    (let* (
        ($labell44 (format-args l{}{} (4 4)))
        ($labell74 (format-args l{}{} (7 4)))
        ($a7 (index-atom $cov-matrice 7))
        ($l44 (match $lspace (cell $labell44 $x) $x))
        ($a74 (index-atom $a7 4))
        ($l74 (/ (- $a74 (sum (cells-product 7 4 $lspace))) $l44))
        ($add (add-atom $lspace (cell $labell74 $l74)))
    ) $l74)
)

(= (l75 $cov-matrice $lspace)
    (let* (
        ($labell55 (format-args l{}{} (5 5)))
        ($labell75 (format-args l{}{} (7 5)))
        ($a7 (index-atom $cov-matrice 7))
        ($l55 (match $lspace (cell $labell55 $x) $x))
        ($a75 (index-atom $a7 5))
        ($l75 (/ (- $a75 (sum (cells-product 7 5 $lspace))) $l55))
        ($add (add-atom $lspace (cell $labell75 $l75)))
    ) $l75)
)

(= (l76 $cov-matrice $lspace)
    (let* (
        ($labell66 (format-args l{}{} (6 6)))
        ($labell76 (format-args l{}{} (7 6)))
        ($a7 (index-atom $cov-matrice 7))
        ($l66 (match $lspace (cell $labell66 $x) $x))
        ($a76 (index-atom $a7 6))
        ($l76 (/ (- $a76 (sum (cells-product 7 6 $lspace))) $l66))
        ($add (add-atom $lspace (cell $labell76 $l76)))
    ) $l76)
)

(= (l77 $cov-matrice $lspace)
    (let* (
        ($labell77 (format-args l{}{} (7 7)))
        ($a7 (index-atom $cov-matrice 7))
        ($a77 (index-atom $a7 7))
        ($sum (sum (cells-product 7 7 $lspace)))
        ($l77 (sqrt-math (- $a77 $sum)))
        ($add (add-atom $lspace (cell $labell77 $l77)))
    ) $l77)
)

(= (chol-decomp $cov-matrice $lspace)
    (let ($rows $columns) (collapse(superpose((size-atom $cov-matrice) (let $row1 (index-atom $cov-matrice 0) (size-atom $row1)))))
    (collapse
        (superpose
            (
                (
                    if (>= (- $rows 1) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l00 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) 0 (empty)) (if (>= (- $columns 3) 0) 0 (empty)) (if (>= (- $columns 4) 0) 0 (empty)) (if (>= (- $columns 5) 0) 0 (empty)) (if (>= (- $columns 6) 0) 0 (empty)) (if (>= (- $columns 7) 0) 0 (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 2) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l10 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l11 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) 0 (empty)) (if (>= (- $columns 4) 0) 0 (empty)) (if (>= (- $columns 5) 0) 0 (empty)) (if (>= (- $columns 6) 0) 0 (empty)) (if (>= (- $columns 7) 0) 0 (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 3) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l20 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l21 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) (l22 $cov-matrice $lspace) (empty)) (if (>= (- $columns 4) 0) 0 (empty)) (if (>= (- $columns 5) 0) 0 (empty)) (if (>= (- $columns 6) 0) 0 (empty)) (if (>= (- $columns 7) 0) 0 (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 4) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l30 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l31 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) (l32 $cov-matrice $lspace) (empty)) (if (>= (- $columns 4) 0) (l33 $cov-matrice $lspace) (empty)) (if (>= (- $columns 5) 0) 0 (empty)) (if (>= (- $columns 6) 0) 0 (empty)) (if (>= (- $columns 7) 0) 0 (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 5) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l40 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l41 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) (l42 $cov-matrice $lspace) (empty)) (if (>= (- $columns 4) 0) (l43 $cov-matrice $lspace) (empty)) (if (>= (- $columns 5) 0) (l44 $cov-matrice $lspace) (empty)) (if (>= (- $columns 6) 0) 0 (empty)) (if (>= (- $columns 7) 0) 0 (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 6) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l50 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l51 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) (l52 $cov-matrice $lspace) (empty)) (if (>= (- $columns 4) 0) (l53 $cov-matrice $lspace) (empty)) (if (>= (- $columns 5) 0) (l54 $cov-matrice $lspace) (empty)) (if (>= (- $columns 6) 0) (l55 $cov-matrice $lspace) (empty)) (if (>= (- $columns 7) 0) 0 (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 7) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l60 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l61 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) (l62 $cov-matrice $lspace) (empty)) (if (>= (- $columns 4) 0) (l63 $cov-matrice $lspace) (empty)) (if (>= (- $columns 5) 0) (l64 $cov-matrice $lspace) (empty)) (if (>= (- $columns 6) 0) (l65 $cov-matrice $lspace) (empty)) (if (>= (- $columns 7) 0) (l66 $cov-matrice $lspace) (empty)) (if (>= (- $columns 8) 0) 0 (empty))
                            )
                        )
                    )
                    (empty)
                )
                (
                    if (>= (- $rows 8) 0)
                    (collapse
                        (superpose
                            (
                                (if (>= (- $columns 1) 0) (l70 $cov-matrice $lspace) (empty)) (if (>= (- $columns 2) 0) (l71 $cov-matrice $lspace) (empty)) (if (>= (- $columns 3) 0) (l72 $cov-matrice $lspace) (empty)) (if (>= (- $columns 4) 0) (l73 $cov-matrice $lspace) (empty)) (if (>= (- $columns 5) 0) (l74 $cov-matrice $lspace) (empty)) (if (>= (- $columns 6) 0) (l75 $cov-matrice $lspace) (empty)) (if (>= (- $columns 7) 0) (l76 $cov-matrice $lspace) (empty)) (if (>= (- $columns 8) 0) (l77 $cov-matrice $lspace) (empty))
                            )
                        )
                    )
                    (empty)
                )
            )
        )
    )
)
)

;!(chol-decomp ((1 0 1) (0 1 1) (0 0 1)) &self)

#####################done
(= (vec-inf-checker $vec)
(if (== $vec ()) (empty)
   (let* (($head (car-atom $vec))
          ($tail (cdr-atom $vec))
          ($res (isinf-math $head)))
          ($res1 (vec-inf-checker $tail))
          ($f (cons-atom $res $res1))
     (if $res True (vec-inf-checker $tail))
         
         )
    ))




;; --- Test Case ---

;!(isinf-math 1)
;!(vec-inf-checker (1 2 3))    ;; Returns [] (meaning no infinity found)
;!(vec-inf-checker (1 inf 3))  ;; Returns [True]


#######done
(= (vec-NaN-checker $vec)
(if (== $vec ()) ()
   (let* (($head (car-atom $vec))
          ($tail (cdr-atom $vec))
          ($res (isnan-math $head)))
          
     (if $res True (vec-NaN-checker $tail))))
)
;!(vec-NaN-checker (1 2 3))

######done
(= (Pos-definitness-checker $mat)
   (if (== $mat ())
       True  ;; Base case: All rows passed!
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ;; Collapse row checks. If row is clean, this is ().
              
              ($row-errors (collapse (superpose ((vec-NaN-checker $row) 
                                                 (vec-inf-checker $row))))))
         (if (== $row-errors ())
             (Pos-definitness-checker $rest) ;; Row clean, check the rest
             False                           ;; Issue found, stop and return False
         )
       )
   )
)

;; --- Test ---

;!(Pos-definitness-checker ((1 2 3)))

;!(==(()) (()))

(= (-ve $number)
    (- 0.0 $number)
)

(=(to-float $number)
    (- (+ $number 0.1) 0.1)
)

(= (div $num $denom)
    (/ (to-float $num) $denom)
)

##done
(= (m00 $lspace $mspace)
    (let* (
        ($label (format-args m{}{} (0 0)))
        ($l00 (match $lspace (cell $label $x) $x))
        ($lspace1 (collapse(get-atoms $lspace)))
        ($m00 (div 1 $l00))
        ($add (add-atom $mspace (cell $label $m00)))
    )
    $m00)
)


(= (m10 $lspace $mspace)
    (let* (
        ($labell10 (format-args l{}{} (1 0)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labelm10 (format-args m{}{} (1 0)))
        ($labelm00 (format-args m{}{} (0 0)))
        (($l10 $l11 $m00) (collapse(superpose((match $lspace (cell $labell10 $x) $x) (match $lspace (cell $labell11 $x) $x) (match $mspace (cell $labelm00 $x) $x)))))
        ($m10 (-ve (* $m00 (div $l10 $l11))))
        ($add (add-atom $mspace (cell $labelm10 $m10)))
    )
    $m10)
)


####done
(= (m11 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (1 1)))
        ($labelm (format-args m{}{} (1 1)))
        ($l11 (match $lspace (cell $labell $x) $x))
        ($m11 (div 1.0 $l11))
        ($add (add-atom $mspace (cell $labelm $m11)))
    )
    $m11)
)

####done
(= (m20 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (2 2)))
        ($labelm (format-args m{}{} (2 0)))
        ($l22 (match $lspace (cell $labell $x) $x))
        ($m20 (-ve (div (sum (inverse-cells-product 2 0 $lspace $mspace)) $l22)))
        ($add (add-atom $mspace (cell $labelm $m20)))
    )
    $m20)
)

##done
(= (m21 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (2 1)))
        ($labell11 (format-args l{}{} (1 1)))
        ($labell22 (format-args l{}{} (2 2)))
        ($labelm (format-args m{}{} (2 1)))
        (($l21 $l22 $l11) (collapse(superpose((match $lspace (cell $labell $x) $x) (match $lspace (cell $labell22 $x) $x) (match $lspace (cell $labell11 $x) $x)))))
        ; ($l21 (match $lspace (cell $labell $x) $x))
        ; ($l22 (match $lspace (cell $labell22 $x) $x))
        ; ($l11 (match $lspace (cell $labell11 $x) $x))
        ($m21 (-ve (div $l21 (* $l22 $l11))))
        ($add (add-atom $mspace (cell $labelm $m21)))
    )
    $m21)
)

#####done
(= (m22 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (2 2)))
        ($labelm (format-args m{}{} (2 2)))
        ($l22 (match $lspace (cell $labell $x) $x))
        ($m22 (div 1.0 $l22))
        ($add (add-atom $mspace (cell $labelm $m22)))
    )
    $m22)
)

####done
(= (m30 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (3 3)))
        ($labelm (format-args m{}{} (3 0)))
        ($l33 (match $lspace (cell $labell $x) $x))
        ($m30 (-ve (div (sum (inverse-cells-product 3 0 $lspace $mspace)) $l33)))
        ($add (add-atom $mspace (cell $labelm $m30)))
    )
    $m30)
)

####done
(= (m31 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (3 3)))
        ($labelm (format-args m{}{} (3 1)))
        ($l33 (match $lspace (cell $labell $x) $x))
        ($m31 (-ve (div (sum (inverse-cells-product 3 1 $lspace $mspace)) $l33)))
        ($add (add-atom $mspace (cell $labelm $m31)))
    )
    $m31)
)
###done
(= (m32 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (3 3)))
        ($labell22 (format-args l{}{} (2 2)))
        ($labell33 (format-args l{}{} (3 3)))
        ($labelm (format-args m{}{} (3 2)))
        (($l32 $l33 $l22) (collapse(superpose((match $lspace (cell $labell $x) $x) (match $lspace (cell $labell33 $x) $x) (match $lspace (cell $labell22 $x) $x)))))
        ; ($l32 (match $lspace (cell l32 $x) $x))
        ; ($l33 (match $lspace (cell l33 $x) $x))
        ; ($l22 (match $lspace (cell $labell22 $x) $x))
        ($m32 (-ve (div $l32 (* $l33 $l22))))
        ($add (add-atom $mspace (cell $labelm $m32)))
    )
    $m32)
)

#########done
(= (m33 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (3 3)))
        ($labelm (format-args m{}{} (3 3)))
        ($l33 (match $lspace (cell $labell $x) $x))
        ($m33 (div 1.0 $l33))
        ($add (add-atom $mspace (cell $labelm $m33)))
    )
    $m33)
)
#####done
(= (m40 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (4 4)))
        ($labelm (format-args m{}{} (4 0)))
        ($l44 (match $lspace (cell $labell $x) $x))
        ($m40 (-ve (div (sum (inverse-cells-product 4 0 $lspace $mspace)) $l44)))
        ($add (add-atom $mspace (cell $labelm $m40)))
    )
    $m40)
)

#####done
(= (m41 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (4 4)))
        ($labelm (format-args m{}{} (4 1)))
        ($l44 (match $lspace (cell $labell $x) $x))
        ($m41 (-ve (div (sum (inverse-cells-product 4 1 $lspace $mspace)) $l44)))
        ($add (add-atom $mspace (cell $labelm $m41)))
    )
    $m41)
)
##done
(= (m42 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (4 4)))
        ($labelm (format-args m{}{} (4 2)))
        ($l44 (match $lspace (cell $labell $x) $x))
        ($m42 (-ve (div (sum (inverse-cells-product 4 2 $lspace $mspace)) $l44)))
        ($add (add-atom $mspace (cell $labelm $m42)))
    )
    $m42)
)

(= (m43 $lspace $mspace)
    (let* (
        ($labell43 (format-args l{}{} (4 3)))
        ($labell44 (format-args l{}{} (4 4)))
        ($labell33 (format-args l{}{} (3 3)))
        ($labelm (format-args m{}{} (4 2)))
        ($labelm (format-args m{}{} (4 2)))
        (($l43 $l44 $l33) (collapse(superpose((match $lspace (cell $labell43 $x) $x) (match $lspace (cell $labell44 $x) $x) (match $lspace (cell $labell33 $x) $x)))))
        ($m43 (-ve (div $l43 (* $l44 $l33))))
        ($add (add-atom $mspace (cell m43 $m43)))
    )
    $m43)
)

###done
(= (m44 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (4 4)))
        ($labelm (format-args m{}{} (4 4)))
        ($l44 (match $lspace (cell $labell $x) $x))
        ($m44 (div 1.0 $l44))
        ($add (add-atom $mspace (cell $labelm $m44)))
    )
    $m44)
)

#done
(= (m50 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (5 5)))
        ($labelm (format-args m{}{} (5 0)))
        ($l55 (match $lspace (cell $labell $x) $x))
        ($m50 (-ve (div (sum (inverse-cells-product 5 0 $lspace $mspace)) $l55)))
        ($add (add-atom $mspace (cell $labelm $m50)))
    )
    $m50)
)

##done
(= (m51 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (5 5)))
        ($labelm (format-args m{}{} (5 1)))
        ($l55 (match $lspace (cell $labell $x) $x))
        ($m51 (-ve (div (sum (inverse-cells-product 5 1 $lspace $mspace)) $l55)))
        ($add (add-atom $mspace (cell $labelm $m51)))
    )
    $m51)
)

##done
(= (m52 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (5 5)))
        ($labelm (format-args m{}{} (5 2)))
        ($l55 (match $lspace (cell $labell $x) $x))
        ($m52 (-ve (div (sum (inverse-cells-product 5 2 $lspace $mspace)) $l55)))
        ($add (add-atom $mspace (cell $labelm $m52)))
    )
    $m52)
)

#done
(= (m53 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (5 5)))
        ($labelm (format-args m{}{} (5 3)))
        ($l55 (match $lspace (cell $labell $x) $x))
        ($m53 (-ve (div (sum (inverse-cells-product 5 3 $lspace $mspace)) $l55)))
        ($add (add-atom $mspace (cell $labelm $m53)))
    )
    $m53)
)

##done
(= (m54 $lspace $mspace)
    (let* (
        ($labell54 (format-args l{}{} (5 4)))
        ($labell55 (format-args l{}{} (5 5)))
        ($labell44 (format-args l{}{} (4 4)))
        ($labelm (format-args m{}{} (5 4)))
        (($l54 $l55 $l44) (collapse(superpose((match $lspace (cell $labell54 $x) $x) (match $lspace (cell $labell55 $x) $x) (match $lspace (cell $labell44 $x) $x)))))
        ($m54 (-ve (div $l54 (* $l55 $l44))))
        ($add (add-atom $mspace (cell $labelm $m54)))
    )
    $m54)
)

###done
(= (m55 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (5 5)))
        ($labelm (format-args m{}{} (5 5)))
        ($l55 (match $lspace (cell $labell $x) $x))
        ($m55 (div 1.0 $l55))
        ($add (add-atom $mspace (cell $labelm $m55)))
    )
    $m55)
)

###done
(= (m60 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (6 0)))
        ($l66 (match $lspace (cell $labell $x) $x))
        ($m60 (-ve (div (sum (inverse-cells-product 6 0 $lspace $mspace)) $l66)))
        ($add (add-atom $mspace (cell $labelm $m60)))
    )
    $m60)
)

(= (m61 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (6 1)))
        ($l66 (match $lspace (cell $labell $x) $x))
        ($m61 (-ve (div (sum (inverse-cells-product 6 1 $lspace $mspace)) $l66)))
        ($add (add-atom $mspace (cell $labelm $m61)))
    )
    $m61)
)

(= (m62 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (6 2)))
        ($l66 (match $lspace (cell $labell $x) $x))
        ($m62 (-ve (div (sum (inverse-cells-product 6 2 $lspace $mspace)) $l66)))
        ($add (add-atom $mspace (cell $labelm $m62)))
    )
    $m62)
)

(= (m63 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (6 3)))
        ($l66 (match $lspace (cell $labell $x) $x))
        ($m63 (-ve (div (sum (inverse-cells-product 6 3 $lspace $mspace)) $l66)))
        ($add (add-atom $mspace (cell $labelm $m63)))
    )
    $m63)
)

(= (m64 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (6 4)))
        ($l66 (match $lspace (cell $labell $x) $x))
        ($m64 (-ve (div (sum (inverse-cells-product 6 4 $lspace $mspace)) $l66)))
        ($add (add-atom $mspace (cell $labelm $m64)))
    )
    $m64)
)

(= (m65 $lspace $mspace)
    (let* (
        ($labell65 (format-args l{}{} (6 5)))
        ($labell66 (format-args l{}{} (6 6)))
        ($labell55 (format-args l{}{} (5 5)))
        ($labelm (format-args m{}{} (6 5)))
        (($l65 $l66 $l55) (collapse(superpose((match $lspace (cell $labell65 $x) $x) (match $lspace (cell $labell66 $x) $x) (match $lspace (cell $labell55 $x) $x)))))
        ($m65 (-ve (div $l65 (* $l66 $l55))))
        ($add (add-atom $mspace (cell $labelm $m65)))
    )
    $m65)
)

(= (m66 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (6 6)))
        ($l66 (match $lspace (cell $labell $x) $x))
        ($m66 (div 1.0 $l66))
        ($add (add-atom $mspace (cell $labelm $m66)))
    )
    $m66)
)

(= (m70 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 0)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m70 (-ve (div (sum (inverse-cells-product 7 0 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m70)))
    )
    $m70)
)

(= (m71 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 1)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m71 (-ve (div (sum (inverse-cells-product 7 1 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m71)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m71 (-ve (div (sum (inverse-cells-product 7 1 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m71)))
    )
    $m71)
)

(= (m72 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 2)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m72 (-ve (div (sum (inverse-cells-product 7 2 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m72)))
    )
    $m72)
)

(= (m73 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 3)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m73 (-ve (div (sum (inverse-cells-product 7 3 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m73)))
    )
    $m73)
)

(= (m74 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 4)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m74 (-ve (div (sum (inverse-cells-product 7 4 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m74)))
    )
    $m74)
)

(= (m75 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 5)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m75 (-ve (div (sum (inverse-cells-product 7 5 $lspace $mspace)) $l77)))
        ($add (add-atom $mspace (cell $labelm $m75)))
    )
    $m75)
)

(= (m76 $lspace $mspace)
    (let* (
        ($labell76 (format-args l{}{} (7 6)))
        ($labell77 (format-args l{}{} (7 7)))
        ($labell66 (format-args l{}{} (6 6)))
        ($labelm (format-args m{}{} (7 6)))
        (($l76 $l77 $l66) (collapse(superpose((match $lspace (cell $labell76 $x) $x) (match $lspace (cell $labell77 $x) $x) (match $lspace (cell $labell66 $x) $x)))))
        ($m76 (-ve (div $l76 (* $l77 $l66))))
        ($add (add-atom $mspace (cell $labelm $m76)))
    )
    $m76)
)

(= (m77 $lspace $mspace)
    (let* (
        ($labell (format-args l{}{} (7 7)))
        ($labelm (format-args m{}{} (7 7)))
        ($l77 (match $lspace (cell $labell $x) $x))
        ($m77 (div 1.0 $l77))
        ($add (add-atom $mspace (cell $labelm $m77)))
    )
    $m77)
)

#######done 
;; --- Helper: Generate columns for a specific row ---
(= (gen-inverse-cols $row-idx $num-cols $lspace $mspace)
   (if (== $num-cols 0)
       ()
       (let* (($col-idx (- $num-cols 1))
              ;; Dynamically create the function name: m00, m10, etc.
              ($func-name (format-args m{}{} ($row-idx $col-idx)))
              ;; Execute the function call
              ($val ($func-name $lspace $mspace))
              ($rest (gen-inverse-cols $row-idx $col-idx $lspace $mspace)))
         ;; We use append-like logic to keep columns in order (0 to N)
         (cons-atom $val $rest))))

;; --- Helper: Generate rows for the matrix ---
(= (gen-inverse-rows $num-rows $num-cols $lspace $mspace)
   (if (== $num-rows 0)
       ()
       (let* (($row-idx (- $num-rows 1))
              ($rest-rows (gen-inverse-rows $row-idx $num-cols $lspace $mspace))
              ($current-row (gen-inverse-cols $row-idx $num-cols $lspace $mspace)))
         (cons-atom $current-row $rest-rows))))

;; --- Inverse Wrapper ---
######done
(= (inverse-lmatrice $lmatrice $lspace $mspace)
   (let* (($add  (add-lmat-to-lspace $lmatrice $lspace))
          ($rows (size-atom $lmatrice))
          ($cols (size-atom (index-atom $lmatrice 0))))
     (gen-inverse-rows $rows $cols $lspace $mspace)))
###############################################################################

;; --- Setup and Test ---
!(bind! &space1 (new-space))
!(bind! &space2 (new-space))

;; Assuming m00, m01, m10, m11 are defined elsewhere
;!(inverse-lmatrice ((1 2) (3 4)) &space1 &space2)

; (L-Matrice:-> ((1 2) (3 4)))
; (add:-> (() (() ())))
; (L-Space-after-add:-> ((cell l00 1) (cell l10 3) (cell l11 4)))
; (Row:-> 2)
; (Row0:-> (1 2))
; ("Calculating m00")
; ("m00 =" 1.0 "l00 =" 1)
; ("Calculating m10")
; ("l10 =" 3 "l11 =" 4 "m00 =" 1.0)
; ("m10 =" -0.75)
; ("Calculating m11")
; [()]
; [()]
; [()]
; [((1.0 0) (-0.75 0.25))]


#########done
;; Helper 1: Gets the first element (head) of every row
(= (get-heads $mat)
   (if (== $mat ())
       ()
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ($head (get-heads $rest))
              ($val (car-atom $row))) ;; <-- Force evaluation here
         (cons-atom $val $head)       ;; <-- Pass the evaluated variable
       )
   )
)

;; Helper 2: Gets the remaining elements (tail) of every row
(= (get-tails $mat)
   (if (== $mat ())
       ()
       (let* (($row (car-atom $mat))
              ($rest (cdr-atom $mat))
              ($tail (get-tails $rest))
              ($val (cdr-atom $row))) ;; <-- Force evaluation here
         (cons-atom $val $tail)       ;; <-- Pass the evaluated variable
       )
   )
)

;; ########done
(= (transpose-matrice $mat)
   (if (== $mat ())
       ()
       (let $first-row (car-atom $mat)
         ;; If the first row is empty, we've extracted all columns, so we stop.
         (if (== $first-row ())
             ()
             (let* (
                ($head (get-heads $mat))
                ($tail (get-tails $mat))
                ($t (transpose-matrice $tail))
             ) 
             ;; Otherwise, build the new matrix: (Heads) + Transpose(Tails)
             (cons-atom $head $t)
             )
         )
       )
   )
)

;; --- Test Case ---
;!(transpose-matrice ((1 2 5)(1 2 5) (4 5 7)))

(= (C-inv-sqrt $matrice $clspace $ilspace $mspace)
    (transpose-matrice (inverse-lmatrice (chol-decomp $matrice $clspace) $ilspace $mspace))
)



;; 1. Helper: Generates a vector (row) of size $dim filled with gaussians
######done
(= (gen-gauss-row $dim)
   (if (<= $dim 0)
       ()
       (let* (
           ($gauss (gauss 1))
           ($res (gen-gauss-row (- $dim 1)))
       )
       (cons-atom $gauss $res))
       )
       )
       

;; 2. Main: Generates a matrix with $lambda_ rows
############done
(= (standard-normal $dim $lambda_)
   (if (<= $lambda_ 0)
       ()
       (let* (
       ($row (gen-gauss-row $dim))
       ($res (standard-normal $dim (- $lambda_ 1)))
       ) 
       (cons-atom $row $res))
       )
    )
       

;; --- Test ---
;!(standard-normal 3 1)
;; Example Output: ((-0.42 1.21 -0.15))

;!(standard-normal 2 3)
;; Example Output: ((0.1 -0.5) (1.2 0.8) (-0.3 2.1))

######done
;; 1. Helper: Dot product of two vectors
(= (dot-product $v1 $v2)
   (sum (vector-op $v1 $v2 *)))

;; 2. Helper: Dot product of one row against all columns (rows of transposed M2)
(= (row-times-matrix $row ()) ())
(= (row-times-matrix $row $m2-t)
   (let* (($col (car-atom $m2-t))
          ($rest-cols (cdr-atom $m2-t))
          ($dot (dot-product $row $col))
          ($res (row-times-matrix $row $rest-cols)))
     (cons-atom $dot $res)))

;####done
(= (mat-mat-mul $m1 $m2)
   (let* (($m1-row0 (index-atom $m1 0))
          ($m1-cols (size-atom $m1-row0))
          ($m2-rows (size-atom $m2)))
     (if (not (== $m1-cols $m2-rows))
         (Error ($m1-cols $m2-rows) DimensionMismatch)
         (let $m2-t (transpose-matrice $m2)
              (matrix-mul-recursive $m1 $m2-t)))))

;; Internal recursion to process M1 row by row
(= (matrix-mul-recursive () $m2-t) ())
(= (matrix-mul-recursive $m1 $m2-t)
   (let* (($row (car-atom $m1))
          ($rest-m1 (cdr-atom $m1))
          ($new-row (row-times-matrix $row $m2-t))
          ($res (matrix-mul-recursive $rest-m1 $m2-t))
          )
     (cons-atom $new-row $res)))

;; --- Test ---
;!(mat-mat-mul ((1 2)) ((3 4 5) (6 5 4)))
;!(mat-mat-mul ((1 2) (4 5)) ((3 4 5) (6 5 4)))



(= (random-multivariate $mean $cov-matrice $lambda_ $lspace)
    (let ($decomp-cov-matrice $standard-normals) (collapse(superpose((chol-decomp $cov-matrice $lspace) (standard-normal (size-atom $mean) $lambda_))))
        (let $transformed-standard-normals (mat-mat-mul $standard-normals (transpose-matrice $decomp-cov-matrice))
            (collapse
                (superpose
                    (
                        (if (>= (- $lambda_ 1) 0)
                        (let $trans-stand-norm0 (index-atom $transformed-standard-normals 0)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm0 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm0 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm0 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm0 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm0 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm0 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm0 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm0 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 2) 0)
                        (let $trans-stand-norm1 (index-atom $transformed-standard-normals 1)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm1 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm1 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm1 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm1 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm1 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm1 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm1 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm1 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 3) 0)
                        (let $trans-stand-norm2 (index-atom $transformed-standard-normals 2)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm2 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm2 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm2 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm2 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm2 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm2 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm2 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm2 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 4) 0)
                        (let $trans-stand-norm3 (index-atom $transformed-standard-normals 3)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm3 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm3 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm3 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm3 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm3 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm3 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm3 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm3 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 5) 0)
                        (let $trans-stand-norm4 (index-atom $transformed-standard-normals 4)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm4 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm4 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm4 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm4 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm4 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm4 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm4 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm4 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 6) 0)
                        (let $trans-stand-norm5 (index-atom $transformed-standard-normals 5)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm5 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm5 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm5 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm5 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm5 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm5 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm5 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm5 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 7) 0)
                        (let $trans-stand-norm6 (index-atom $transformed-standard-normals 6)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm6 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm6 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm6 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm6 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm6 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm6 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm6 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm6 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 8) 0)
                        (let $trans-stand-norm7 (index-atom $transformed-standard-normals 7)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm7 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm7 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm7 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm7 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm7 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm7 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm7 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm7 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 9) 0)
                        (let $trans-stand-norm8 (index-atom $transformed-standard-normals 8)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm8 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm8 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm8 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm8 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm8 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm8 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm8 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm8 7)))))
                        )
                        (empty))
                        (if (>= (- $lambda_ 10) 0)
                        (let $trans-stand-norm9 (index-atom $transformed-standard-normals 9)
                        (collapse(superpose(
                        (+ (index-atom $mean 0) (index-atom $trans-stand-norm9 0))
                        (+ (index-atom $mean 1) (index-atom $trans-stand-norm9 1))
                        (+ (index-atom $mean 2) (index-atom $trans-stand-norm9 2))
                        (+ (index-atom $mean 3) (index-atom $trans-stand-norm9 3))
                        (+ (index-atom $mean 4) (index-atom $trans-stand-norm9 4))
                        (+ (index-atom $mean 5) (index-atom $trans-stand-norm9 5))
                        (+ (index-atom $mean 6) (index-atom $trans-stand-norm9 6))
                        (+ (index-atom $mean 7) (index-atom $trans-stand-norm9 7)))))
                        )
                        (empty))
                    )
                )
            )
        )
    )
)

; !(random-multivariate (0 0) ((1 0) (0 1)) 5 &self)

; (: range (Number Number Number -> List))
(= (range $start $end $step)
    (if (> $start $end)
        ()
        (let*
            (
                ($next (range (+ $start $step) $end $step))
            )   
            (cons-atom $start $next)
        )
    )
)

;––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
; make-indices: 0-based indices for a list
(= (make-indices $lst) (range 0 (- (size-atom $lst) 1) 1))
; ! (make-indices (10 30 20))


; remove-index: remove the i-th element
(= (remove-index $lst $i)
   (if (== $i 0)
       (cdr-atom $lst)                       
       (let* (
               ($head (index-atom $lst 0))   
               ($tail (cdr-atom   $lst))    
               ($rest (remove-index $tail (- $i 1))) 
             )
         (cons-atom $head $rest)        
       )
   )
)
; ! (remove-index ((0 10) (1 30) (2 20)) 1)   ; [((0 10) (2 20))]

(= (vec-scale $c $v)
   (map-atom                                 
     $v $x
     (* $c $x))                              
)
; ! (vec-scale 0.5  (2 4 6))        ; Expected -> [(1 2 3)]

; (: vec-add (List List -> List))            
(= (vec-add $a $b)
   (if (== (size-atom $a) 0)                
       ()
       (let* (
               ($sum  (+ (index-atom $a 0)   
                          (index-atom $b 0)))
               ($tail (vec-add              
                         (cdr-atom $a)
                         (cdr-atom $b)))
             )
         (cons-atom $sum $tail)              
       )
   )
)

(= (cleaner-helper $list $index)
    (index-atom $list $index)
)

(= (cleaner $lists $index)
    (collapse
        (cleaner-helper (superpose $lists) $index)
    )
)

;!(cleaner (((5 4) 2)) 0)

(= (match-val-best-nd $val $best-nd)
    (let $obj (index-atom $best-nd 1) (if (== $val $obj) $best-nd (empty)))
)

(= (max-best-nd-helper $val $best-nds)
    (let $res (collapse
        (match-val-best-nd $val (superpose $best-nds))
    )
    (cleaner $res 0)
    )
)

(= (custom-union-atom $list1 $list2)
    (union-atom $list1 $list2)
)

(= (custom-unique-atom $list)
    (unique-atom $list)
)


#####done
(= (unionize () $acc) (custom-unique-atom $acc))
(= (unionize $list $acc)
   (let* (($ht (decons-atom $list))
          (($head $tail) $ht))
     (if (== (size-atom $head) 1)
         ;; If head is (x), treat x as an element
         (unionize $tail (cons-atom (car-atom $head) $acc))
         ;; If head is (x y ...), merge lists
         (unionize $tail (custom-union-atom $head $acc)))))

;; --- Test ---
;!(unionize ((1 2) (c a)) ())
;; Output: (a c 2 1) (order depends on your custom-union implementation)


(= (pair-index-fitness $inds $fits)
   (map-atom $inds $i
     ($i (index-atom $fits $i))
   )
)

#done
; find-max-helper: helper to find index of max fitness
(= (find-max-helper $pairs $i $max-idx $maxval)
   (if (== $i (size-atom $pairs))
       $max-idx
       (let*
         (
           ($pair (index-atom $pairs $i))   
           ($val  (index-atom $pair 1))     
         )
         (if (> $val $maxval)
             (find-max-helper $pairs (+ $i 1) $i $val)
             (find-max-helper $pairs (+ $i 1) $max-idx $maxval)
         )
       )
   )
)

#done
; max-index: find index of highest-fitness pair
(= (max-index $pairs)
   (let*
     (
       ($first (index-atom $pairs 0))
       ($start (index-atom $first 1))
     )
     (find-max-helper $pairs 1 0 $start)
   )
)

#done
; sort-pairs-desc
(= (sort-pairs-desc $pairs)
    (if (< (size-atom $pairs) 2)       
        $pairs                         
        (let* (
                ($idx        (max-index $pairs))
                ($maxPair    (index-atom $pairs $idx)) 
                ($rest       (remove-index $pairs $idx))  
                ($sorted-rest (sort-pairs-desc $rest))   
                )
            (cons-atom $maxPair $sorted-rest)           
        )
    )
)

#done
(= (extract-indices $pairs $mu)
    (
        if (or (== $mu 0) (== (size-atom $pairs) 0))
        ()
        (let*
            (
            ($first-pair (index-atom $pairs 0))
            ($idx         (index-atom $first-pair 0))
            ($rest        (remove-index $pairs 0))
            ($tail        (extract-indices $rest (- $mu 1)))
            )
            (cons-atom $idx $tail)
        )
    )
)


#done
(= (select-by-indices $samples $indices)
    (
        if (== (size-atom $indices) 0)
        ()
        (let* (
                ($first-i (index-atom $indices 0))
                ($item    (index-atom $samples $first-i))
                ($rest    (select-by-indices $samples (cdr-atom $indices)))
                )
            (cons-atom $item $rest)
        )
    )
)





;; --- Execution ---
!(bind! &lspace (new-space))
!(add-lmat-to-lspace ((10000000 2234 300000) (4432 675 612) (657 834 9234)) &lspace)
!(let $result (collapse (match &lspace $x $x)) $result)
;!(chol-decomp ((1 0 1) (0 1 1) (0 0 1)) &self)
;!(random-multivariate (0 0) ((1 0) (0 1)) 5 &self)



