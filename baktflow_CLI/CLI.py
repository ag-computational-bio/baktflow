#!/usr/bin/env python3

import argparse
import csv


def setup_subcommand(args):
    print("Running setup subcommand...")
    print(f"Home directory: {args.directory}")
    if args.config:
        print(f"Using config file: {args.config}")


def validate_tsv(tsv_file):
    # Define the expected headers for the TSV file
    expected_headers = ['column1', 'column2', 'column3']  # Update with your expected headers

    with open(tsv_file, 'r') as file:
        reader = csv.DictReader(file, delimiter='\t')
        headers = reader.fieldnames

        # Check if the headers match the expected format
        if headers != expected_headers:
            raise ValueError(
                f"TSV file headers do not match expected format. Expected: {expected_headers}, Actual: {headers}")

        # Validate each row
        for row in reader:
            # Perform validation checks on each row
            # Example: Check if required columns are present and have valid values
            if not row['column1'] or not row['column2']:
                raise ValueError("Required columns are missing or have invalid values.")
            # Add more validation checks as needed


def batch_subcommand(args):
    print("Running batch subcommand...")
    print(f"Input samples file: {args.samples}")
    print(f"Output directory: {args.output}")

    # Validate the provided TSV file
    try:
        validate_tsv(args.samples)
        print("TSV file is valid.")
    except ValueError as e:
        print(f"Error: {e}")
        # Handle the error, such as displaying a message to the user or exiting the script


def single_subcommand(args):
    print("Running single subcommand...")
    print(f"Analysis ID: {args.id}")
    print(f"Analysis type: {args.type}")
    if args.type == 'illumina':
        print(f"Illumina R1 file: {args.r1}")
        if args.r2:
            print(f"Illumina R2 file: {args.r2}")


def parse_arguments():
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

    return parser.parse_args()


def main():
    args = parse_arguments()

    if args.subcommand == 'setup':
        setup_subcommand(args)
    elif args.subcommand == 'batch':
        batch_subcommand(args)
    elif args.subcommand == 'single':
        single_subcommand(args)
    else:
        print("No subcommand provided. Use --help for usage information.")


if __name__ == "__main__":
    main()
