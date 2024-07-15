# baktflow_python/nextflow.py
import subprocess
import logging
import os

logger = logging.getLogger(__name__)
logger = logging.getLogger(__name__)

# Define color codes
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
    
    # Construct the Nextflow command
    nextflow_cmd = f"{nextflow_path} run {setup_script} -profile standard"

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



