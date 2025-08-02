; !(import! &self libs)
!(import! &self integration)
!(import! &self good-reason)
!(import! &self metonymy)
!(import! &self topology)
!(import! &self unpacking)
!(import! &self web)

(= (op-evaluater $blend)
    (let*
        (
            ($integration-res (integration-op $blend))
            ; ($good-reason-res (good-reason-op $blend))
            ; ($metonymy-res (metonymy-op $blend))
            ; ($topology-res (topology-op $blend $concept1 $concept2))
            ; ($unpacking-res (unpacking-op $blend))
            ; ($web-res (web-op $blend))
        )
        $integration-res
    )
)