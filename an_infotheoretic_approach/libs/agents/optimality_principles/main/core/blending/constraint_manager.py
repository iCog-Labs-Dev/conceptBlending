from main.core.blending.constraints.integration import IntegrationConstraint
from main.core.blending.constraints.topology import TopologyConstraint
from main.core.blending.constraints.web import WebConstraint
from main.core.blending.constraints.unpacking import UnpackingConstraint
from main.core.blending.constraints.metonymy import MetonymyConstraint
from main.core.blending.constraints.good_reason import GoodReasonConstraint
from main.data_sources.conceptnet_adapter import ConceptNetAdapter
from main.data_sources.llm_integration import LLMIntegration

class ConstraintManager:
    def __init__(self, config: dict):
        cn_config = config.get("conceptnet", {})
        conceptnet = ConceptNetAdapter(cn_config.get("cache_enabled", True))

        llm = LLMIntegration(config.get("llm", {}))

        constraints_config = config.get("constraints", {})

        self.constraints = {
            "integration": IntegrationConstraint(conceptnet),
            "topology": TopologyConstraint(
                conceptnet, 
                cn_config.get("similarity_threshold", 0.65)
            ),
            "web": WebConstraint(constraints_config.get("web", {}), conceptnet),
            "unpacking": UnpackingConstraint(constraints_config.get("unpacking", {}), conceptnet),
            "metonymy": MetonymyConstraint(constraints_config.get("metonymy", {}), conceptnet),
            "good_reason": GoodReasonConstraint(
                constraints_config.get("good_reason", {}),
                conceptnet,
                llm
            )
        }

        self.weights = config["constraint_weights"]
        self.rejection_thresholds = config["rejection_thresholds"]

    def evaluate(self, blend: 'Concept', sources: tuple, cross_mappings: list) -> dict:
        source_a, source_b = sources
        scores = {}

        for name, constraint in self.constraints.items():
            if name == "topology":
                scores[name] = constraint.evaluate(blend, source_a, source_b)
            elif name == "web":
                scores[name] = constraint.evaluate(blend, cross_mappings)
            else:
                scores[name] = constraint.evaluate(blend)

        weighted_score = sum(
            scores[name] * self.weights.get(name, 0)
            for name in scores
        )

        is_rejected, reason = self._should_reject(scores, weighted_score)

        return {
            "raw_scores": scores,
            "weighted_score": weighted_score,
            "is_rejected": is_rejected,
            "rejection_reason": reason
        }

    def _should_reject(self, scores: dict, weighted_score: float) -> (bool, str):
        if weighted_score < self.rejection_thresholds["min_weighted_score"]:
            return True, f"Overall score too low ({weighted_score:.2f} < {self.rejection_thresholds['min_weighted_score']})"

        for constraint, min_val in self.rejection_thresholds["min_individual"].items():
            if constraint in scores and scores[constraint] < min_val:
                return True, f"{constraint} score too low ({scores[constraint]:.2f} < {min_val})"

        return False, ""
