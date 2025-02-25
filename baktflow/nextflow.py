import subprocess
import logging
import os

logger = logging.getLogger(__name__)
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"


def start(setup_script, config_file=None, nextflow_path=None):
    """Run the Nextflow setup script."""
    logger.info("Running Nextflow setup script...")
    
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
    
    nextflow_cmd = f"{nextflow_path} run {setup_script}"
    if config_file:
        nextflow_cmd += f" -c {config_file}"
    
    try:
        subprocess.run(nextflow_cmd, check=True, shell=True)
        logger.info("Nextflow setup script completed successfully.")
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
       
        '-profile', 'standard'
    ]

    try:
        # Execute the Nextflow command
        subprocess.run(nextflow_cmd, check=True)
        logger.info(f"{c_green}Nextflow pipeline executed successfully.{c_reset}")
    except subprocess.CalledProcessError as e:
        logger.error(f"{c_blue}Nextflow pipeline failed: {e}{c_reset}")
        raise


