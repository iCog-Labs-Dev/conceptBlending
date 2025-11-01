!(import! &self ../libs/agents/gpt_agents)

; !(test (gpt-network-selector Bat@Man) gpt-simplex)
; !(test (let $res (gpt-simplex Bat@Man (1 1 1 1 1 1 1 1)) (size-atom $res)) 4)
; !(test (let $res (gpt-single-scope Bat@Man (1 1 1 1 1 1 1 1)) (size-atom $res)) 4)
; !(test (let $res (gpt-double-scope Bat@Man (1 1 1 1 1 1 1 1)) (size-atom $res)) 4)
; !(test (let $res (gpt-mirror Bat@Man (1 1 1 1 1 1 1 1)) (size-atom $res)) 4)
; !(test (let $res (gpt-vector-extraction Bat Man (Topology Time Space)) (size-atom $res)) 2)
!(gpt-vector-extraction Bat Man (Topology Time Space))