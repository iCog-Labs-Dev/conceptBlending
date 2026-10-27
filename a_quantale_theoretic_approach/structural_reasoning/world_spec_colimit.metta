; WorldSpec-level colimit helpers for integrated V-predicate colimits.
;
; Cluster format:
;   ((GenericWorld BlendedWorld (SourceWorldA SourceWorldB ...)) ...)
;
; The cluster is the deterministic many-to-many mapping form.  Every source
; world in a cluster rewrites to the same BlendedWorld, and the blended
; WorldSpec is built by merging the CASL-like sections of all source worlds.

(= (ws-name (WorldSpec $name $body))
   $name)

(= (ws-body (WorldSpec $name $body))
   $body)

(= (ws-placeholder-spec $world)
   (WorldSpec $world
      (independent-spec
         (sorts ())
         (ops ())
         (preds ())
         (axioms ()))))

(= (ws-list-member $item $items)
   (if (== $items ())
       False
       (let* (($head (car-atom $items))
              ($tail (cdr-atom $items)))
          (if (== $item $head)
              True
              (ws-list-member $item $tail)))))

(= (ws-normalize-section-tail $raw)
   (if (== (size-atom $raw) 1)
       (let $first (car-atom $raw)
          (if (== (get-metatype $first) Expression)
              $first
              $raw))
       $raw))

(= (ws-section-values-from-sections $sections $section-name)
   (if (== $sections ())
       ()
       (let* (($head (car-atom $sections))
              ($tail (cdr-atom $sections)))
          (if (== (car-atom $head) $section-name)
              (ws-normalize-section-tail (cdr-atom $head))
              (ws-section-values-from-sections $tail $section-name)))))

(= (ws-section-values $spec $section-name)
   (let* (($body (ws-body $spec))
          ($sections (cdr-atom $body)))
      (ws-section-values-from-sections $sections $section-name)))

(= (ws-find-spec $world $registry)
   (if (== $registry ())
       (ws-placeholder-spec $world)
       (let* (($head (car-atom $registry))
              ($tail (cdr-atom $registry)))
          (if (== (ws-name $head) $world)
              $head
              (ws-find-spec $world $tail)))))

(= (ws-merge-section-from-worlds $worlds $registry $section-name)
   (if (== $worlds ())
       ()
       (let* (($world (car-atom $worlds))
              ($remaining-worlds (cdr-atom $worlds))
              ($spec (ws-find-spec $world $registry))
              ($head-values (ws-section-values $spec $section-name))
              ($tail-values (ws-merge-section-from-worlds $remaining-worlds $registry $section-name)))
          (unique-atom (union-atom $head-values $tail-values)))))

(= (ws-cluster-generic-name $cluster)
   (index-atom $cluster 0))

(= (ws-cluster-blend-name $cluster)
   (index-atom $cluster 1))

(= (ws-cluster-source-worlds $cluster)
   (index-atom $cluster 2))

(= (ws-world-in-cluster $world $cluster)
   (ws-list-member $world (ws-cluster-source-worlds $cluster)))

(= (ws-colimit-world-spec $cluster $registry)
   (let* (($blend-world (ws-cluster-blend-name $cluster))
          ($source-worlds (ws-cluster-source-worlds $cluster))
          ($sorts (ws-merge-section-from-worlds $source-worlds $registry sorts))
          ($ops (ws-merge-section-from-worlds $source-worlds $registry ops))
          ($preds (ws-merge-section-from-worlds $source-worlds $registry preds))
          ($axioms (ws-merge-section-from-worlds $source-worlds $registry axioms)))
      (WorldSpec $blend-world
         (independent-spec
            (sorts $sorts)
            (ops $ops)
            (preds $preds)
            (axioms $axioms)))))

(= (ws-cluster-for-source-world $world $clusters)
   (if (== $clusters ())
       ()
       (let* (($head (car-atom $clusters))
              ($tail (cdr-atom $clusters)))
          (if (ws-world-in-cluster $world $head)
              $head
              (ws-cluster-for-source-world $world $tail)))))

(= (ws-cluster-for-blend-world $world $clusters)
   (if (== $clusters ())
       ()
       (let* (($head (car-atom $clusters))
              ($tail (cdr-atom $clusters)))
          (if (== $world (ws-cluster-blend-name $head))
              $head
              (ws-cluster-for-blend-world $world $tail)))))

(= (ws-rewrite-world $world $clusters)
   (let $cluster (ws-cluster-for-source-world $world $clusters)
      (if (== $cluster ())
          $world
          (ws-cluster-blend-name $cluster))))

(= (ws-rewrite-worlds $worlds $clusters)
   (if (== $worlds ())
       ()
       (let* (($head (car-atom $worlds))
              ($tail (cdr-atom $worlds))
              ($rewritten-head (ws-rewrite-world $head $clusters))
              ($rewritten-tail (ws-rewrite-worlds $tail $clusters)))
          (unique-atom (cons-atom $rewritten-head $rewritten-tail)))))

(= (ws-map-from-worlds $source-worlds $blend-world)
   (if (== $source-worlds ())
       ()
       (let* (($head (car-atom $source-worlds))
              ($tail (cdr-atom $source-worlds))
              ($tail-map (ws-map-from-worlds $tail $blend-world)))
          (cons-atom ($head $blend-world) $tail-map))))

(= (ws-world-colimit-map $clusters)
   (if (== $clusters ())
       ()
       (let* (($head (car-atom $clusters))
              ($tail (cdr-atom $clusters))
              ($blend-world (ws-cluster-blend-name $head))
              ($head-map (ws-map-from-worlds (ws-cluster-source-worlds $head) $blend-world))
              ($tail-map (ws-world-colimit-map $tail)))
          (union-atom $head-map $tail-map))))

(= (ws-spec-for-final-world $world $clusters $registry)
   (let $cluster (ws-cluster-for-blend-world $world $clusters)
      (if (== $cluster ())
          (ws-find-spec $world $registry)
          (ws-colimit-world-spec $cluster $registry))))

(= (ws-specs-for-worlds $worlds $clusters $registry)
   (if (== $worlds ())
       ()
       (let* (($head (car-atom $worlds))
              ($tail (cdr-atom $worlds))
              ($head-spec (ws-spec-for-final-world $head $clusters $registry))
              ($tail-specs (ws-specs-for-worlds $tail $clusters $registry)))
          (cons-atom $head-spec $tail-specs))))
