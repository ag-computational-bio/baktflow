#utils.py
import csv

import os
import sys
from pathlib import Path

def check_existence(path: str) -> bool:
    """Check if the path exists."""
    return os.path.exists(path)

def check_readability(path: str) -> bool:
    """Check if the path is readable."""
    return os.access(path, os.R_OK)

def check_writability(path: str) -> bool:
    """Check if the path is writable."""
    return os.access(path, os.W_OK)

def create_directory(output_path: str) -> None:
    """Create the output directory if it does not exist."""
    output_path = Path(output_path)
    if not output_path.exists():
        try:
            output_path.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            sys.exit(f'ERROR: could not resolve or create output directory ({output_path})!')



def convert_to_table_format(input_files, file_type):
    """Converts input files into a specific table format."""
    table_data = []
    for file_path in input_files:
        # Extract relevant information from the file path or content
        file_name = os.path.basename(file_path)
        table_data.append((file_name, file_type))
    return table_data



def validate_tsv(tsv_file):
    """Validate the TSV file format."""
    expected_headers = ['id', 'type', 'read1', 'read2', 'read3']
    with open(tsv_file, 'r') as file:
        reader = csv.DictReader(file, delimiter='\t')
        headers = reader.fieldnames
        if headers != expected_headers:
            raise ValueError(
                f"TSV file headers do not match expected format. Expected: {expected_headers}, Actual: {headers}")
        for row in reader:
            if not row['id'] or not row['type']:
                raise ValueError("ID or type is missing in the TSV file.")
            if row['type'] == 'illumina':
                if not row['read2'] or not row['read3']:
                    raise ValueError("For hybrid type, both read1 and read2 must be provided.")
            else:
                if not row['read1']:
                    raise ValueError("For non-hybrid types, a single read must be provided.")
