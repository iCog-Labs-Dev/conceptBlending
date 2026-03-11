!(import! &self "../libs/agents/gpt_agents.py")

!(test (py-call (gpt_agents.gpt_network_selector Bat@Man)) gpt_double_scope)
!(test (let $res (sread (py-call (gpt_agents.gpt_simplex david@teacher (1 1 1 1 1 1 1 1)))) (size-atom $res)) 4)
!(test (let $res (sread (py-call (gpt_agents.gpt_single_scope car@boat (1 1 1 1 1 1 1 1)))) (size-atom $res)) 4)
!(test (let $res (sread (py-call (gpt_agents.gpt_double_scope bat@man (1 1 1 1 1 1 1 1)))) (size-atom $res)) 4)
!(test (let $res (sread (py-call (gpt_agents.gpt_mirror sun@moon (1 1 1 1 1 1 1 1)))) (size-atom $res)) 4)
!(test (let $res (sread (py-call (gpt_agents.gpt_vector_extraction bat man (Topology Time Space)))) (size-atom $res)) 2)
