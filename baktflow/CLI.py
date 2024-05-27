import argparse
import logging
import sys
import subprocess

from nextflow_runner import run_nextflow, discard_nextflow_run
from utils import check_existence, check_readability, check_writability, convert_to_table_format, validate_tsv, create_directory, determine_analysis_type

logger = logging.getLogger(__name__)

def batch_subcommand(args):
    """Batch subcommand function."""
    logger.info("Running baktflow batch...")
    logger.info(f"Input samples file: {args.samples}")
    logger.info(f"Output directory: {args.output}")

    # Read TSV file
    try:
        with open(args.samples, 'r') as f:
            reader = csv.DictReader(f, delimiter='\t')
            for row in reader:
                try:
                    # Extract analysis ID, type, and file paths
                    analysis_id = row['id']
                    analysis_type = row['type']
                    file_paths = [row[f] for f in ['file_1', 'file_2', 'file_3'] if row.get(f)]
                    
                    # Check existence, readability, and writability
                    for file_path in file_paths:
                        if not check_existence(file_path):
                            raise FileNotFoundError(f"Input file {file_path} does not exist")
                        if not check_readability(file_path):
                            raise PermissionError(f"Input file {file_path} is not readable")
                    if not check_writability(args.output):
                        raise PermissionError(f"Output directory {args.output} is not writable")
                    
                    # Convert input file to table format
                    tsv_file = convert_to_table_format(analysis_id, file_paths, analysis_type, args.output)
                    logger.info(f"Converted input to table format: {tsv_file}")
                    
                    # Validate TSV
                    validate_tsv(tsv_file)
                    
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
    except Exception as e:
        logger.error(f"Failed to read TSV file: {e}")

def single_subcommand(args):
    """Single subcommand function."""
    logger.info("Running baktflow single...")

    # Parse input provided by the user
    try:
        id_index = args.input.index('id-')
        analysis_id = args.input[:id_index].strip()
        file_info = args.input[id_index + 3:].strip().split(' ')
        if len(file_info) % 2 != 0:
            raise ValueError("Invalid input format. Please provide file paths in pairs.")
        file_pairs = [(file_info[i], file_info[i+1]) for i in range(0, len(file_info), 2)]
        input_files = [file[1] for file in file_pairs]
    except Exception as e:
        logger.error(f"Failed to parse input: {e}")
        return

    logger.info(f"Analysis ID: {analysis_id}")
    logger.info(f"Input file(s): {', '.join(input_files)}")

    # Determine analysis type based on file extensions
    try:
        analysis_type = determine_analysis_type(input_files)
        logger.info(f"Determined analysis type: {analysis_type}")
    except ValueError as e:
        logger.error(e)
        return



    

    # Check file existence, readability, and writability
    logger.info("Checking file existence, readability, and writability...")
    try:
        for file in input_files:
            if not check_existence(file):
                raise FileNotFoundError(f"Input file {file} does not exist")
            if not check_readability(file):
                raise PermissionError(f"Input file {file} is not readable")
        if not check_writability(args.output):
            raise PermissionError(f"Output directory {args.output} is not writable")
    except (FileNotFoundError, PermissionError) as e:
        logger.error(e)
        return

    # Convert input file to table format for single analysis
    logger.info("Converting input files to table format...")
    try:
        tsv_file = convert_to_table_format(analysis_id, input_files, analysis_type, args.output)
        logger.info(f"Converted input to table format: {tsv_file}")
    except Exception as e:
        logger.error(f"Error converting input file to table format: {e}")
        return

    # Validate TSV
    logger.info("Validating TSV...")
    try:
        validate_tsv(tsv_file)
    except ValueError as e:
        logger.error(f"TSV validation failed: {e}")
        return

    # Execute Nextflow main command with provided input, output, and type
    logger.info("Executing Nextflow pipeline...")
    try:
        run_nextflow(tsv_file, args.output)
    except Exception as e:
        logger.error(f"Failed to run Nextflow pipeline: {e}")
        return

    # Cleanup Nextflow run directory
    logger.info("Cleaning up Nextflow run directory...")
    try:
        discard_nextflow_run(args.output)
    except Exception as e:
        logger.error(f"Failed to clean up Nextflow run directory: {e}")
        return

      # Set default output directory if not provided
    if not args.output:
        args.output = '/default/output/directory'  # Change to the default directory

    # Create output directory if it doesn't exist
    create_directory(args.output)
    logger.info(f"Output directory: {args.output}")



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