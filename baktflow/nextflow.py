import subprocess
import logging
import os
import shutil
from pathlib import Path

logger = logging.getLogger(__name__)
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"


def baktflow_setup(setup_script: Path, setup_dir: Path, conda_dir: Path, database_dir: Path, conda_implementation: str, nextflow_path: str | None):
    """Run Nextflow setup script."""
    if nextflow_path is None:
        nextflow_path = shutil.which('nextflow')
        if not bool(nextflow_path):
            raise 'Could not find nextflow executable. Please provide the path to the executable with: "--nextflow_path"'
    if not os.path.exists(nextflow_path):
        logger.error(f"Nextflow not found at {nextflow_path}. Please provide a valid path.")
        raise f'Could not find nextflow executable at {nextflow_path}. Please provide a valid path.'

    if not os.path.exists(setup_script):
        logger.error(f"Cannot find script file: {setup_script}")
        raise f'Could not find nextflow setup script at {setup_script}'
    
    nextflow_cmd: str = f"{nextflow_path} run {setup_script} -profile standard --cacheDir {conda_dir} --databaseDir {database_dir}"
    if conda_implementation == 'micromamba':
        nextflow_cmd += ' --useMicromamba true'
    elif conda_implementation == 'mamba':
        nextflow_cmd += ' --useMamba true'

    nextflow_clean_cmd: str = f"{nextflow_path} clean -f -q"

    try:
        env = os.environ.copy()
        subprocess.run(nextflow_cmd, check=True, shell=True, cwd=str(setup_dir), env=env)
        subprocess.run(nextflow_clean_cmd, check=True, shell=True, cwd=str(setup_dir), env=env)
        shutil.rmtree(setup_dir.joinpath('work'), ignore_errors=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"Nextflow setup script failed: {e}")
        raise e



def run(main, temp_tsv, sample_output_path, base_path,nextflow_path=None):
    """Run Nextflow pipeline script."""
    
    # Use a default nextflow_path if not provided
    if nextflow_path is None:
        nextflow_path = os.environ.get('NEXTFLOW_HOME', '')  # Environment variable for Nextflow path
    
    # Use an alternative default path if NEXTFLOW_HOME is not set
    if not nextflow_path:
        nextflow_path = os.path.expanduser("~/nextflow")  # Default path in user's home directory
    
    # Validate the nextflow_path
    if not os.path.exists(nextflow_path):
        logger.error(f"Nextflow not found at {nextflow_path}. Please provide a valid path.")
        return
    
    # Construct the Nextflow command
    nextflow_cmd = [
        nextflow_path, 'run', main,
        '--INPUT_TSV', temp_tsv,
        '--OUTPUT_DIR', sample_output_path,
        '--BASE_PATH', base_path,
       
        '-profile', 'standard'
    ]

    try:
        # Execute the Nextflow command
        subprocess.run(nextflow_cmd, check=True)
        logger.info(f"{c_green}Nextflow pipeline executed successfully.{c_reset}")
    except subprocess.CalledProcessError as e:
        logger.error(f"{c_blue}Nextflow pipeline failed: {e}{c_reset}")
        raise


