import os
import argparse
import logging
from pathlib import Path
import argparse
import subprocess
from utils import check_existence, check_readability, check_writability, determine_analysis_type, convert_to_table_format, validate_tsv
from nextflow import start, run
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

     # Check if required databases exist
    required_databases = ['bakta_db']
    existing_databases = [db for db in required_databases if (database_dir / db).exists()]

    if existing_databases:
        response = input(f"{c_blue}The following databases already exist: {', '.join(existing_databases)}. Do you want to reinstall them? [Y/N]: ").strip().lower()
        if response == 'n':
            logger.info(f"{c_blue}Exiting setup.{c_reset}")
            return  # Exit the setup if the user declines

    # Check for Conda environments
    conda_patterns = {
        'fastqc': r'^fastqc-',
        'fastp': r'^fastp-',
        'bakta': r'^bakta-'
    }
    existing_conda_envs = {name for name, pattern in conda_patterns.items() if any(re.match(pattern, p.name) for p in conda_dir.iterdir() if p.is_dir())}

    if existing_conda_envs:
        response = input(f"{c_blue}The following Conda environments already exist: {', '.join(existing_conda_envs)}. Do you want to reinstall them? [Y/N]: ").strip().lower()
        if response == 'n':
            logger.info(f"{c_blue}Exiting setup.{c_reset}")
            return  # Exit the setup if the user declines

    # Proceed with the rest of the setup if needed
    logger.info(f"{c_green}Proceeding with the setup...{c_reset}")

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

    # Construct the TSV file path
    tsv_file = Path(args.input_dir) / 'input_files.tsv'

    # Get the list of input files as Path objects and filter only fastq/fq files
    input_files = [
        Path(args.input_dir) / f for f in os.listdir(args.input_dir)
        if (Path(args.input_dir) / f).is_file() and f.endswith(('.fastq', '.fq', '.fastq.gz', '.fq.gz'))
    ]
    
    logger.info(f"Found input files: {input_files}")
    if not input_files:
        logger.error("No valid FASTQ files found in the input directory.")
        return
     
    
    # Check file existence, readability, and writability
    try:
        for file_path in input_files:
            if not check_existence(file_path):
                raise FileNotFoundError(f"Input file {file_path} does not exist")
            if not check_readability(file_path):
                raise PermissionError(f"Input file {file_path} is not readable")
    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
        return

    # Create output directory if it doesn't exist
    output_path = Path(args.output)
    if not output_path.exists():
        output_path.mkdir(parents=True)
        logger.info(f"{c_green}Created directory: {output_path}{c_reset}")
    else:
        logger.info(f"{c_green}Directory already exists: {output_path}{c_reset}")
    # Create subdirectory for the sample ID
    sample_output_path = output_path / args.id
    if not sample_output_path.exists():
        sample_output_path.mkdir(parents=True)
        logger.info(f"{c_green}Created sample directory: {sample_output_path}{c_reset}")
    else:
        logger.info(f"{c_green}Sample directory already exists: {sample_output_path}{c_reset}")
    # Check if output directory is writable
    if not check_writability(args.output):
        logger.error(f"Output directory {args.output} is not writable")
        return

    # Determine analysis type
    try:
        analysis_type = determine_analysis_type(input_files)
        logger.info(f"Analysis type: {analysis_type}")
    except ValueError as e:
        logger.error(f"Error determining analysis type: {e}")
        return

    # Convert input files to table format
    try:
        tsv_file = convert_to_table_format(args.id, analysis_type, input_files, args.input_dir, args.output)
        logger.info(f"Converted input to table format and saved as: {tsv_file}")
    except Exception as e:
        logger.error(f"Error converting input files to table format: {e}")
        return

    # Validate TSV
    try:
        validate_tsv(tsv_file)
    except ValueError as e:
        logger.error(f"TSV validation failed: {e}")
        return

    # Path to Nextflow main script
    main_script = Path('nextflow', 'main.nf').resolve()

    # Run the Nextflow pipeline
    logger.info("Executing Nextflow pipeline...")
    try:
        run(main_script, tsv_file, sample_output_path, args.input_dir)
    except subprocess.CalledProcessError as e:
        logger.error(f"Nextflow pipeline failed: {e}")
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
    single_parser.add_argument('--input_dir', help='Input file(s) for single analysis')
    single_parser.add_argument('--id', help='ID for a specific single analysis')
    single_parser.add_argument('--output', help='Output directory for single analysis')

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