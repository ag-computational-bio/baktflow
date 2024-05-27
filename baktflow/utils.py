# utils.py
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

def determine_analysis_type(files):
    """
    Determine the type of sequencing analysis based on the file extensions and number of files.
    
    Args:
        files (list): List of input file paths.
        
    Returns:
        str: The inferred analysis type ('illumina', 'long', 'assembly', 'hybrid').
    """
    if len(files) == 1:
        if files[0].endswith(('.fastq', '.fq', '.fastq.gz', '.fq.gz')):
            return 'long'
        elif files[0].endswith(('.fasta', '.fa', '.fasta.gz', '.fa.gz')):
            return 'assembly'
        else:
            raise ValueError(f"Could not determine the analysis type for file: {files[0]}")
    elif len(files) == 2:
        if all(f.endswith(('.fastq', '.fq', '.fastq.gz', '.fq.gz')) for f in files):
            return 'illumina'
        else:
            raise ValueError("Paired files should both have fastq or fq extensions.")
    elif len(files) == 3:
        if all(f.endswith(('.fastq', '.fq', '.fastq.gz', '.fq.gz')) for f in files):
            return 'hybrid'
        else:
            raise ValueError("All three files should have fastq or fq extensions.")
    else:
        raise ValueError("Unexpected number of files for determining the analysis type.")

def convert_to_table_format(id, input_files, analysis_type, output_dir):
    """Convert input files to table format and save as a TSV file."""
    tsv_file = os.path.join(output_dir, 'input_files.tsv')
    with open(tsv_file, 'w') as f:
        f.write("id\tfile_1\tfile_2\tfile_3\ttype\n")  # Header
        
        # Prepare the row data
        file_1 = input_files[0] if len(input_files) > 0 else ""
        file_2 = input_files[1] if len(input_files) > 1 else ""
        file_3 = input_files[2] if len(input_files) > 2 else ""
        
        # Write the row with the determined analysis type
        f.write(f"{id}\t{file_1}\t{file_2}\t{file_3}\t{analysis_type}\n")
    
    return tsv_file

def validate_tsv(tsv_file):
    """Validate the TSV file format."""
    expected_headers = ['id', 'file_1', 'file_2', 'file_3', 'type']
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
                if not row['file_2'] or not row['file_3']:
                    raise ValueError("For illumina type, both file_2 and file_3 must be provided.")
            elif row['type'] == 'hybrid':
                if not row['file_2'] or not row['file_3']:
                    raise ValueError("For hybrid type, file_2 and file_3 must be provided.")
            else:
                if not row['file_1']:
                    raise ValueError("For long and assembly types, file_1 must be provided.")
