import logging
import os
import shutil
import subprocess
from pathlib import Path

logger = logging.getLogger(__name__)


def get_nextflow_executable() -> str:
    nextflow_path: str | None = shutil.which("nextflow")
    if not bool(nextflow_path):
        raise Exception(
            'Could not find nextflow executable. Please provide the path to the executable with: "--nextflow_path"'
        )
    return nextflow_path


def baktflow_setup(
    setup_script: Path,
    setup_dir: Path,
    conda_dir: Path,
    database_dir: Path,
    conda_implementation: str,
    nextflow_path: str | None,
) -> None:
    """Run Nextflow setup script."""
    nextflow_path: str = get_nextflow_executable() if not nextflow_path else nextflow_path

    nextflow_cmd: str = (
        f"{nextflow_path} run {setup_script} -profile standard --cacheDir {conda_dir} --databaseDir {database_dir}"
    )
    if conda_implementation == "micromamba":
        nextflow_cmd += " --useMicromamba true"
    elif conda_implementation == "mamba":
        nextflow_cmd += " --useMamba true"

    nextflow_clean_cmd: str = f"{nextflow_path} clean -f -q"

    env = os.environ.copy()
    subprocess.run(nextflow_cmd, check=True, shell=True, cwd=str(setup_dir), env=env)
    subprocess.run(nextflow_clean_cmd, check=True, shell=True, cwd=str(setup_dir), env=env)
    shutil.rmtree(setup_dir.joinpath("work"), ignore_errors=True)


def run_baktflow_workflow(
    workflow_script: Path,
    input_tsv: Path,
    output_path: Path,
    conda_dir: Path,
    database_dir: Path,
    profile: str,
    conda_implementation: str,
    nextflow_path: str | None,
):
    """Run Nextflow workflow script."""

    nextflow_path: str = get_nextflow_executable() if not nextflow_path else nextflow_path

    nextflow_cmd = [
        nextflow_path,
        "run",
        str(workflow_script),
        "-profile",
        profile,
        "--inputTsv",
        str(input_tsv),
        "--output",
        str(output_path),
        "--cacheDir",
        str(conda_dir),
        "--databaseDir",
        str(database_dir),
    ]
    if conda_implementation == "micromamba":
        nextflow_cmd.extend(["--useMicromamba", "true"])
    elif conda_implementation == "mamba":
        nextflow_cmd.extend(["--useMamba", "true"])

    print(" ".join(nextflow_cmd))

    subprocess.run(nextflow_cmd, check=True, env=os.environ.copy())
    logger.info("Nextflow workflow executed successfully.")
