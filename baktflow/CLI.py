import os
import logging
from pathlib import Path
import argparse
import subprocess
import shutil

from baktflow.utils import (
    check_existence,
    check_writability,
    check_directory_accessibility,
    determine_sample_type,
    process_tsv,
    create_tsv,
    check_tsv_readability,
    get_baktflow_parent_dir
)
from baktflow.aggregated_report import find_json_reports, generate_html_report
from baktflow.nextflow import baktflow_setup, run


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# ---- Basic direcotries ----
base_dir: Path = Path(__file__).resolve()
root_dir: Path = Path(__file__).parent.parent.resolve()
nextflow_dir = root_dir.joinpath('nextflow_interface')

# ---- Subcommand: Setup ----
default_setup_dir = root_dir.joinpath('setup')
setup_script = nextflow_dir.joinpath('setup.nf')

# ---- Subcommand: Report ----
aggregated_report_script = root_dir.joinpath("baktflow", "aggregated_report.py")

# ---- Subcommand: Single ----
valid_extensions = ('.fastq', '.fq', '.fastq.gz', '.fq.gz', '.fasta', '.fa', '.fa.gz')
# ---- Paths for Subcommands (Single and Batch) ----
main_script = nextflow_dir.joinpath('main.nf')
base_path = base_dir.parent


def setup_subcommand(args, conda_implementation: str):
    """Setup Baktflow pipeline by managing Conda environments and databases"""
    logger.info("Setting up Baktflow pipeline...")
    logger.info(f"Setup directory: {args.directory}")

    setup_subdir =  Path(args.directory).resolve() if args.directory else default_setup_dir
    conda_dir = setup_subdir.joinpath('envs')
    database_dir = setup_subdir.joinpath('databases')

    for directory in [conda_dir, database_dir]:
        if not directory.exists():
            directory.mkdir(parents=True)
            logger.info(f"Created directory: {directory}")
    
    conda_files = [file.name for file in conda_dir.iterdir() if conda_dir.exists() and any(conda_dir.iterdir())]
    database_files = [file.name for file in database_dir.iterdir() if database_dir.exists() and any(database_dir.iterdir())]
    
    if not args.force and (conda_files or database_files):
        if conda_files:
            logger.info(f"Existing Conda Environments found: {', '.join(conda_files)}")
        if database_files:
            logger.info(f"Existing Databases found: {', '.join(database_files)}")

        response = input("Do you want to reinstall the environments and databases? ([r]einstall/[s]kip): ").strip().lower()
        if response == 'r' or response == 'reinstall':
            logger.info("Reinstalling all environments and databases...")
            shutil.rmtree(conda_dir, ignore_errors=True)
            conda_dir.mkdir(parents=True)
            shutil.rmtree(database_dir, ignore_errors=True)
            database_dir.mkdir(parents=True)

            try:
                baktflow_setup(setup_script, setup_subdir, conda_dir, database_dir, conda_implementation, nextflow_path=args.nextflow_path)
            except subprocess.CalledProcessError as e:
                logger.error(f"Nextflow setup failed: {e}")
                return
            logger.info("Reinstallation complete.")

        elif response == 's' or response == 'skip':
            logger.info("Skipping setup process.")
    else:
        if args.force:
            logger.info("Try forced reinstallation of all environments and databases...")
            shutil.rmtree(conda_dir, ignore_errors=True)
            conda_dir.mkdir(parents=True)
            shutil.rmtree(database_dir, ignore_errors=True)
            database_dir.mkdir(parents=True)
        else:
            logger.info("No existing environments or databases found. Installing from scratch...")
        try:
            baktflow_setup(setup_script, setup_subdir, conda_dir, database_dir, conda_implementation, nextflow_path=args.nextflow_path)
        except subprocess.CalledProcessError as e:
            logger.error(f"Nextflow setup failed: {e}")
            return


def single_subcommand(args):
    """Run baktflow single analysis."""
    logger.info("Running baktflow single...")
    logger.info(f"Analysis ID: {args.id}")

    logger.info(f"Output directory: {args.output}")

    if not args.id or not args.output:
        logger.error("Analysis ID and output directory are required.")
        return

    input_files = [f for f in [args.r1, args.r2, args.long, args.assembly] if f]
    if not input_files:
        logger.error("At least one input file must be provided.")
        return
    
    for file in input_files:
        if not file.endswith(valid_extensions):
            logger.error(f"Invalid file extension: {file}")
            return
        logger.info(f"Valid file detected: {file}")
    
    sample_type = determine_sample_type(args.r1, args.r2, args.long, args.assembly)
    # Check existence, readability, and writability of input files
    try:
        for file_path in input_files:
            path = Path(file_path)
            if not check_existence(path):
                raise FileNotFoundError(f"Input file {file_path} does not exist")

    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
        return

     # Output directory checks
    output = Path(args.output)   
    if not output.exists():
        try:
            output.mkdir(parents=True)  # Create the directory if it doesn't exist
            logger.info(f"Created output directory: {output}")
        except Exception as e:
            logger.error(f"Failed to create output directory {output}: {e}")
            return
    elif not check_writability(output):
        logger.error(f"The output directory {args.output} is not writable.")
        return
    else:
        logger.info(f"Output directory already exists: {output}")

    final_output_dir = output

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

    try:
        run(main_script, tsv_path, output,base_path)
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
    # Convert input arguments to Path objects for easier handling
    tsv_file = Path(args.input_tsv)
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output)

    # Validate the existence and accessibility of the TSV file
    if not check_tsv_readability(tsv_file):
        logger.error(f"The TSV file {args.input_tsv} does not exist or is not readable.")
        return

    # Validate the input directory
    if not check_existence(input_dir):
        logger.error(f"The input directory {args.input_dir} does not exist.")
        return
    if not check_directory_accessibility(input_dir):
        logger.error(f"The input directory {args.input_dir} is not readable.")
        return

      # Validate and create the output directory
    if not output_dir.exists():
        try:
            output_dir.mkdir(parents=True)  # Create the directory if it doesn't exist
            logger.info(f"Created output directory: {output_dir}")
        except Exception as e:
            logger.error(f"Failed to create output directory {output_dir}: {e}")
            return
    elif not check_writability(output_dir):
        logger.error(f"The output directory {args.output} is not writable.")
        return
    else:
        logger.info(f"Output directory already exists: {output_dir}")

    final_output_dir = output_dir

     # Process the TSV file and generate a temporary TSV file
    temp_tsv = process_tsv(args.input_tsv, args.input_dir)
    if temp_tsv is None:
        logger.error("Error processing TSV: Unable to generate temp TSV file. Aborting.")
        return
    
    temp_tsv = Path(temp_tsv)  
    temp_folder = temp_tsv.parent  

    logger.info(f"Temporary TSV file saved at {temp_tsv}")
 
    # Run the Nextflow pipeline
    try:
        run(
            main_script,
            temp_tsv,
            final_output_dir,
            args.input_dir
        )
        logger.info("Nextflow pipeline executed successfully.")
    except Exception as e:
        logger.error(f"Error executing Nextflow pipeline: {e}")
        return

    # Cleanup: Remove the temporary TSV file and its folder
    try:
        if temp_tsv.exists():
            temp_tsv.unlink()  # Delete the TSV file
            logger.info(f"Temporary TSV file {temp_tsv} deleted after execution.")

        if temp_folder.exists() and temp_folder.name == "temp": 
            shutil.rmtree(temp_folder) 
            logger.info(f"Temporary folder {temp_folder} removed successfully.")
    except Exception as e:
        logger.error(f"Error cleaning up temporary files: {e}")


def report_subcommand(input_dir, output_dir):
    logger = logging.getLogger(__name__)

    logger.info("Running baktflow batch...")
    logger.info(f"Input directory: {input_dir}")
    logger.info(f"Output directory: {output_dir}")

    if not os.path.exists(aggregated_report_script):
        logger.error(f"aggregated_report.py not found at {aggregated_report_script}")
        return

    logger.info(f"Running aggregated report from {input_dir} to {output_dir}...")

    try:
        subprocess.run(["python", aggregated_report_script, "--input_dir", input_dir, "--output_dir", output_dir], check=True)
        logger.info("Report generation completed successfully.")
    except subprocess.CalledProcessError as e:
        logger.error(f"Error while running report: {e}")

    # Load the sample reports
    sample_reports = find_json_reports(input_dir)

    # If no reports are found, log and exit
    if not sample_reports:
        logger.warning("No sample reports found!")
        return

    # Generate the report
    output_file = os.path.join(output_dir, "aggregated_report.html")
    generate_html_report(sample_reports, output_file)
       # Check if the report file was created successfully
    if os.path.exists(output_file):
        logger.info("Aggregated report created successfully!")
    else:
        logger.error("Failed to create aggregated report.")


def get_conda_implementation() -> str:
    if bool(shutil.which('micromamba')):
        return 'micromamba'
    elif bool(shutil.which('mamba')):
        return 'mamba'
    elif bool(shutil.which('conda')):
        return 'conda'
    else:
        raise 'No Conda, Mamba or Micromamba'


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description='baktflow: ')
    subparsers = parser.add_subparsers(title='subcommands', dest='subcommand')

    # Setup subcommand
    setup_parser = subparsers.add_parser('setup', help='Setup baktflow pipeline')
    setup_parser.add_argument('--directory', '-d', help='Home directory for the pipeline setup')
    setup_parser.add_argument('--nextflow_path', '-n', default=None, help='Path to Nextflow installation')
    setup_parser.add_argument('--force', '-f', default=False, action='store_true', help='Force the (re)installation setup of baktflow.')
    
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
    batch_parser.add_argument('--input_dir', help='Output directory for batch analysis', required=True)
    batch_parser.add_argument('--output', help='Output directory for batch analysis', required=True)
     
    # Subcommand for processing aggregated reports
    report_parser = subparsers.add_parser('report', help='Generate an aggregated report from output directory')
    report_parser.add_argument('--input_dir', required=True, help='Path to the input directory containing report files')
    report_parser.add_argument('--output_dir', required=True, help='Path to the output directory for the report')

    return parser.parse_args()


def main():
    args = parse_arguments()

    conda_implementation: str = get_conda_implementation()

    if args.subcommand == 'setup':
        setup_subcommand(args, conda_implementation)
    elif args.subcommand == 'single':
        single_subcommand(args)
    elif args.subcommand == 'batch':
        batch_subcommand(args)
    elif args.subcommand == 'report':
        # Pass all required arguments to report_subcommand
        report_subcommand(args.input_dir, args.output_dir)
    else:
        logger.error("No subcommand provided. Use --help for usage information.")

if __name__ == "__main__":
    main()
