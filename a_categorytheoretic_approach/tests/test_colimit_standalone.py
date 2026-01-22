import sys
import os
import json

current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)

try:
    from libs.colimit import compute_colimit
    print(" Successfully imported compute_colimit.")
except ImportError as e:
    print(f" Import Error: {e}")
    sys.exit(1)

# Spec A: House (High priority for Wall, Low for Window)
spec_a = """
(Concept House
 (spec
  (sorts ((Wall 0.9) (Window 0.4) (Roof 0.8)))
  (ops (((: build Wall) 0.9) ((: open Window) 0.4)))
  (preds (((keeps_warm Wall) 0.85)))
  (axioms (((keeps_warm (build)) 0.85)))
 )
)
"""

# Spec B: Boat (Medium priority for Hull, High for Porthole)
spec_b = """
(Concept Boat
 (spec
  (sorts ((Hull 0.7) (Porthole 0.8) (Sail 0.6)))
  (ops (((: float Hull) 0.7) ((: open Porthole) 0.8)))
  (preds (((keeps_dry Hull) 0.8)))
  (axioms (((keeps_dry (float)) 0.8)))
 )
)
"""

# Spec G: Generic Container (Shared Structure)
spec_g = """
(Concept Generic
 (spec
  (sorts ((Boundary 0.5) (Aperture 0.5)))
  (ops (((: make Boundary) 0.5) ((: open Aperture) 0.5)))
  (preds (((protects Boundary) 0.5)))
  (axioms (((protects (make)) 0.5)))
 )
)
"""

# 3. DEFINE MAPPINGS
map_a = {
    "sorts": {"Boundary": "Wall", "Aperture": "Window"},
    "ops": {"make": "build", "open": "open"},
    "preds": {"protects": "keeps_warm"}
}

map_b = {
    "sorts": {"Boundary": "Hull", "Aperture": "Porthole"},
    "ops": {"make": "float", "open": "open"},
    "preds": {"protects": "keeps_dry"}
}

# 4. RUN THE TEST
print("\n TESTING WEIGHTED COLIMIT ENGINE...")
print("=" * 60)

try:
    result = compute_colimit(spec_a, spec_b, spec_g, map_a, map_b)
    
    print("RESULT GENERATED:\n")
    print(result)
    print("-" * 60)
    
    # 5. VERIFICATION LOGIC
    # Check 1: Unification Names
    if "Wall_Hull" in result:
        print(" SUCCESS: 'Wall' and 'Hull' unified to 'Wall_Hull'.")
    else:
        print(" FAILURE: Unification of Wall/Hull missed.")

    # Check 2: Priority Resolution (Max Logic)
    if "(Wall_Hull 0.9)" in result:
        print(" Priority Logic Works! (Wall 0.9 vs Hull 0.7 -> 0.9)")
    elif "(Wall_Hull 0.7)" in result:
        print(" FAILURE: Priority Logic Wrong. It picked the lower weight.")
    else:
        print(" WARNING: Could not find '(Wall_Hull 0.9)'. Check formatting.")

    metrics_found = True

    # I. Compression
    if "(compression " not in result:
        print("FAILURE: 'compression' metric missing.")
        metrics_found = False

    # II. InfoValue 
    if "(infoValue " not in result:
        print("FAILURE: 'infoValue' metric missing.")
        metrics_found = False

    # III. Imbalance
    if "(imbalance " not in result:
        print(" FAILURE: 'imbalance' metric missing.")
        metrics_found = False
    
    metrics_missing = []
    
    if "(compression " not in result: metrics_missing.append("compression")
    if "(infoValue " not in result: metrics_missing.append("infoValue")
    if "(imbalance " not in result: metrics_missing.append("imbalance")

    if not metrics_missing:
        print("SUCCESS: All 3 Metrics (Compression, InfoValue, Imbalance) found.")
    else:
        print(f"FAILURE: The following metrics are missing: {', '.join(metrics_missing)}")
except Exception as e:
    print(f"\n EXECUTION FAILED: {e}")
