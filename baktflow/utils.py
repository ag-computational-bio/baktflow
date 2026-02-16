import csv
import os
import sys
from pathlib import Path
import os
import logging
import shutil
from pathlib import Path
# Define expected file counts for each sample type
sample_types = {'short', 'long', 'assembly', 'hybrid'}
short_files = 2  # Expecting R1 and R2 files
long_files = 1      # Expecting one long-read file
assembly_files = 1  # Expecting one assembly file
hybrid_files = 3    # Expecting three files for hybrid samples

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
        sample_type = 'hybrid'
    elif r1 and r2:
        sample_type = 'short'
    elif long:
        sample_type = 'long'
    elif assembly:
        sample_type = 'assembly'
    else:
        return None
    return sample_type



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

    row = [sample_id, sample_type, r1 or '', r2 or '', long or '', assembly or '']
    
    logger.info(f"TSV Row Content: {row}")

    try:
        with open(output_path, 'w', newline='') as f:
            writer = csv.writer(f, delimiter='\t')
            writer.writerow(row)
        logger.info(f"TSV file successfully written at: {output_path}")
    except Exception as e:
        logger.error(f"Error writing TSV file: {e}")


# ------------------------------
# BATCH PROCESSING FUNCTION
# ------------------------------
def process_tsv(input_tsv, input_dir):
    """Process the TSV file and generate a modified version with absolute file paths.
    
    Args:
        input_tsv (str): Path to the input TSV file containing sample information.
        input_dir (str): Directory where the raw sequence files are located.

    Returns:
        str or None: Path to the modified TSV file if successful, otherwise None.
    """
    
    # Create a temporary folder inside the main 'baktflow' directory for storing modified TSV files
    temp_folder = os.path.join(os.path.dirname(os.path.dirname(input_tsv)), 'temp')
    os.makedirs(temp_folder, exist_ok=True)

    # Define the output file path for the processed TSV
    output_file = os.path.join(temp_folder, 'temp_tsv.tsv')

    # Read the contents of the input TSV file
    try:
        with open(input_tsv, 'r') as infile:
            reader = infile.readlines()
    except Exception as e:
        print(f"Error reading the input TSV file: {e}")
        return None

    # List to store processed rows that will be written to the new TSV file
    processed_rows = []

    # Process each row from the input TSV file
    for idx, row in enumerate(reader, start=1):
        # Strip whitespace and split by spaces or tabs
        row = [col.strip() for col in row.split()]
        
        # Skip rows that do not contain the minimum required number of columns
        if len(row) < 3:
            print(f"Skipping incomplete row (Line {idx}): {row}")
            user_input = input(f"Incomplete row on Line {idx}: {row}. Do you want to skip this line? (y/n): ")
            if user_input.lower() == 'y':
                print(f"Skipping line {idx}...")
                continue
            else:
                print(f"Please check the data for line {idx}.")
                return None  

        sample_id, sample_type, *files = row
        new_row = [sample_id, sample_type]

        if sample_type not in sample_types:
            logger.warning(f"Invalid sample type '{sample_type}' in row {idx}: {row}")
            continue  

        # Debugging: Print file paths
        logger.debug(f"Processing row {idx}: {row}")

        # Process different sample types
        if sample_type == 'short' and len(files) == short_files:
            new_row.append(os.path.join(input_dir, files[0]))  # R1
            new_row.append(os.path.join(input_dir, files[1]))  # R2
        elif sample_type == 'long' and len(files) == long_files:
            new_row.extend(['', '', os.path.join(input_dir, files[0])])  # Long-read file
        elif sample_type == 'assembly' and len(files) == assembly_files:
            new_row.extend(['', '', '', os.path.join(input_dir, files[0])])  # Assembly file
        elif sample_type == 'hybrid' and len(files) >= hybrid_files:
            new_row.append(os.path.join(input_dir, files[0]))
            new_row.append(os.path.join(input_dir, files[1]))
            new_row.append(os.path.join(input_dir, files[2]))
        else:
            logger.warning(f"Skipping row {idx}: Incorrect file count for type '{sample_type}'")
            continue

        logger.info(f"Processed row {idx}: {new_row}")
        processed_rows.append(new_row)
    # If no valid rows are found, return None
    if not processed_rows:
        print("No valid rows to write to the output file.")
        return None

    # Write the processed data to a new TSV file
    try:
        with open(output_file, 'w', newline='') as outfile:
            writer = csv.writer(outfile, delimiter='\t')
            writer.writerows(processed_rows)
        return output_file  # Return the path of the modified TSV
    except Exception as e:
        print(f"Error writing the processed TSV file: {e}")
        return None