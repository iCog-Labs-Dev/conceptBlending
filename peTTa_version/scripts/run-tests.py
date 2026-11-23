import os
import shutil
import subprocess
import pathlib
import sys
import time

try:
    from tqdm import tqdm  # type: ignore
except ImportError:
    def tqdm(iterable, **kwargs):
        return iterable

# Ensure agents library is importable for mock gating
agents_path = pathlib.Path(__file__).resolve().parent.parent / "libs" / "agents"
if agents_path.exists():
    sys.path.insert(0, str(agents_path))

try:
    from llm_agent import is_offline_mock_enabled
except ImportError:
    def is_offline_mock_enabled() -> bool:
        return (
            os.getenv("CI", "").strip().lower() in {"true", "1"}
            or os.getenv("GITHUB_ACTIONS", "").strip().lower() in {"true", "1"}
            or os.getenv("PETTA_OFFLINE_MOCK", "").strip().lower() in {"true", "1"}
        )


# ANSI styling
RESET = "\033[0m"
BOLD = "\033[1m"
CYAN = "\033[96m"
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"

metta_run_command = "petta"
root = pathlib.Path(".")
test_files = sorted(list(root.rglob("tests/*-tests.metta")))
total_files = len(test_files)

total_failures = 0        # number of files with failures
total_passes = 0          # number of individual passing tests
total_skipped = 0         # number of files skipped


def run_test_file(test_file):
    try:
        return subprocess.run(
            [metta_run_command, test_file.as_posix()],
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return None


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

petta_installed = shutil.which(metta_run_command) is not None

for idx, test_file in enumerate(tqdm(test_files, desc="🔍 Testing", unit="file")):

    print(f"\n{CYAN}{BOLD}File {idx + 1}/{total_files}:{RESET} {YELLOW}{test_file.name}{RESET}")
    print(f"{CYAN}{'-'*60}{RESET}")

    if not petta_installed:
        total_skipped += 1
        print(f"{YELLOW}⚠️  SKIP: {test_file.name} (PeTTa executable '{metta_run_command}' not found in PATH){RESET}")
        continue

    result = run_test_file(test_file)

    if result is None:
        total_skipped += 1
        print(f"{YELLOW}⚠️  SKIP: {test_file.name} (PeTTa executable '{metta_run_command}' not found){RESET}")
        continue

    if result.returncode != 0:
        stderr_text = result.stderr.strip()
        stdout_text = result.stdout.strip()
        combined = f"{stderr_text}\n{stdout_text}"

        # Check for missing API key / auth when mock is not enabled
        api_key = (os.getenv("OPENAI_API_KEY") or "").strip()
        has_api_key = bool(api_key and api_key not in {"YOUR_OPENAI_API_KEY_HERE", "None"})

        is_auth_skip = (
            ("AuthenticationError" in combined or "OPENAI_API_KEY" in combined)
            and not has_api_key
            and not is_offline_mock_enabled()
        )
        is_prereq_skip = (
            "swipl: not found" in combined
            or "error while loading shared libraries" in combined
        )

        if is_auth_skip:
            total_skipped += 1
            print(f"{YELLOW}⚠️  SKIP: {test_file.name} (OPENAI_API_KEY not configured and offline mock disabled){RESET}")
            continue
        elif is_prereq_skip:
            total_skipped += 1
            print(f"{YELLOW}⚠️  SKIP: {test_file.name} (SWI-Prolog / PeTTa prerequisite missing){RESET}")
            continue
        else:
            total_failures += 1
            print(f"{RED}❌ FAIL: {test_file.name}{RESET}")
            if stderr_text:
                print(f"{RED}{stderr_text}{RESET}")
            print(f"{RED}{'-'*60}{RESET}")
            print(f"{RED}Stopped remaining tests in {test_file.name}{RESET}")
            print(f"{RED}{'-'*60}{RESET}")
            continue

    file_passed, passes_in_file = process_output(result.stdout, test_file)
    total_passes += passes_in_file

    if file_passed:
        print(f"{GREEN}✅ PASS: {test_file.name}{RESET}")
    else:
        total_failures += 1
        print(f"{RED}❌ FAIL: {test_file.name}{RESET}")
        print(f"{RED}{'-'*60}{RESET}")
        print(f"{RED}Stopped remaining tests in {test_file.name}{RESET}")
        print(f"{RED}{'-'*60}{RESET}")

# -----------------------------
# Final Summary
# -----------------------------
duration = time.time() - start_time

print(f"\n{CYAN}{BOLD}{'═'*20} Test Summary {'═'*20}{RESET}")
print(f"{BOLD}📂 Total Files Tested:  {RESET}{total_files}")
print(f"{GREEN}✅ Total Tests Passed:  {total_passes}{RESET}")
print(f"{YELLOW}⚠️  Total Files Skipped: {total_skipped}{RESET}")
print(f"{RED}❌ Total Files Failed:  {total_failures}{RESET}")
print(f"{CYAN}⏱ Execution Duration: {duration:.2f} seconds{RESET}")
print(f"{CYAN}{'═'*60}{RESET}")

# Exit code semantics: Exit 0 if total_failures == 0 (even if some tests were skipped); exit 1 if total_failures > 0
if total_failures > 0:
    print(f"{RED}🚨 Some test files failed.{RESET}")
    sys.exit(1)
else:
    print(f"{GREEN}🎉 All test files completed successfully!{RESET}")
    sys.exit(0)
