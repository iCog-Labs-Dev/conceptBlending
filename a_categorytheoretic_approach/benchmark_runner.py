import subprocess
import json
import re
import time

# Configuration
ROUNDS = 1  # How many times to run the experiment
SCRIPT = "master_pipeline.metta"

print(f"Starting Benchmark: {ROUNDS} Rounds...")
print("=" * 40)

total_latency = 0
success_count = 0
results = []

for i in range(1, ROUNDS + 1):
    print(f"Running Round {i}/{ROUNDS}...", end=" ", flush=True)
    
    # Run MeTTa
    start = time.time()
    try:
        # Run the command and capture output
        process = subprocess.run(
            ["metta", SCRIPT], 
            capture_output=True, 
            text=True
        )
        output = process.stdout
        
        # Check for the Performance Report in the output
        match = re.search(r'"Robustness_SVR":\s*"(\d+\.\d+)%"', output)
        
        if match and process.returncode == 0:
            print(" Success")
            success_count += 1
            
            # Extract Latency from the JSON in the output
            lat_match = re.search(r'"Total":\s*(\d+\.\d+)', output)
            if lat_match:
                latency = float(lat_match.group(1))
                total_latency += latency
                results.append(latency)
        else:
            print("Failed (Parse Error or Crash)")
            
    except Exception as e:
        print(f" System Error: {e}")

print("\n" + "=" * 40)
print("FINAL BENCHMARK RESULTS")
print("=" * 40)

# Calculate Aggregate Metrics
if ROUNDS > 0:
    agg_svr = (success_count / ROUNDS) * 100
    avg_latency = total_latency / success_count if success_count > 0 else 0
    
    print(f"Total Rounds:    {ROUNDS}")
    print(f"Successful Runs: {success_count}")
    print(f"Aggregate SVR:   {agg_svr:.2f}")
    print(f"Average Latency: {avg_latency:.4f}s")
    print("-" * 40)
    print(f"Latencies: {results}")