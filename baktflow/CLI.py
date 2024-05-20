import argparse
import logging
import sys
import subprocess
from utils import check_file, convert_to_table_format, validate_tsv

logger = logging.getLogger(__name__)

def batch_subcommand(args):
    """Batch subcommand function."""
    logger.info("Running baktflow batch...")
    logger.info(f"Input samples file: {args.samples}")
    logger.info(f"Output directory: {args.output}")

    # Check file existence, readability, writability, and validate TSV
    try:
        if not check_existence(args.samples):
            raise FileNotFoundError(f"Input samples file {args.samples} does not exist")
        if not check_readability(args.samples):
            raise PermissionError(f"Input samples file {args.samples} is not readable")
        if not check_writability(args.output):
            raise PermissionError(f"Output directory {args.output} is not writable")
        
        
    # Validate TSV
    try:
        validate_tsv(args.input)
    except ValueError as e:
        logger.error(f"TSV validation failed: {e}")

      # Set default output directory if not provided
    if not args.output:
        args.output = '/default/output/directory'  # Change to the default directory

    # Create output directory if it doesn't exist
    create_directory(args.output)

   


        # Trigger main Nextflow workflow
        subprocess.run(f"nextflow main.nf --inputDir {args.samples} --outputDir {args.output}", shell=True)
    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
    except ValueError as e:
        logger.error(f"Error: {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")

def single_subcommand(args):
    """Single subcommand function."""
    logger.info("Running baktflow single...")
    logger.info(f"Analysis ID: {args.id}")
    logger.info(f"Analysis type: {args.type}")
    logger.info(f"Input file: {args.input}")
    logger.info(f"Output directory: {args.output}")

    # Check file existence, readability, and writability
    try:
        if not check_existence(args.input):
            raise FileNotFoundError(f"Input file {args.input} does not exist")
        if not check_readability(args.input):
            raise PermissionError(f"Input file {args.input} is not readable")
        if not check_writability(args.output):
            raise PermissionError(f"Output directory {args.output} is not writable")
    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
        return

    # Convert input file to table format
    try:
        table_data = convert_to_table_format([args.input], args.type)
        logger.info("Converted input to table format:")
        for file_name, file_type in table_data:
            logger.info(f"File: {file_name}, Type: {file_type}")
    except Exception as e:
        logger.error(f"Error converting input file to table format: {e}")
        return

    # Validate TSV
    try:
        validate_tsv(args.input)
    except ValueError as e:
        logger.error(f"TSV validation failed: {e}")

      # Set default output directory if not provided
    if not args.output:
        args.output = '/default/output/directory'  # Change to the default directory

    # Create output directory if it doesn't exist
    create_directory(args.output)



def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description='Bacterial WGS analysis suite.')
    subparsers = parser.add_subparsers(title='subcommands', dest='subcommand')

    # Setup subcommand
    setup_parser = subparsers.add_parser('setup', help='Setup baktflow pipeline')
    setup_parser.add_argument('directory', help='Home directory for the pipeline setup')
    setup_parser.add_argument('-c', '--config', help='Configuration file for setup parameters')

    # Batch subcommand
    batch_parser = subparsers.add_parser('batch', help='Run baktflow batch processing')
    batch_parser.add_argument('-s', '--samples', required=True, help='Input file for batch processing')
    batch_parser.add_argument('-o', '--output', default='/default/batch/output',
                              help='Output directory for batch results')

    # Single subcommand
    single_parser = subparsers.add_parser('single', help='Run baktflowsingle analysis')
    single_parser.add_argument('--id', required=True, help='ID for a specific single analysis')
    single_parser.add_argument('--type', required=True, choices=['illumina', 'long', 'assembly'],
                               help='Type of analysis')
    single_parser.add_argument('--input', required=True, help='Input file for single analysis')
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