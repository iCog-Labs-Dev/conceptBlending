import json
import re
from main.data_sources.conceptnet_adapter import ConceptNetAdapter
from main.data_sources.llm_integration import LLMIntegration
from main.core.representation.concept import Concept

class GoodReasonConstraint:
    def __init__(self, config: dict = None, conceptnet=None, llm=None):
        self.config = config or {}
        self.conceptnet = conceptnet or ConceptNetAdapter()
        self.llm = llm or LLMIntegration(self.config.get("llm", {}))
        self.prompt_template = self.config.get("prompt", self._default_prompt())
    
    def evaluate(self, blend: 'Concept') -> float:
        emergent = [p for p in blend.properties if not p.provenance]
        if not emergent:
            return 1.0
        justified = sum(1 for prop in emergent if self._is_justified(prop.name, blend))
        return justified / len(emergent)
    
    def _is_justified(self, property: str, blend: Concept) -> bool:
        if self._conceptnet_justification(property, blend):
            return True
        return self._llm_justification(property, blend)
    
    def _conceptnet_justification(self, property: str, blend: Concept) -> bool:
        if self.conceptnet.is_justified(property, blend.name):
            return True
        for source in self._get_provenance_sources(blend):
            if self.conceptnet.is_justified(property, source):
                return True
        return False
    
    def _llm_justification(self, property: str, blend: Concept) -> bool:
        context = self._blend_context(blend)
        prompt = self.prompt_template.format(
            property=property,
            blend=blend.name,
            context=context
        )
        response = self.llm.query(prompt)
        return self._parse_response(response)
    
    def _get_provenance_sources(self, blend: Concept) -> list:
        sources = set()
        for prop in blend.properties:
            sources.update(prop.provenance)
        return list(sources)
    
    def _blend_context(self, blend: Concept) -> str:
        props = ", ".join(p.name for p in blend.properties)
        rels = ", ".join(f"{r.type}→{r.target}" for r in blend.relations)
        sources = ", ".join(self._get_provenance_sources(blend))
        return (f"Properties: {props}\nRelations: {rels}\nSources: {sources}")
    
    def _parse_response(self, response: str) -> bool:
        try:
            if response.strip().startswith("{"):
                data = json.loads(response)
                if "justified" in data:
                    return data["justified"]
                elif all(k in data for k in ["scientific", "functional", "innovation", "commonsense"]):
                    return (data["scientific"] + data["functional"] + 
                            data["innovation"] + data["commonsense"]) >= 12  # Avg 3/5
        except json.JSONDecodeError:
            pass
        
        if re.search(r'\byes\b|\btrue\b|\bjustified\b', response, re.IGNORECASE):
            return True
        if re.search(r'\bno\b|\bfalse\b|\bnot justified\b', response, re.IGNORECASE):
            return False
            
        match = re.search(r"confidence:?\s*(\d+)%", response, re.IGNORECASE)
        if match:
            return int(match.group(1)) >= 70
            
        return False
    
    def _default_prompt(self):
        return (
            "Evaluate the property '{property}' in the blend concept '{blend}':\n"
            "{context}\n\n"
            "Please provide a JSON response with the following fields:\n"
            "- justified: boolean (true if the property is justified in the blend)\n"
            "- reason: a brief explanation supporting the justification\n\n"
            "Example response:\n"
            "{{\n"
            "  \"justified\": true,\n"
            "  \"reason\": \"The property logically follows from the combination of the source concepts.\"\n"
            "}}"
        )
