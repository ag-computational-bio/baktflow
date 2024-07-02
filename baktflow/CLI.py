import os
import argparse
import logging
import sys
import subprocess
from nextflow import start,run, discard
from utils import check_existence, check_readability, check_writability, determine_analysis_type,convert_to_table_format, validate_tsv, create_directory 
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

def setup_subcommand(args):
    """Setup baktflow pipeline."""
    logger.info("Setting up baktflow pipeline...")
    logger.info(f"Setup directory: {args.directory}")
    logger.info(f"Configuration file: {args.config}")



    # Determine the path to the Nextflow setup script dynamically
    script_dir = os.path.dirname(os.path.abspath(__file__))
    setup_script = os.path.join(script_dir, '..', 'nextflow', 'setup', 'setup.nf')

    # Ensure setup_script path is correct
    if not os.path.exists(setup_script):
        logger.error(f"Setup script not found at {setup_script}")
        return
    try:
        start(setup_script, args.config, args.nextflow_path)
    except subprocess.CalledProcessError as e:
        logger.error(f"Setup failed: {e}")


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



    logger.info("Executing Nextflow pipeline...")
    try:
        run(tsv_file, args.output)
    except Exception as e:
        logger.error(f"Failed to run Nextflow pipeline: {e}")
        return

    # Cleanup Nextflow run directory
    logger.info("Cleaning up Nextflow run directory...")
    try:
        discard(args.output)
    except Exception as e:
        logger.error(f"Failed to clean up Nextflow run directory: {e}")
        return



def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description='baktflow: ')
    subparsers = parser.add_subparsers(title='subcommands', dest='subcommand')

    # Setup subcommand
      
    setup_parser = subparsers.add_parser('setup', help='Setup baktflow pipeline')
    setup_parser.add_argument('directory', nargs='?', default=os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'nextflow', 'setup', 'setup.nf')),
                              help='Home directory for the pipeline setup')
    setup_parser.add_argument('-c', '--config', help='Configuration file for setup parameters')
    setup_parser.add_argument('--nextflow_path', default=None, help='Path to Nextflow installation')

  

    # Batch subcommand
    batch_parser = subparsers.add_parser('batch', help='Run baktflow batch processing')
    batch_parser.add_argument('-s', '--samples', required=True, help='Input file for batch processing')
    batch_parser.add_argument('-o', '--output', default='/default/batch/output',
                              help='Output directory for batch results')

    # Single subcommand
    single_parser = subparsers.add_parser('single', help='Run baktflow single analysis')
    single_parser.add_argument('--id', required=True, help='ID for a specific single analysis')
    single_parser.add_argument('--input', required=True, nargs='+', help='Input file(s) for single analysis')
    single_parser.add_argument('--output', default='/default/single/output',
                               help='Output directory for single analysis')

    return parser.parse_args()

def main():
    """Main function."""
    args = parse_arguments()

    # Perform the selected subcommand
    if args.subcommand == 'setup':
        setup_subcommand(args)
    elif args.subcommand == 'batch':
        batch_subcommand(args)
    elif args.subcommand == 'single':
        single_subcommand(args)
    else:
        logger.error("No subcommand provided. Use --help for usage information.")

if __name__ == "__main__":
    main()
