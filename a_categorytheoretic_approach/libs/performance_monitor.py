import time
import json

class PerformanceMonitor:
    def __init__(self):
        self.stats = {
            "start_time": 0,
            "end_time": 0,
            "phases": {},         # Stores time per phase
            "llm_attempts": 0,    # Total calls to LLM
            "llm_failures": 0,    # Failed parses (SVR)
            "synergy_score": 0,   # Quality Metric
            "fidelity_score": 0   # From your Quality Metric
        }

