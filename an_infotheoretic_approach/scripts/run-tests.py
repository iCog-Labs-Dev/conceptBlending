import subprocess
import pathlib
import sys
import time
from tqdm import tqdm


# ANSI escape codes for styling
RESET = "\033[0m"
BOLD = "\033[1m"
UNDERLINE = "\033[4m"
CYAN = "\033[96m"
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"

# Metta command
metta_run_command = "metta"
root = pathlib.Path(".")
test_files = list(root.rglob("tests/*-tests.metta"))
total_files = len(test_files)

results = []
failures = 0


def run_test_file(test_file):
    try:
        result = subprocess.run(
            [metta_run_command, test_file.as_posix()],
            capture_output=True,
            text=True,
            check=True,
        )
        return (result, test_file)
    except subprocess.CalledProcessError as e:
        return (f"Error running {test_file}:\n{e.stderr.strip()}", test_file)


def extract_and_print(result, path, idx):
    output = result.stdout if result.returncode == 0 else result.stderr
    extracted = output.replace("[()]\n", "").strip()
    has_error = "Error" in extracted

    if not has_error:
        extracted = "✅ Passed"

    color = RED if has_error else GREEN

    print(f"{YELLOW}{BOLD}Test {idx + 1}/{total_files}:{RESET} {CYAN}{path.name}{RESET}")
    print(f"{YELLOW}Exit Code: {RESET}{result.returncode}")
    print(f"{color}{extracted}{RESET}")
    print(f"{CYAN}{'-'*50}{RESET}")

    return has_error


# Start testing
print(f"\n{CYAN}{BOLD}{'═'*20} Running Tests {'═'*20}{RESET}\n")
start_time = time.time()

for test_file in tqdm(test_files, desc=f"{CYAN}🔍 Testing", unit="file", leave=True):
    result = run_test_file(test_file)
    results.append(result)

# Process results
print(f"\n{CYAN}{BOLD}{'═'*21} Test Results {'═'*21}{RESET}\n")

for idx, (result, path) in enumerate(results):
    if isinstance(result, str):
        print(f"{RED}{result}{RESET}")
        print(f"{CYAN}{'-'*50}{RESET}")
        failures += 1
        continue

    if extract_and_print(result, path, idx):
        failures += 1

# Final Summary
duration = time.time() - start_time
successes = total_files - failures

print(f"\n{CYAN}{BOLD}{'═'*20} Test Summary {'═'*20}{RESET}")
print(f"{BOLD}📂 Total Files Tested: {RESET}{total_files}")
print(f"{GREEN}✅ Passed: {successes}{RESET}")
print(f"{RED}❌ Failed: {failures}{RESET}")
print(f"{YELLOW}⏱  Duration: {duration:.2f} seconds{RESET}")
print(f"{CYAN}{'═'*60}{RESET}")

# Exit code for CI
if failures > 0:
    print(f"{RED}🚨 Tests failed. Exiting with code 1.{RESET}")
    sys.exit(1)
else:
    print(f"{GREEN}🎉 All tests passed successfully!{RESET}")
