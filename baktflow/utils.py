import csv
import os
import sys
from pathlib import Path
import os
import logging
import shutil
from pathlib import Path

# Define color codes
c_blue = "\033[1;34m"
c_green = "\033[1;32m"
c_reset = "\033[0m"

logger = logging.getLogger(__name__)


def check_existence(path: str) -> bool:
    """Check if the path exists."""
    return os.path.exists(path)
def check_directory_accessibility(directory_path):
    """Check if a directory exists and is accessible."""
    directory_path = Path(directory_path)
    return directory_path.is_dir() and directory_path.exists()
def check_writability(directory_path):
    """Check if a directory is writable."""
    directory_path = Path(directory_path)  # Convert to Path object
    test_file = directory_path / 'test_writable'
    try:
        # Create a test file to check writability
        with test_file.open('w') as f:
            pass
        test_file.unlink()  # Remove the test file
        return True
    except IOError:
        return False
def check_tsv_readability(tsv_file):
    """Check if the TSV file exists, is accessible, and can be read."""
    tsv_file = Path(tsv_file)
    
    # Check if the file exists and is a valid file
    if not tsv_file.exists() or not tsv_file.is_file():
        return False
    
    # Try opening the file to check if it can be read
    try:
        with tsv_file.open('r') as f:
            # Attempt to read the first line (simple check for file contents)
            first_line = f.readline()
            if not first_line:  # If the file is empty
                return False
    except Exception as e:
        # If there's an error opening the file, return False
        print(f"Error reading the TSV file: {e}")
        return False
    
    return True
def get_baktflow_parent_dir():
    """Dynamically get the parent directory of the 'baktflow' folder."""
    # Get the absolute path to the current script
    current_script_path = Path(__file__).resolve()
    
    # Navigate one level up from the 'baktflow' directory to get the parent directory
    baktflow_parent_dir = current_script_path.parent.parent  # Going up two levels from the script
    
    return baktflow_parent_dir
# ------------------------------
# SINGLE SAMPLE PROCESSING FUNCTIONS
# ------------------------------

def determine_sample_type(r1=None, r2=None, long=None, assembly=None):
    """
    Determine the type of sequencing data based on file names.
    
    Parameters:
    - r1 (str, optional): Path to the first read file.
    - r2 (str, optional): Path to the second read file.
    - long (str, optional): Path to the long-read file.
    - assembly (str, optional): Path to the assembly file.
    
    Returns:
    - str: The determined sequencing type (illumina, Long, Hybrid, Assembly, or Unknown).
    """
    if r1 and r2 and long:
        return 'hybrid'
    elif r1 and r2:
        return 'illumina'
    elif long:
        return 'long'
    elif assembly:
        return 'assembly'
    else:
        return None



def create_tsv(sample_id, r1=None, r2=None, long=None, assembly=None, analysis_type=None, output_path='temp/temp_tsv.tsv'):
    """
    Create a TSV file containing sample information without headers.
    
    Parameters:
    - sample_id (str): The sample identifier.
    - r1 (str, optional): Path to the first read file.
    - r2 (str, optional): Path to the second read file.
    - long (str, optional): Path to the long-read file.
    - assembly (str, optional): Path to the assembly file.
    - analysis_type (str, optional): The determined sequencing type. If not provided, it will be inferred.
    - output_path (str): Path to save the output TSV file.
    
    Output:
    - Writes a TSV file to the specified location with the format:
      sample_id, sequencing_type, R1_file, R2_file, long_read_file, assembly_file
    """
    # Determine sample type if not provided
    if not analysis_type:
        sample_type = determine_sample_type(r1, r2, long, assembly)
    else:
        sample_type = analysis_type

    print(f"Debug: Sample ID: {sample_id}")
    print(f"Debug: Sequencing Type: {sample_type}")

    # Open the output file in write mode
    with open(output_path, 'w', newline='') as f:
        writer = csv.writer(f, delimiter='\t')

        # Prepare the row to write
        if sample_type == 'hybrid':
            row = [sample_id, sample_type, r1 or '', r2 or '', long or '', '']
        elif sample_type == 'illumina':
            row = [sample_id, sample_type, r1 or '', r2 or '', '', '']
        elif sample_type == 'long':
            row = [sample_id, sample_type, '', '', long or '', '']
        elif sample_type == 'assembly':
            row = [sample_id, sample_type, '', '', '', assembly or '']
        else:  # Default to single-end
            row = [sample_id, 'single-end', r1 or '', '', '', '']

        # Debug: Print the row that will be written
        print(f"Debug: Row to write: {row}")
        
        writer.writerow(row)