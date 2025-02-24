<<<<<<< HEAD
=======
# baktflow_python/nextflow.py
>>>>>>> 9f62023593e3838a9e934b903e777657b6481ccc
import subprocess
import logging
import os

logger = logging.getLogger(__name__)
<<<<<<< HEAD

def start(setup_script, config_file=None, nextflow_path=None):
    """Run the Nextflow setup script."""
    logger.info("Running Nextflow setup script...")
=======
logger = logging.getLogger(__name__)

# Define color codes
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"
def start(setup_script, setup_dir, conda_dir, database_dir, nextflow_path=None):
    """Run Nextflow setup script."""
>>>>>>> 9f62023593e3838a9e934b903e777657b6481ccc
    
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
    
<<<<<<< HEAD
    nextflow_cmd = f"{nextflow_path} run {setup_script}"
    if config_file:
        nextflow_cmd += f" -c {config_file}"
    
    try:
        subprocess.run(nextflow_cmd, check=True, shell=True)
        logger.info("Nextflow setup script completed successfully.")
=======
    # Construct the Nextflow command
    nextflow_cmd = f"{nextflow_path} run {setup_script} -profile standard"

    try:
        # Set up Conda and database directories
        env = os.environ.copy()
        env['CONDA_ENVS_PATH'] = str(conda_dir)
        env['DATABASE_DIR'] = str(database_dir)

        # Execute the Nextflow command
        subprocess.run(nextflow_cmd, check=True, shell=True, cwd=str(setup_dir), env=env)

        
>>>>>>> 9f62023593e3838a9e934b903e777657b6481ccc
    except subprocess.CalledProcessError as e:
        logger.error(f"Nextflow setup script failed: {e}")
        raise

<<<<<<< HEAD
def run(tsv_file, output_dir):
    """Run the Nextflow pipeline with the given TSV file and output directory."""
    logger.info("Running Nextflow pipeline...")
    nextflow_cmd = f"nextflow run main.nf --input {tsv_file} --output {output_dir}"
    try:
        subprocess.run(nextflow_cmd, check=True, shell=True)
        logger.info("Nextflow pipeline completed successfully.")
    except subprocess.CalledProcessError as e:
        logger.error(f"Nextflow pipeline failed: {e}")
        raise

def discard(output_dir):
    """Clean up the Nextflow run directory."""
    logger.info("Cleaning up Nextflow run directory...")
    nextflow_work_dir = os.path.join(output_dir, 'work')
    if os.path.exists(nextflow_work_dir):
        try:
            subprocess.run(f"rm -rf {nextflow_work_dir}", check=True, shell=True)
            logger.info("Nextflow run directory cleaned up successfully.")
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to clean up Nextflow run directory: {e}")
            raise
    else:
        logger.warning("Nextflow run directory does not exist. No cleanup needed.")
=======

>>>>>>> 9f62023593e3838a9e934b903e777657b6481ccc

