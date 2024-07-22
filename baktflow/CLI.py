import os
import argparse
import logging
from pathlib import Path
import argparse
import subprocess
from baktflow.nextflow import start
import os

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)
# Define color codes
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"

# Define the root setup directory for baktflow
default_setup_dir = Path('./setup').resolve()

def setup_subcommand(args):
    """Setup baktflow pipeline."""
    logger.info(f"{c_reset}Setting up baktflow pipeline...{c_reset}")

    # Log user-provided directory and configuration file
    logger.info(f"{c_reset}Setup directory: {args.directory}{c_reset}")
    logger.info(f"{c_reset}Configuration file: {args.config}{c_reset}")

    # Create default setup directories if they don't exist
    setup_subdir = default_setup_dir
    if not setup_subdir.exists():
        setup_subdir.mkdir(parents=True)
        logger.info(f"{c_green}Created directory: {setup_subdir}{c_reset}")
    else:
        logger.info(f"{c_green}Directory already exists: {setup_subdir}{c_reset}")

    # Define paths for Conda and database directories
    conda_dir = setup_subdir / 'conda_envs'
    database_dir = setup_subdir / 'databases'

    if not conda_dir.exists():
        conda_dir.mkdir(parents=True)
        logger.info(f"{c_green}Created directory: {conda_dir}{c_reset}")
    else:
        logger.info(f"{c_green}Directory already exists: {conda_dir}{c_reset}")


    if not database_dir.exists():
        database_dir.mkdir(parents=True)
        logger.info(f"{c_green}Created directory: {database_dir}{c_reset}")
    else:
        logger.info(f"{c_green}Directory already exists: {database_dir}{c_reset}")

    # Check if the user provided a different directory
    if args.directory:
        user_dir = Path(args.directory).resolve()

        # If user provided directory is different, confirm moving setup
        if user_dir != default_setup_dir:
            response = input(f"Do you want to move the setup to {user_dir / 'setup'}? [Y/N]: ")
            if response.lower() == 'y':
                logger.info(f"{c_blue}Moving setup to specified directory: {user_dir / 'setup'}{c_reset}")
                setup_subdir.rename(user_dir / 'setup')
                logger.info(f"{c_green}Moved setup directory to: {user_dir / 'setup'}{c_reset}")
                setup_subdir = user_dir / 'setup'  # Update setup_subdir to user-pr
    # Path to the Nextflow script
    setup_script = Path('nextflow','setup.nf').resolve()


# Start Nextflow setup using the specified setup script and directory
    try:
        start(setup_script, setup_subdir, conda_dir, database_dir) 
    except subprocess.CalledProcessError as e:
        logger.error(f"Nextflow setup failed: {e}")

 
def single_subcommand(args):
    """Run baktflow single analysis."""
    logger.info("Running baktflow single...")
    logger.info(f"Analysis ID: {args.id}")
    logger.info(f"Input file(s): {args.input}")
    logger.info(f"Output directory: {args.output}")

    # Check file existence, readability, and writability
    try:
        for file_path in args.input:
            if not check_existence(file_path):
                raise FileNotFoundError(f"Input file {file_path} does not exist")
            if not check_readability(file_path):
                raise PermissionError(f"Input file {file_path} is not readable")
            if not check_writability(args.output):
                raise PermissionError(f"Output directory {args.output} is not writable")
    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
        return
    # Set default output directory if not provided
    if not args.output:
        args.output = '/default/output/directory'  # Change to the default directory

    # Create output directory if it doesn't exist
    create_directory(args.output)
        
    
     # Determine analysis type
    try:
        analysis_type = determine_analysis_type(args.input)
        logger.info(f"Analysis type: {analysis_type}")
    except ValueError as e:
        logger.error(f"Error determining analysis type: {e}")
        return

    # Convert input file to table format
    try:
        tsv_file = convert_to_table_format(args.id,analysis_type,args.input)
        logger.info(f"Converted input to table format and saved as: {tsv_file}")
    except Exception as e:
        logger.error(f"Error converting input file to table format: {e}")
        return

    # Validate TSV
    try:
        validate_tsv(tsv_file)
    except ValueError as e:
        logger.error(f"TSV validation failed: {e}")
        return





def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description='baktflow: ')
    subparsers = parser.add_subparsers(title='subcommands', dest='subcommand')

    # Setup subcommand
    setup_parser = subparsers.add_parser('setup', help='Setup baktflow pipeline')
    setup_parser.add_argument('--directory', help='Home directory for the pipeline setup')
    setup_parser.add_argument('-c', '--config', help='Configuration file for setup parameters')
    setup_parser.add_argument('--nextflow_path', default=None, help='Path to Nextflow installation')
    
    # Single subcommand
    single_parser = subparsers.add_parser('single', help='Run baktflow single analysis')
    single_parser.add_argument('--id', required=True, help='ID for a specific single analysis')
    single_parser.add_argument('--input', required=True, nargs='+', help='Input file(s) for single analysis')
    single_parser.add_argument('--output', default='/default/single/output',
                               help='Output directory for single analysis')

    return parser.parse_args()
def main():
    args = parse_arguments()

    if args.subcommand == 'setup':
        setup_subcommand(args)
    elif args.subcommand == 'single':
        single_subcommand(args)
    else:
        logger.error("No subcommand provided. Use --help for usage information.")

if __name__ == "__main__":
    main()