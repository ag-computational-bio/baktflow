import subprocess
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"


def start(setup_script, setup_dir, conda_dir, database_dir, nextflow_path=None):
    """Run Nextflow setup script."""
    
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
    
    root_path = Path(__file__).resolve().parent.parent 
            
    # Dynamically determine the path to the setup.nf script
    setup_script_path = os.path.join(root_path, 'nextflow', setup_script)  # Pointing to 'nextflow/setup.nf'
    
    if not os.path.exists(setup_script_path):
        logger.error(f"Cannot find script file: {setup_script_path}")
        return
    
    # Construct the Nextflow command
    nextflow_cmd = f"{nextflow_path} run {setup_script_path} -profile standard"

    try:
        # Set up Conda and database directories
        env = os.environ.copy()
        env['CONDA_ENVS_PATH'] = str(conda_dir)
        env['DATABASE_DIR'] = str(database_dir)

        # Execute the Nextflow command
        subprocess.run(nextflow_cmd, check=True, shell=True, cwd=str(setup_dir), env=env)
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Nextflow setup script failed: {e}")
        raise


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
        '-profile', 'standard',
        '-stub-run'
    ]

    try:
        # Execute the Nextflow command
        subprocess.run(nextflow_cmd, check=True)
        logger.info(f"{c_green}Nextflow pipeline executed successfully.{c_reset}")
    except subprocess.CalledProcessError as e:
        logger.error(f"{c_blue}Nextflow pipeline failed: {e}{c_reset}")
        raise


