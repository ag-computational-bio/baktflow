import os
import argparse
import logging
from pathlib import Path
import pandas as pd
import re
import argparse
import subprocess
import shutil
from utils import check_existence,check_directory_accessibility, check_writability, determine_sample_type,create_tsv,process_tsv,get_baktflow_parent_dir
from nextflow import start, run


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)
# Define color codes
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"

# Define the root setup directory for baktflow
default_setup_dir = Path('./setup').resolve()



def setup_subcommand(args):
    """Setup Baktflow pipeline by managing Conda environments and databases"""
    logger.info("Setting up Baktflow pipeline...")

    # Log user-provided directory and configuration file
    logger.info(f"Setup directory: {args.directory}")
    logger.info(f"Configuration file: {args.config}")

    # Define paths for Conda and database directories
    setup_subdir =  Path(args.directory).resolve() if args.directory else default_setup_dir
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

     # Ensure required directories exist; create them if they don't
    for directory in [conda_dir, database_dir]:
        if not directory.exists():
            directory.mkdir(parents=True)
            logger.info(f"Created directory: {directory}")
    
     # Check if any YAML configuration files exist in the Conda environments directory
        yaml_files_found = False
        for env_dir in conda_dir.iterdir():
            if env_dir.is_dir() and list(env_dir.glob('*.yaml')):  # Look for YAML files inside each Conda env folder
                yaml_files_found = True
                logger.info(f"Found YAML files in: {env_dir}")
    
    # List existing files in Conda and database directories
    conda_files = [file.name for file in conda_dir.iterdir() if conda_dir.exists() and any(conda_dir.iterdir())]
    database_files = [file.name for file in database_dir.iterdir() if database_dir.exists() and any(database_dir.iterdir())]
    
    
    if conda_files or database_files:
        # Log detected existing environments and databases
        logger.info("Existing files found:")
        if conda_files:
            logger.info(f"Conda Environments found: {', '.join(conda_files)}")
        if database_files:
            logger.info(f"Databases found: {', '.join(database_files)}")

        # Prompt user for action: reinstall, update, or skip setup
        response = input("Do you want to reinstall or update these environments and databases? [reinstall/update/skip]: ").strip().lower()

        if response == 'reinstall':
            # Reinstall: remove and recreate the directories
            logger.info("Reinstalling all environments and databases...")
            shutil.rmtree(conda_dir, ignore_errors=True)  # Delete existing Conda environments
            conda_dir.mkdir(parents=True)  # Recreate the directory

            shutil.rmtree(database_dir, ignore_errors=True)  # Delete existing database files
            database_dir.mkdir(parents=True)  # Recreate the directory
              # Run the Nextflow setup script to reinstall everything
            try:
                subprocess.run([
                    'nextflow', 'run', 'setup.nf', 
                    '--conda_dir', str(conda_dir), 
                    '--database_dir', str(database_dir)
                ], check=True)
            except subprocess.CalledProcessError as e:
                logger.error(f"Nextflow setup failed: {e}")
                return
            logger.info("Reinstallation complete.")

        elif response == 'update':
            # Update: Preserve YAML files and reinstall while keeping configurations
            logger.info("Updating environments and databases while preserving user configuration...")

            temp_dir = Path(setup_subdir, 'temp_configs')  # Temporary directory for storing YAML files
            temp_dir.mkdir(parents=True, exist_ok=True)
            preserved_configs = {}

            # Backup YAML configuration files before removal
            for env_dir in conda_dir.iterdir():
                if env_dir.is_dir():
                    for yaml_file in env_dir.glob('*.yaml'):
                        temp_file = temp_dir / yaml_file.name
                        shutil.copy(yaml_file, temp_file)  # Copy YAML file to temp directory
                        preserved_configs.setdefault(env_dir, []).append(temp_file)
                        logger.info(f"Preserved YAML file '{yaml_file.name}' from '{env_dir}' to '{temp_dir}'")

            # Remove old directories and reinstall everything
            shutil.rmtree(conda_dir, ignore_errors=True)
            shutil.rmtree(database_dir, ignore_errors=True)
            conda_dir.mkdir(parents=True)
            database_dir.mkdir(parents=True)

            try:
                subprocess.run([
                    'nextflow', 'run', 'setup.nf', 
                    '--conda_dir', str(conda_dir), 
                    '--database_dir', str(database_dir)
                ], check=True)
            except subprocess.CalledProcessError as e:
                logger.error(f"Nextflow setup failed: {e}")
                return

            # Restore preserved YAML files back to the respective environment directories
            for env_dir, yaml_files in preserved_configs.items():
                for temp_file in yaml_files:
                    shutil.copy(temp_file, env_dir / temp_file.name)
                    logger.info(f"Restored YAML file '{temp_file.name}' to '{env_dir}'")

            # Clean up temporary storage for YAML files
            shutil.rmtree(temp_dir)
            logger.info(f"Deleted temporary configuration files from '{temp_dir}'")

        elif response == 'skip':
            # Skip the setup process
            logger.info("Skipping setup process.")
    else:
        # No existing files found: Install everything from scratch
        logger.info("No existing environments or databases found. Installing from scratch...")

        try:
            subprocess.run([
                'nextflow', 'run', 'setup.nf', 
                '--conda_dir', str(conda_dir), 
                '--database_dir', str(database_dir)
            ], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"Nextflow setup failed: {e}")
            return


 
def single_subcommand(args):
    """Run baktflow single analysis."""
    logger.info("Running baktflow single...")
    logger.info(f"Analysis ID: {args.id}")
    logger.info(f"Input file(s): {args.input}")
    logger.info(f"Output directory: {args.output}")

    if not args.id or not args.output:
        logger.error("Analysis ID and output directory are required.")
        return

    input_files = [f for f in [args.r1, args.r2, args.long, args.assembly] if f]
    if not input_files:
        logger.error("At least one input file must be provided.")
        return

    valid_extensions = ('.fastq', '.fq', '.fastq.gz', '.fq.gz', '.fasta', '.fa', '.fa.gz')
    for file in input_files:
        if not file.endswith(valid_extensions):
            logger.error(f"Invalid file extension: {file}")
            return
    
    
    # Check existence, readability, and writability of input files
    try:
        for file_path in input_files:
            path = Path(file_path)
            if not check_existence(path):
                raise FileNotFoundError(f"Input file {file_path} does not exist")
            if not check_directory_accessibility(path):
                raise PermissionError(f"Input file {file_path} is not readable")
            if not check_writability(path):
                raise PermissionError(f"Input file {file_path} is not writable")
    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
        return

    output_path = Path(args.output)
    if not check_directory_accessibility(output_path):
        logger.error(f"The output directory {args.output} does not exist or is not accessible.")
        return
    if not check_writability(output_path):
        logger.error(f"The output directory {args.output} is not writable.")
        return
    
    sample_output_path = output_path / args.id
    sample_output_path.mkdir(parents=True, exist_ok=True)


    temp_tsv_path = get_baktflow_parent_dir() / 'temp'
    temp_tsv_path.mkdir(parents=True, exist_ok=True)
    logger.info(f"Temporary directory for TSV created: {temp_tsv_path}")

    sample_type = determine_sample_type(args.r1, args.r2, args.long, args.assembly)
    tsv_path = temp_tsv_path / 'temp_tsv.tsv'  

    try:
        create_tsv(args.id, args.r1, args.r2, args.long, args.assembly, sample_type, tsv_path)

        
        if not check_existence(tsv_path):
            logger.error(f"Failed to create the TSV file at: {tsv_path}")
            return
        logger.info(f"temp TSV file saved at: {tsv_path}")
    
    except Exception as e:
        logger.error(f"Error creating TSV: {e}")
        return

    base_path = Path(__file__).parent

    try:
        run(
            main=Path('nextflow', 'main.nf').resolve(),
            temp_tsv=tsv_path,
            sample_output_path=sample_output_path,
            base_path=base_path,
            nextflow_path=None  
        )
    except Exception as e:
        logger.error(f"Error running Nextflow pipeline: {e}")
    finally:
        # Remove temp folder after Nextflow finishes
        try:
            shutil.rmtree(temp_tsv_path)
            logger.info(f"Temporary directory {temp_tsv_path} removed successfully.")
        except Exception as e:
            logger.error(f"Failed to remove temporary directory {temp_tsv_path}: {e}")



def batch_subcommand(args):
    """Run baktflow batch analysis."""
    logger.info("Running baktflow batch...")
    logger.info(f"Input directory for TSV file: {args.input_tsv}")
    logger.info(f"Output directory: {args.output}")

    input_dir = Path(args.input_tsv)
    if not input_dir.is_dir():
        logger.error(f"The input path {args.input_tsv} is not a directory.")
        return

    tsv_file = None
    for file in os.listdir(input_dir):
        if file.endswith('.tsv'):
            tsv_file = input_dir / file
            break

    if tsv_file is None:
        logger.error("No TSV file found in the provided directory.")
        return

    logger.info(f"Found TSV file: {tsv_file}")

    try:
        df = pd.read_csv(tsv_file, sep='\t', header=None)
        logger.info("TSV file successfully read into DataFrame.")
    except Exception as e:
        logger.error(f"Error reading TSV file: {e}")
        return

    logger.info(f"DataFrame contents:\n{df}")

    main_script = Path('nextflow', 'main.nf').resolve()

    for index, row in df.iterrows():
        sample_id = row[0]
        files = []

        for col in row[2:]:
            split_files = col.split() if pd.notna(col) and col.strip() else []
            for file in split_files:
                if file:
                    files.append(input_dir / file.strip())

        sample_output_path = Path(args.output) / sample_id

        logger.info(f"Processing batch sample ID: {sample_id}")
        logger.info(f"Files to process: {files}")

        if not sample_output_path.exists():
            sample_output_path.mkdir(parents=True)
            logger.info(f"Created directory: {sample_output_path}")
        else:
            logger.info(f"Directory already exists: {sample_output_path}")

        if not check_writability(sample_output_path):
            logger.error(f"Output directory {sample_output_path} is not writable")
            continue

        try:
            for file_path in files:
                if not check_existence(file_path):
                    raise FileNotFoundError(f"Input file {file_path} does not exist")
                if not check_readability(file_path):
                    raise PermissionError(f"Input file {file_path} is not readable")
        except (FileNotFoundError, PermissionError) as e:
            logger.error(e)
            continue

        logger.info("Executing Nextflow pipeline...")
        try:
            run(main_script, str(tsv_file), str(sample_output_path), str(input_dir))
        except subprocess.CalledProcessError as e:
            logger.error(f"Nextflow pipeline failed: {e}")
            continue



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
    single_parser.add_argument('--r1', help='Input file for R1 sequencing reads (FASTQ format)', required=False)
    single_parser.add_argument('--r2', help='Input file for R2 sequencing reads (FASTQ format)', required=False)
    single_parser.add_argument('--long', help='Input file for long reads (FASTQ format)', required=False)
    single_parser.add_argument('--assembly', help='Input assembly file (FASTQ format)', required=False)
    single_parser.add_argument('--id', help='ID for a specific single analysis', required=True)
    single_parser.add_argument('--output', help='Output directory for single analysis', required=True)

    # Batch subcommand
    batch_parser = subparsers.add_parser('batch', help='Run baktflow batch analysis')
    batch_parser.add_argument('--input_tsv', help='Output directory for batch analysis', required=True)
    batch_parser.add_argument('--output', help='Output directory for batch analysis', required=True)

    return parser.parse_args()
def main():
    args = parse_arguments()

    if args.subcommand == 'setup':
        setup_subcommand(args)
    elif args.subcommand == 'single':
        single_subcommand(args)
    elif args.subcommand == 'batch':
        batch_subcommand(args)
    else:
        logger.error("No subcommand provided. Use --help for usage information.")

if __name__ == "__main__":
    main()