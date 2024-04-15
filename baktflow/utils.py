#utils.py
import csv

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
