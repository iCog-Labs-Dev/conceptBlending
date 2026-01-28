!(import! &self libs)
!(import! &self kb:knowledge_base)
!(import! &self utils:extensions)

(= (find-generalization $specA $specB) 
   (llm:generate-gen $specA $specB)
)