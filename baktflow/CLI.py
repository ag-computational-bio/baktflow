import argparse
import logging
import os
import subprocess
from pathlib import Path
import polars as pl

import baktflow.nextflow as bn
import baktflow.utils as bu
import baktflow.report as br

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


def setup_subcommand(args):
    """Setup Baktflow workflow by managing Conda environments and databases"""
    logger.info("Setting up Baktflow workflow...")
    logger.info(f"Setup directory: {args.setup_dir}")

    setup_subdir, conda_dir, database_dir = bu.get_setup_directories(args.setup_dir, setup_mode=True)

    conda_files: list[str] = [file.name for file in conda_dir.iterdir()] if conda_dir.exists() else []
    database_files: list[str] = [file.name for file in database_dir.iterdir()] if database_dir.exists() else []

    if not args.force and (setup_subdir.exists() and (conda_files or database_files)):
        if conda_files or database_files:
            logger.debug(f"Existing Setup found: {', '.join(conda_files + database_files)}")

        response = input("Do you want to reinstall the environments and databases? (Yes/No): ").strip().lower()
        if response == "y" or response == "yes":
            logger.info("Reinstalling all environments and databases...")
            bu.reinstall_directory(conda_dir)
            bu.reinstall_directory(database_dir)
            bn.baktflow_setup(
                bu.get_nf_script("setup.nf"), setup_subdir, conda_dir, database_dir, bakta_db_type=args.bakta_db_type
            )
            logger.info("Reinstallation complete.")

        elif response == "n" or response == "no":
            logger.info("Skipping setup process.")
    else:
        if args.force:
            logger.info("Try forced reinstallation of all environments and databases...")
            bu.reinstall_directory(conda_dir)
            bu.reinstall_directory(database_dir)
        else:
            logger.info("No existing environments or databases found. Installing from scratch...")
        setup_subdir.mkdir(parents=True, exist_ok=True)
        bn.baktflow_setup(
            bu.get_nf_script("setup.nf"), setup_subdir, conda_dir, database_dir, bakta_db_type=args.bakta_db_type
        )


def on_the_fly_setup(setup_dir: str, bakta_db_type: str, work_dir: str, output: Path) -> tuple[Path, Path, str, Path]:
    try:
        _, conda_dir, database_dir = bu.get_setup_directories(setup_dir)
        bu.check_directory_accessibility(conda_dir)
        bu.check_directory_accessibility(database_dir)
        bakta_db_type: str = bu.get_bakta_db_type(database_dir)
    except FileNotFoundError or IOError as e:
        logger.warning(
            f"Did not find installed setup. Trying to install them on the fly (internet connection required).\n\t{e}"
        )
        setup_subdir, conda_dir, database_dir = bu.get_setup_directories(setup_dir, setup_mode=True)
        setup_subdir.mkdir(parents=True, exist_ok=True)
        bakta_db_type: str = bakta_db_type
        bn.baktflow_setup(
            bu.get_nf_script("setup.nf"), setup_subdir, conda_dir, database_dir, bakta_db_type=bakta_db_type
        )

    work_dir: Path = Path(work_dir) if work_dir else output.joinpath("work")
    work_dir.mkdir(parents=True, exist_ok=True)
    return conda_dir, database_dir, bakta_db_type, work_dir


def single_subcommand(args):
    """Run baktflow single analysis."""
    logger.info("Running baktflow single...")
    logger.info(f"Analysis ID: {args.id}\nOutput directory: {args.output}")

    input_files: list[str] = [f for f in [args.r1, args.r2, args.long, args.assembly] if f]
    if len(input_files) == 0:
        raise FileNotFoundError("At least one input file must be provided.")
    extensions = bu.get_fasta_file_extensions()
    for file in input_files:
        if not file.endswith(extensions):
            raise IOError(f"Invalid file extension: {file}")
        bu.check_readable(file)
        logger.info(f"Valid file detected: {file}")

    output = Path(args.output).resolve()
    if output.exists():
        logger.info(f"Output directory already exists. May overwrite existing data: {output}")
    try:
        output.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        raise e
    bu.check_directory_accessibility(output)

    sample_type = bu.determine_sample_type(args.r1, args.r2, args.long, args.assembly)
    tsv_path = output.joinpath("single_config.tsv")
    bu.create_tsv(args.id, sample_type, tsv_path, args.r1, args.r2, args.long, args.assembly)

    conda_dir, database_dir, bakta_db_type, work_dir = on_the_fly_setup(
        args.setup_dir, args.bakta_db_type, args.work_dir, output
    )


    bn.run_baktflow_workflow(
        workflow_script=bu.get_nf_script("main.nf"),
        input_tsv=tsv_path,
        output_path=output,
        conda_dir=conda_dir,
        database_dir=database_dir,
        bakta_db_type=bakta_db_type,
        work_dir=work_dir,
        profile=args.profile,
        resume=args.resume,
        stub=args.stub,
    )
    logger.info("Nextflow workflow executed successfully.")

    jsons = br.check_output(output_dir=output)
    br.create_aggregated_json(path_json_files=jsons, output_dir=output, sample_id=args.id)

    logger.info("Report generation completed successfully.")


def batch_subcommand(args):
    """Run baktflow batch analysis."""
    logger.info("Running baktflow batch...")
    logger.info(f"Input TSV file: {args.input_tsv}")
    logger.info(f"Input directory: {args.input_dir}")
    logger.info(f"Output directory: {args.output}")

    bu.check_readable(args.input_tsv)
    bu.check_directory_accessibility(args.input_dir)

    output = Path(args.output).resolve()
    if output.exists():
        logger.info(f"Output directory already exists. May overwrite existing data: {output}")
    try:
        output.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        raise e
    bu.check_directory_accessibility(output)

    # Process the TSV file and generate a temporary TSV file
    cleaned_tsv: Path = bu.preprocess_tsv(args.input_tsv, Path(args.input_dir), output)
    logger.info(f"Temporary TSV file saved at {cleaned_tsv}")

    conda_dir, database_dir, bakta_db_type, work_dir = on_the_fly_setup(
        args.setup_dir, args.bakta_db_type, args.work_dir, output
    )

    bn.run_baktflow_workflow(
        workflow_script=bu.get_nf_script("main.nf"),
        input_tsv=cleaned_tsv,
        output_path=output,
        conda_dir=conda_dir,
        database_dir=database_dir,
        bakta_db_type=bakta_db_type,
        work_dir=work_dir,
        profile=args.profile,
        resume=args.resume,
        stub=args.stub,
    )
    logger.info("Nextflow workflow executed successfully.")

    df = pl.read_csv(cleaned_tsv, separator="\t", has_header=False)
    samples_id = df[:,0].to_list()
    for sample in samples_id:
        jsons = br.check_output(output_dir=f"{output}/{sample}")
        br.create_aggregated_json(path_json_files=jsons, output_dir=f"{output}/{sample}", sample_id=sample)

    logger.info("Report generation completed successfully.")


def parse_arguments():
    """Parse command-line arguments."""
    parser = argparse.ArgumentParser(description="baktflow: ")
    subparsers = parser.add_subparsers(title="subcommands", dest="subcommand")

    # Setup subcommand
    setup_parser = subparsers.add_parser("setup", help="Setup baktflow workflow")
    setup_parser.add_argument(
        "--setup_dir",
        "-d",
        required=True,
        help="Directory for the workflow setup",
    )
    setup_parser.add_argument(
        "--force", "-f", action="store_true", help="Force the (re)installation setup of baktflow."
    )
    setup_parser.add_argument(
        "--bakta_db_type", type=str, default="light", help="Bakta database type [light, full]. default = 'light'"
    )

    # Single subcommand
    single_parser = subparsers.add_parser("single", help="Run baktflow single analysis")
    single_parser.add_argument("--id", help="ID for a specific single analysis", required=True)
    single_parser.add_argument("--output", help="Output directory", required=True)
    single_parser.add_argument("--setup_dir", help="Directory for the workflow setup", required=True)
    single_parser.add_argument(
        "--bakta_db_type", type=str, default="light", help="Bakta database type [light, full]. default = 'light'"
    )
    single_parser.add_argument("--work_dir", help="Directory for the nextflow work folder (default: output/work)")
    single_parser.add_argument("--profile", type=str, default="standard", help="Nextflow execution profile")
    single_parser.add_argument("--resume", help="Resume the workflow", action="store_true")
    single_parser.add_argument("--r1", default=None, help="Input file for R1 sequencing reads (FASTQ format)")
    single_parser.add_argument("--r2", default=None, help="Input file for R2 sequencing reads (FASTQ format)")
    single_parser.add_argument("--long", default=None, help="Input file for long reads (FASTQ format)")
    single_parser.add_argument("--assembly", default=None, help="Input assembly file (FASTQ format)")
    single_parser.add_argument("--stub", action="store_true", help="Executed pipeline with the -stub-run option")

    # Batch subcommand
    batch_parser = subparsers.add_parser("batch", help="Run baktflow batch analysis")
    batch_parser.add_argument("--input_tsv", help="Input TSV for batch analysis", required=True)
    batch_parser.add_argument("--input_dir", help="Input directory for batch analysis", required=True)
    batch_parser.add_argument("--output", help="Output directory for batch analysis", required=True)
    batch_parser.add_argument("--setup_dir", help="Directory for the workflow setup", required=True)
    batch_parser.add_argument(
        "--bakta_db_type", type=str, default="light", help="Bakta database type [light, full]. default = 'light'"
    )
    batch_parser.add_argument("--work_dir", "-w", help="Directory for the nextflow work folder (default: output/work)")
    batch_parser.add_argument("--profile", type=str, default="standard", help="Nextflow execution profile")
    batch_parser.add_argument("--resume", help="Resume the workflow", action="store_true")
    batch_parser.add_argument("--stub", action="store_true", help="Executed pipeline with the -stub-run option")

    return parser.parse_args()


def main():
    args = parse_arguments()

    if args.subcommand == "setup":
        setup_subcommand(args)
    elif args.subcommand == "single":
        single_subcommand(args)
    elif args.subcommand == "batch":
        batch_subcommand(args)
    else:
        logger.error("No subcommand provided. Use --help for usage information.")


if __name__ == "__main__":
    main()
