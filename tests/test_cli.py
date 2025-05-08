import subprocess
import os

def test_cli():
    output_file = "test_fire.metta"
    env = os.environ.copy()
    env["PYTHONPATH"] = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    result = subprocess.run(
        ['python', 'run_cli.py', 'fire', '--output', output_file],
        capture_output=True, text=True, env=env
    )

    print("STDOUT:", result.stdout)
    print("STDERR:", result.stderr)

    assert "ConceptNet knowledge for 'fire' saved" in result.stdout
    assert os.path.exists(output_file)

    with open(output_file, "r") as f:
        content = f.read()
        assert "(causes lighting a match fire)" in content
        assert "(capableof fire burn things)" in content

    os.remove(output_file)

def test_cli_png_export():
    export_path = "test_fire_graph.png"
    env = os.environ.copy()
    env["PYTHONPATH"] = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    result = subprocess.run(
        ['python', 'run_cli.py', 'fire', '--visualize', '--export', export_path],
        capture_output=True, text=True, env=env
    )

    print("PNG Export STDOUT:", result.stdout)
    print("PNG Export STDERR:", result.stderr)

    assert os.path.exists(export_path)
    assert os.path.getsize(export_path) > 0

    os.remove(export_path)


