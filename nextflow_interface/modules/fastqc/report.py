import argparse
import json
import os
import zipfile


def parse_fastqc_txt(fastqc_txt_content):
    fastqc_data = {}
    current_module = None
    for line in fastqc_txt_content.splitlines():
        if not line.strip():
            continue
        if line.startswith(">>"):
            current_module = line.split("\t")[0][2:]
            fastqc_data[current_module] = []
            continue
        if line.startswith("#"):
            continue
        if current_module:
            if current_module == "Basic Statistics" and not line.startswith("#"):
                columns = line.split("\t")
                if len(columns) == 2:
                    fastqc_data[current_module].append({columns[0]: columns[1]})
            elif current_module == "Per sequence GC content" and not line.startswith("#"):
                columns = line.split("\t")
                if len(columns) == 2:
                    try:
                        gc_content = int(columns[0])
                        count = float(columns[1])
                        fastqc_data[current_module].append({"GC Content": gc_content, "Count": count})
                    except ValueError:
                        continue
    return fastqc_data


def create_json_report(input_filename, fastqc_txt_content, output_dir):
    fastqc_data = parse_fastqc_txt(fastqc_txt_content)
    report = {
        "fastqc_summary": fastqc_data.get("Basic Statistics", []),
        "gc_content": fastqc_data.get("Per sequence GC content", []),
        "Filename": input_filename,  # Set the input filename in the JSON report
    }

    # Clean base filename and remove '_fastqc' suffix
    base_filename = os.path.basename(input_filename).replace("_fastqc", "").replace(".zip", "")

    # Normalize sample names for paired-end reads
    if base_filename.endswith("_1") or base_filename.endswith("_2"):
        base_filename = base_filename.rsplit("_", 1)[0]

    # Save the JSON report with the full filename
    json_output_path = os.path.join(output_dir, f"{input_filename}.json")

    # Save the JSON report
    with open(json_output_path, "w") as json_file:
        json.dump(report, json_file, indent=4)
    print(f"JSON report saved at {json_output_path}")


def extract_and_process_zip(zip_path, input_filename, output_dir):
    if not os.path.exists(zip_path):
        print(f"ZIP file {zip_path} not found.")
        return
    try:
        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            txt_files = [f for f in zip_ref.namelist() if f.endswith("fastqc_data.txt")]
            if not txt_files:
                print(f"No fastqc_data.txt found inside the ZIP: {zip_path}")
                return
            with zip_ref.open(txt_files[0]) as file:
                fastqc_txt_content = file.read().decode("utf-8")
        create_json_report(input_filename, fastqc_txt_content, output_dir)
    except Exception as e:
        print(f"Error processing ZIP file {zip_path}: {e}")


def process_zip_files(zip_files, output_dir):
    for zip_path in zip_files:
        # Extract the full filename (including suffix) for the input filename
        input_filename = os.path.basename(zip_path).replace("_fastqc.zip", "")  # Remove the suffix like '_fastqc.zip'
        print(f"Processing ZIP file: {zip_path}")
        extract_and_process_zip(zip_path, input_filename, output_dir)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--zip", nargs="+", required=True, help="List of FastQC ZIP files to process")
    parser.add_argument("--output", required=True, help="Directory to save the JSON reports")
    args = parser.parse_args()

    zip_files = args.zip
    output_dir = args.output

    process_zip_files(zip_files, output_dir)


if __name__ == "__main__":
    main()
