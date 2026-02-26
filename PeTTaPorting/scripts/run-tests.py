import subprocess
import pathlib
import sys
import time
from tqdm import tqdm


# ANSI styling
RESET = "\033[0m"
BOLD = "\033[1m"
CYAN = "\033[96m"
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"

metta_run_command = "petta"
root = pathlib.Path(".")
test_files = list(root.rglob("tests/*-tests.metta"))
total_files = len(test_files)

total_failures = 0        # number of files with failures
total_passes = 0          # number of individual passing tests


def run_test_file(test_file):
    return subprocess.run(
        [metta_run_command, test_file.as_posix()],
        capture_output=True,
        text=True,
    )


def process_output(output, test_file):
    """
    Prints test comparisons.
    Stops processing further lines for THIS FILE on first ❌.
    Returns (file_passed, passes_in_file)
    """
    passes_in_file = 0

    for line in output.splitlines():
        stripped = line.strip()

        if not stripped:
            continue

        # Skip trailing Prolog 'true'
        if stripped == "true":
            continue

        if stripped.startswith("is "):
            if "❌" in stripped:
                print(f"{RED}{stripped}{RESET}")
                print(f"{RED}❌ Failure in file: {test_file.name}{RESET}")
                return False, passes_in_file
            else:
                print(f"{GREEN}{stripped}{RESET}")
                passes_in_file += 1
        else:
            print(f"{YELLOW}{stripped}{RESET}")

    return True, passes_in_file


# -----------------------------
# Start testing
# -----------------------------
print(f"\n{CYAN}{BOLD}{'═'*20} Running Tests {'═'*20}{RESET}\n")
start_time = time.time()

for idx, test_file in enumerate(tqdm(test_files, desc="🔍 Testing", unit="file")):

    print(f"\n{CYAN}{BOLD}File {idx + 1}/{total_files}:{RESET} {YELLOW}{test_file.name}{RESET}")
    print(f"{CYAN}{'-'*60}{RESET}")

    result = run_test_file(test_file)

    file_passed, passes_in_file = process_output(result.stdout, test_file)
    total_passes += passes_in_file

    if result.returncode != 0:
        file_passed = False
        if result.stderr.strip():
            print(f"{RED}{result.stderr.strip()}{RESET}")

    if not file_passed:
        total_failures += 1
        print(f"{RED}{'-'*60}{RESET}")
        print(f"{RED}Stopped remaining tests in {test_file.name}{RESET}")
        print(f"{RED}{'-'*60}{RESET}")

# -----------------------------
# Final Summary
# -----------------------------
duration = time.time() - start_time

print(f"\n{CYAN}{BOLD}{'═'*20} Test Summary {'═'*20}{RESET}")
print(f"{BOLD}📂 Total Files Tested: {RESET}{total_files}")
print(f"{GREEN}✅ Total Tests Passed: {total_passes}{RESET}")
print(f"{RED}❌ Files With Failures: {total_failures}{RESET}")
print(f"{YELLOW}⏱ Duration: {duration:.2f} seconds{RESET}")
print(f"{CYAN}{'═'*60}{RESET}")

# CI exit code
if total_failures > 0:
    print(f"{RED}🚨 Some test files failed.{RESET}")
    sys.exit(1)
else:
    print(f"{GREEN}🎉 All test files passed successfully!{RESET}")
