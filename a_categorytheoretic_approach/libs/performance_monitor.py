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
            "fidelity_score": 0   # Quality Metric
        }

    def start_pipeline(self):
        self.stats["start_time"] = time.time()
        
    def end_pipeline(self, quality_metrics=None):
        self.stats["end_time"] = time.time()
        if quality_metrics:
            self.stats["synergy_score"] = quality_metrics.get("Synergy", 0)
            self.stats["fidelity_score"] = quality_metrics.get("Fidelity", 0)
            
    def log_phase(self, phase_name, duration):
        self.stats["phases"][phase_name] = duration
    
    def log_llm_attempt(self, success=True):
        self.stats["llm_attempts"] += 1
        if not success:
            self.stats["llm_failures"] += 1
            
    def get_report(self):
        total_time = self.stats["end_time"] - self.stats["start_time"]
        
        # 1. Latency Description
        latency_report = self.stats["phases"]
        latency_report["Total"] = total_time
        
        # 2. Syntactic Validity Rate (Robustness)
        if self.stats["llm_attempts"] > 0:
            svr = (self.stats["llm_attempts"] - self.stats["llm_failures"]) / self.stats["llm_attempts"]
        else:
            svr = 1.0
            
        # 3. Cognitive ROI (Combining Performance and Quality Metrics)
        safe_time = max(total_time, 0.0001) 
        roi = (self.stats["synergy_score"] * self.stats["fidelity_score"]) / safe_time

        return {
            "Latency_Breakdown": latency_report,
            "Robustness_SVR": f"{svr:.2%}",
            "Cognitive_ROI": f"{roi:.4f}",
            "Raw_Stats": self.stats
        }
        
monitor = PerformanceMonitor()