import argparse
import logging
import sys
from utils.py import validate_tsv

# Configure logging
logging.basicConfig(
    level=logging.INFO,  # Set the default logging level to INFO
    format='%(asctime)s - %(levelname)s - %(message)s',  # Define log message format
    datefmt='%Y-%m-%d %H:%M:%S',  # Define date/time format
    handlers=[
        logging.FileHandler('logfile.log'),  # Log to file
        logging.StreamHandler(sys.stdout)  # Log to console
    ]
)

# Create a logger object
logger = logging.getLogger(__name__)


def setup_subcommand(args):
    """Setup subcommand function."""
    logger.info("Running setup subcommand...")
    logger.info(f"Home directory: {args.directory}")
    if args.config:
        logger.info(f"Using config file: {args.config}")


def batch_subcommand(args):
    """Batch subcommand function."""
    logger.info("Running batch subcommand...")
    logger.info(f"Input samples file: {args.samples}")
    logger.info(f"Output directory: {args.output}")

    try:
        validate_tsv(args.samples)
        logger.info("TSV file is valid.")
    except ValueError as e:
        logger.error(f"Error: {e}")


def single_subcommand(args):
    """Single subcommand function."""
    logger.info("Running single subcommand...")
    logger.info(f"Analysis ID: {args.id}")
    logger.info(f"Analysis type: {args.type}")
    if args.type == 'illumina':
        logger.info(f"Illumina R1 file: {args.r1}")
        if args.r2:
            logger.info(f"Illumina R2 file: {args.r2}")
    else:
        logger.info(f"Read file: {args.read}")


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(
        description='Bacterial WGS analysis suite.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    subparsers = parser.add_subparsers(title='subcommands', dest='subcommand')

    # Setup subcommand
    setup_parser = subparsers.add_parser('setup', help='Setup the pipeline')
    setup_parser.add_argument('directory', help='Home directory for the pipeline setup')
    setup_parser.add_argument('-c', '--config', help='Configuration file for setup parameters')

    # Batch subcommand
    batch_parser = subparsers.add_parser('batch', help='Run batch processing')
    batch_parser.add_argument('-s', '--samples', required=True, help='Input file for batch processing')
    batch_parser.add_argument('-o', '--output', required=True, help='Output directory for batch results')

    # Single subcommand
    single_parser = subparsers.add_parser('single', help='Run single analysis')
    single_parser.add_argument('--id', required=True, help='ID for a specific single analysis')
    single_parser.add_argument('--type', required=True, choices=['illumina', 'long', 'assembly'],
                               help='Type of analysis')
    single_parser.add_argument('--r1', help='Path to the first read file for Illumina analysis')
    single_parser.add_argument('--r2', help='Path to the second read file for paired-end Illumina analysis')
    single_parser.add_argument('--read', help='Path to the read file for non-Illumina analysis')

    return parser.parse_args()


def main():
    """Main function."""
    args = parse_arguments()

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
