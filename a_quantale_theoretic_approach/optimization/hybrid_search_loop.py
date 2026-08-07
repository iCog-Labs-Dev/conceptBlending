"""
Hybrid Evolutionary-Local Search for Conceptual Blending.

Implements Algorithm 1 from Goertzel (2026) Section 7.3.

The loop:
  - Global search: generate blend candidates via mutation/crossover of property TVs
  - Local refinement: apply McBride gradient steps to promising candidates
  - Peircean scoring: use habit memory to weight candidate quality
  - Selection: keep Pareto-optimal candidates across (emergence, coherence, Peircean quality)

Connects to:
  - McBrideOptimizer (optimization/macbride_derivative.py)
  - habit_memory/ (repo root) via HabitMemory interface
  - QuantaleConstraintManager (optimality/constraint_manager.py)
"""

from __future__ import annotations
import copy
import random
import warnings
from dataclasses import dataclass
from typing import Optional, List, Dict, Tuple

from a_quantale_theoretic_approach.core_representation.v_predicate import VPredicateConcept
from a_quantale_theoretic_approach.core_representation.product_quantale import ProductQuantale
from a_quantale_theoretic_approach.optimization.macbride_derivative import (
    McBrideOptimizer,
    emergence_tv,
    uniform_valuation,
)
from a_quantale_theoretic_approach.optimality.constraint_manager import (
    evaluate_quantale_optimality,
)
from a_quantale_theoretic_approach.structural_reasoning.quantale_colimit_engine import (
    QuantaleColimitResult,
)
from a_quantale_theoretic_approach.core_representation.world_spec import WorldSpecRegistry


@dataclass
class BlendCandidate:
    """A blend candidate with its multi-objective fitness scores."""
    blend: VPredicateConcept
    emergence: float = 0.0
    coherence: float = 0.0
    peircean_quality: float = 0.0
    optimality_score: float = 0.0
    generation: int = 0
    refined: bool = False

    @property
    def fitness_vector(self) -> Tuple[float, float, float]:
        return (self.emergence, self.coherence, self.peircean_quality)

    def dominates(self, other: "BlendCandidate") -> bool:
        """Pareto dominance: self is at least as good on all objectives."""
        sv = self.fitness_vector
        ov = other.fitness_vector
        return all(s >= o for s, o in zip(sv, ov)) and any(s > o for s, o in zip(sv, ov))


def _mutate_blend(
    blend: VPredicateConcept,
    mutation_rate: float = 0.2,
    mutation_scale: float = 0.1,
) -> VPredicateConcept:
    """Randomly perturb TV values of blend properties."""
    universe = blend.universal_set
    mutated = VPredicateConcept(blend.name, universal_set=universe)
    for prop_name, entry in blend.entries.items():
        tv = entry.quantale.tv.value
        if random.random() < mutation_rate:
            noise = random.gauss(0, mutation_scale)
            tv = max(0.01, min(0.99, tv + noise))
        new_q = ProductQuantale(entry.quantale.logic, type(entry.quantale.tv)(tv))
        mutated.add_property(
            prop_name,
            new_q,
            source=entry.source,
            extraction_method="mutation",
        )
    return mutated


def _crossover_blends(
    blend_a: VPredicateConcept,
    blend_b: VPredicateConcept,
) -> VPredicateConcept:
    """Uniform crossover: each property TV taken randomly from one parent."""
    universe = blend_a.universal_set
    child = VPredicateConcept(blend_a.name, universal_set=universe)
    all_props = set(blend_a.entries) | set(blend_b.entries)
    for prop_name in all_props:
        entry_a = blend_a.entries.get(prop_name)
        entry_b = blend_b.entries.get(prop_name)
        if entry_a is None:
            child.add_property(prop_name, entry_b.quantale)
        elif entry_b is None:
            child.add_property(prop_name, entry_a.quantale)
        else:
            chosen = entry_a if random.random() < 0.5 else entry_b
            child.add_property(prop_name, chosen.quantale)
    return child


class HybridSearchLoop:
    """
    Memetic search for high-quality conceptual blends.
    Global evolutionary search + local McBride gradient refinement.
    """

    def __init__(
        self,
        source_a: VPredicateConcept,
        source_b: VPredicateConcept,
        initial_blend: VPredicateConcept,
        population_size: int = 10,
        max_generations: int = 20,
        local_refinement_prob: float = 0.5,
        mcbride_steps: int = 10,
        mcbride_eta: float = 0.05,
        habit_scores: Optional[Dict[str, float]] = None,
    ):
        self.source_a = source_a
        self.source_b = source_b
        self.initial_blend = initial_blend
        self.population_size = population_size
        self.max_generations = max_generations
        self.local_refinement_prob = local_refinement_prob
        self.mcbride_steps = mcbride_steps
        self.mcbride_eta = mcbride_eta
        self.habit_scores = habit_scores or {}

        self.mcbride = McBrideOptimizer(
            source_a=source_a,
            source_b=source_b,
            eta=mcbride_eta,
            max_steps=mcbride_steps,
        )

    def _evaluate(self, candidate: BlendCandidate) -> None:
        """Score a candidate on all three fitness objectives."""
        self._score_emergence(candidate)
        self._score_coherence(candidate)
        self._score_peircean(candidate)

    def _score_emergence(self, candidate: BlendCandidate) -> None:
        candidate.emergence = emergence_tv(
            self.source_a, self.source_b, candidate.blend, uniform_valuation
        )

    def _score_coherence(self, candidate: BlendCandidate) -> None:
        try:
            registry = WorldSpecRegistry()
            if candidate.blend.universal_set:
                registry = registry.ensure_worlds(candidate.blend.universal_set)
            colimit = QuantaleColimitResult(
                blend=candidate.blend,
                world_specs=registry,
                property_maps={},
            )
            report = evaluate_quantale_optimality(
                self.source_a, self.source_b, colimit
            )
            if hasattr(report, 'scalar_score') and report.scalar_score is not None:
                candidate.coherence = float(report.scalar_score)
            elif hasattr(report, 'overall') and report.overall is not None:
                candidate.coherence = float(report.overall)
            else:
                candidate.coherence = candidate.emergence * 0.9
        except Exception as exc:
            warnings.warn(
                f"Optimality evaluation failed for '{candidate.blend.name}': {exc}. "
                f"Falling back to coherence proxy.",
                RuntimeWarning,
                stacklevel=2,
            )
            candidate.coherence = candidate.emergence * 0.9

    def _score_peircean(self, candidate: BlendCandidate) -> None:
        if not candidate.blend.entries:
            candidate.peircean_quality = 0.0
            return
        candidate.peircean_quality = sum(
            self.habit_scores.get(p, 0.5) * e.quantale.tv.value
            for p, e in candidate.blend.entries.items()
        ) / len(candidate.blend.entries)

    def _pareto_front(self, population: List[BlendCandidate]) -> List[BlendCandidate]:
        front = []
        for c in population:
            if not any(other.dominates(c) for other in population if other is not c):
                front.append(c)
        return front

    def run(self) -> List[BlendCandidate]:
        """Run the hybrid search. Returns the Pareto front of best blends."""
        population: List[BlendCandidate] = []
        seed = BlendCandidate(blend=copy.deepcopy(self.initial_blend), generation=0)
        self._evaluate(seed)
        population.append(seed)

        for _ in range(self.population_size - 1):
            candidate = BlendCandidate(blend=_mutate_blend(self.initial_blend), generation=0)
            self._evaluate(candidate)
            population.append(candidate)

        for generation in range(self.max_generations):
            for candidate in population:
                if not candidate.refined and random.random() < self.local_refinement_prob:
                    result = self.mcbride.refine(candidate.blend)
                    candidate.blend = result.refined_blend
                    candidate.refined = True
                    self._evaluate(candidate)

            offspring: List[BlendCandidate] = []
            front = self._pareto_front(population)
            pool = front if front else population
            for _ in range(self.population_size // 2):
                if len(pool) >= 2:
                    parents = random.sample(pool, 2)
                else:
                    parents = [pool[0], pool[0]]
                if len(parents) == 2 and parents[0] is not parents[1]:
                    child_blend = _crossover_blends(parents[0].blend, parents[1].blend)
                else:
                    child_blend = _mutate_blend(parents[0].blend)
                child_blend = _mutate_blend(child_blend, mutation_rate=0.1)
                child = BlendCandidate(blend=child_blend, generation=generation + 1)
                self._evaluate(child)
                offspring.append(child)

            combined = population + offspring
            population = self._pareto_front(combined)
            if len(population) > self.population_size:
                population.sort(key=lambda c: -c.emergence)
                population = population[:self.population_size]

        return self._pareto_front(population)
