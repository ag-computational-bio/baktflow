import os
import argparse
import logging
from pathlib import Path
import argparse
import subprocess
import shutil
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
    """Setup Baktflow pipeline."""
    logger.info("Setting up Baktflow pipeline...")

    # Log user-provided directory and configuration file
    logger.info(f"Setup directory: {args.directory}")
    logger.info(f"Configuration file: {args.config}")

    # Define paths for Conda and database directories
    setup_subdir = default_setup_dir
    conda_dir = setup_subdir / 'conda_envs'
    database_dir = setup_subdir / 'databases'

    if args.directory:
        user_dir = Path(args.directory).resolve()
        setup_subdir = user_dir / 'setup'
        conda_dir = setup_subdir / 'conda_envs'
        database_dir = setup_subdir / 'databases'

        if user_dir != default_setup_dir:
            response = input(f"Do you want to move the setup to {setup_subdir}? [Y/N]: ").strip().lower()
            if response == 'y':
                if setup_subdir.exists():
                    shutil.rmtree(setup_subdir)
                shutil.move(str(default_setup_dir), str(setup_subdir))
                logger.info(f"Moved setup directory to: {setup_subdir}")

    # Create the main directories if they don't exist
    for directory in [conda_dir, database_dir]:
        try:
            if not directory.exists():
                directory.mkdir(parents=True)
                logger.info(f"Created directory: {directory}")
        except OSError as e:
            logger.error(f"Failed to create directory {directory}: {e}")
            return  # Exit the setup if directory creation fails

    # Define patterns for Conda environments and databases
    conda_patterns = {
        'fastqc': r'^fastqc-',
        'fastp': r'^fastp-',
        # Add more patterns as needed
    }
    database_patterns = {
        'baktadb': r'^bakt-db-',
        # Add more patterns as needed
    }

    # Initialize flags for missing environments and databases
    environment_missing = False
    database_missing = False
    existing_envs = {}
    existing_dbs = {}

    # Check Conda environments
    for env_name, pattern in conda_patterns.items():
        env_dir = next((p for p in conda_dir.iterdir() if p.is_dir() and re.match(pattern, p.name)), None)
        if env_dir and any(env_dir.iterdir()):
            yaml_files = list(env_dir.glob('*.yaml'))
            if yaml_files:
                yaml_filenames = [yaml_file.name for yaml_file in yaml_files]
                logger.info(f"Environment '{env_name}' already exists and contains the following YAML files: {', '.join(yaml_filenames)}.")
                existing_envs[env_name] = {'env_dir': env_dir, 'yaml_files': yaml_files}
            else:
                logger.info(f"Environment '{env_name}' already exists but contains no YAML files.")
        else:
            logger.info(f"Environment '{env_name}' not found or is empty.")
            environment_missing = True

    # Check databases
    for db_name, pattern in database_patterns.items():
        db_dir = next((p for p in database_dir.iterdir() if p.is_dir() and re.match(pattern, p.name)), None)
        if db_dir:
            logger.info(f"Database '{db_name}' already exists.")
            existing_dbs[db_name] = db_dir
        else:
            logger.info(f"Database '{db_name}' not found.")
            database_missing = True

    # If any environment or database is missing, reinstall everything
    if environment_missing:
        logger.info("Some environments or databases are missing or empty. Reinstalling all environments and databases...")

        confirm = input(f"Are you sure you want to delete {conda_dir}? This will remove all environments. [y/N]: ").strip().lower()
        if confirm == 'y':
            if conda_dir.exists():
                shutil.rmtree(conda_dir)
            conda_dir.mkdir(parents=True)

        # Proceed with Nextflow setup
        setup_script = Path('nextflow', 'setup.nf').resolve()
        try:
            subprocess.run(['nextflow', 'run', str(setup_script), '-params-file', str(setup_subdir)], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"Nextflow setup failed: {e}")
            return

        logger.info("Reinstallation complete.")
    else:
        # If all environments and databases are present, ask whether to reinstall or update
        response = input("All environments and databases already exist. Do you want to:\n1. Reinstall everything\n2. Update existing environments\n3. Skip the setup\nPlease enter 'reinstall', 'update', or 'skip': ").strip().lower()
        
        if response == 'reinstall':
            logger.info("Reinstalling all environments and databases...")

            # Directly remove existing environments and databases
            confirm = input(f"Are you sure you want to delete {conda_dir} and {database_dir}? [y/N]: ").strip().lower()
            if confirm == 'y':
                if conda_dir.exists():
                    shutil.rmtree(conda_dir)
                if database_dir.exists():
                    shutil.rmtree(database_dir)
                conda_dir.mkdir(parents=True)
                database_dir.mkdir(parents=True)

                # Reinstall environments and databases via Nextflow setup
                setup_script = Path('nextflow', 'setup.nf').resolve()
                try:
                    subprocess.run(['nextflow', 'run', str(setup_script), '-params-file', str(setup_subdir)], check=True)
                except subprocess.CalledProcessError as e:
                    logger.error(f"Nextflow setup failed: {e}")
                    return

            logger.info("Reinstallation complete.")
 
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