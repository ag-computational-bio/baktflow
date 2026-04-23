import csv
import logging
import os
import shutil
from pathlib import Path

logger = logging.getLogger(__name__)


def get_nf_dir() -> Path:
    root_dir: Path = Path(__file__).parent.parent.resolve()
    nextflow_dir: Path = root_dir.joinpath("nextflow_interface")
    return nextflow_dir


def get_nf_script(script_name: str) -> Path:
    return get_nf_dir().joinpath(script_name)


def get_nf_workflow_script() -> Path:
    return get_nf_dir()


def get_conda_implementation() -> str:
    if bool(shutil.which("micromamba")):
        return "micromamba"
    elif bool(shutil.which("mamba")):
        return "mamba"
    elif bool(shutil.which("conda")):
        return "conda"
    else:
        raise Exception("No Conda, Mamba or Micromamba")


def get_fasta_file_extensions() -> tuple[str, ...]:
    fasta_extensions: list[str] = [".fastq", ".fq", ".fasta", ".fa"]
    compression_extensions: list[str] = [".gz"]
    valid_extensions: list[str] = fasta_extensions + [
        fe + ce for fe in fasta_extensions for ce in compression_extensions
    ]
    return tuple(valid_extensions)


def get_bakta_db_type(database_path: Path) -> str:
    bakta_db_path: Path = database_path.joinpath("bakta")
    db_dir: list[Path] = list(bakta_db_path.glob("db-*"))
    db_type: str = str(db_dir[0]).split("-")[-1]
    return db_type


def reinstall_directory(path: Path):
    try:
        shutil.rmtree(path, ignore_errors=True)
        path.mkdir(parents=True)
    except Exception as e:
        raise e


def get_setup_directories(setup_dir: str | Path, setup_mode: bool = False) -> tuple[Path, Path, Path, Path]:
    setup_subdir: Path = Path(setup_dir).resolve()
    conda_dir: Path = setup_subdir.joinpath("envs")
    database_dir: Path = setup_subdir.joinpath("databases")
    models_dir: Path = setup_subdir.joinpath("models")
    if not setup_mode:
        check_readable(database_dir)
        check_readable(models_dir)
    if not conda_dir.exists():
        logger.warning(
            "Could not find installed conda environments. Trying to install them on the fly (internet connection required)."
        )
    return setup_subdir, conda_dir, database_dir, models_dir


def check_readable(path: str | Path) -> None:
    """Check if the path exists."""
    if not os.path.exists(path):
        raise FileNotFoundError(f"Path does not exist: {path}")
    if not os.access(path, os.R_OK):
        raise IOError(f"Path is not readable: {path}")


def check_directory_accessibility(directory_path: str | Path):
    """Check if a directory exists and is accessible."""
    directory_path = Path(directory_path)
    if not directory_path.exists():
        raise FileNotFoundError(f"Directory does not exist: {directory_path}")
    if not directory_path.is_dir():
        raise IOError(f"Is not a directory: {directory_path}")
    if not os.access(directory_path, os.R_OK):
        raise IOError(f"Directory is not readable: {directory_path}")


# ------------------------------
# SINGLE SAMPLE PROCESSING FUNCTIONS
# ------------------------------


def determine_sample_type(r1: str | None, r2: str | None, long: str | None, assembly: str | None) -> str:
    """
    Determine the type of sequencing data based on file names.

    Parameters:
    - r1 (str, optional): Path to the first read file.
    - r2 (str, optional): Path to the second read file.
    - long (str, optional): Path to the long-read file.
    - assembly (str, optional): Path to the assembly file.

    Returns:
    - str | None: The determined sequencing type (Short, Long, Hybrid, Assembly, or None).
    """
    if r1 and r2 and long and not assembly:
        return "hybrid"
    elif r1 and r2 and not (long or assembly):
        return "short"
    elif long and not (r1 or r2 or assembly):
        return "long"
    elif assembly and not (r1 or r2 or long):
        return "assembly"
    else:
        raise Exception(
            f"Could not determine sample type from input:\nR1: {r1}\nR2: {r2}\nLong: {long}\nAssembly: {assembly}"
        )


def create_tsv(
    sample_id: str,
    sample_type: str,
    output_path: Path,
    r1: str = "",
    r2: str = "",
    long: str = "",
    assembly: str = "",
):
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
    row: list[str | None] = [
        sample_id,
        sample_type,
    ] + [str(Path(f).resolve()) if f else None for f in [r1, r2, long, assembly]]
    logger.info(f"TSV Row Content: {row}")

    try:
        with open(output_path, "w") as f:
            writer = csv.writer(f, delimiter="\t")
            writer.writerow(row)
        logger.info(f"TSV file successfully written at: {output_path}")
    except IOError as e:
        raise IOError(f"Error writing TSV file: {e}")


# ------------------------------
# BATCH PROCESSING FUNCTION
# ------------------------------


def checked_file(file_path: str, input_dir: Path, extensions: tuple[str, ...]) -> str:
    if not file_path.endswith(extensions):
        raise IOError(f"Invalid file extension: {file_path}")
    abs_path: Path = input_dir.joinpath(file_path).resolve()
    check_readable(abs_path)
    return str(abs_path)


def preprocess_tsv(input_tsv: str | Path, input_dir: Path, output_dir: Path) -> Path:
    """Process the TSV file and generate a modified version with absolute file paths.

    Args:
        input_tsv (str): Path to the input TSV file containing sample information.
        input_dir (Path): Path to the directory containing the samples.
        output_dir (str): Output directory

    Returns:
        str or None: Path to the modified TSV file if successful, otherwise None.
    """
    sample_types: dict[str, int] = {
        "short": 2,
        "long": 1,
        "hybrid": 3,
        "assembly": 1,
    }
    if not str(input_tsv).endswith((".csv", ".tsv")):
        raise IOError(f"File {input_tsv} is not a .tsv or .csv file")

    cleaned_tsv_file = output_dir.joinpath("cleaned_config.tsv")
    seperator: str = "\t"
    extensions = get_fasta_file_extensions()

    with open(input_tsv, "r") as infile, open(cleaned_tsv_file, "w", newline="\n") as outfile:
        tsv_writer = csv.writer(outfile, delimiter="\t")
        for i, line in enumerate(infile, start=1):
            row: list[str] = [c for c in line.strip().split(seperator) if len(c) > 0]
            if len(row) < 3:
                logger.warning(f"Skipping line {i}. Invalid input: {line}")
                continue

            sample_id, sample_type, *files = row
            checked_row: list[str] = [sample_id, sample_type]

            if sample_type not in sample_types:
                logger.warning(f"Invalid sample type '{sample_type}' in row {i}: {row}")
                continue

            logger.info(f"Processing row {i}: {' '.join(row)}")
            if sample_type == "short" and len(files) == sample_types["short"]:
                checked_row.append(checked_file(files[0], input_dir, extensions))  # R1
                checked_row.append(checked_file(files[1], input_dir, extensions))  # R2
            elif sample_type == "long" and len(files) == sample_types["long"]:
                checked_row.extend(["", "", checked_file(files[0], input_dir, extensions)])  # Long-read file
            elif sample_type == "hybrid" and len(files) == sample_types["hybrid"]:
                checked_row.append(checked_file(files[0], input_dir, extensions))  # R1
                checked_row.append(checked_file(files[1], input_dir, extensions))  # R2
                checked_row.append(checked_file(files[2], input_dir, extensions))  # Long-read file
            elif sample_type == "assembly" and len(files) == sample_types["assembly"]:
                checked_row.extend(["", "", "", checked_file(files[0], input_dir, extensions)])  # Assembly file
            else:
                logger.warning(f"Skipping row {i}: Incorrect file count for type '{sample_type}'")
                continue

            tsv_writer.writerow(checked_row)

    return cleaned_tsv_file