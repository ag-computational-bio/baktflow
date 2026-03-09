import json
import logging
import os

import pandas as pd
import plotly.graph_objects as go
from jinja2 import Environment, FileSystemLoader

# Get the installed baktflow directory path
baktflow_dir = os.path.dirname(__file__)

# Create a Jinja2 environment with the template folder as 'baktflow/baktflow'
env = Environment(loader=FileSystemLoader(os.path.join(baktflow_dir)))

# Load the template
template = env.get_template("dashboard_template.html")

# Setup logging
# Setup logging
logging.basicConfig(level=logging.INFO)

# ----------------------- FASTQC SUMMARY -----------------------


def extract_fastqc_summary(fastqc_data):
    """Extracts relevant information from the FastQC summary into one row per file."""

    # Initialize a list to store the extracted data for each file
    summary_data_list = []

    # Loop through each dictionary inside the fastqc_summary list
    for i in range(0, len(fastqc_data), 7):  # We know that there are 7 fields for each file
        summary_data = {}

        # Extract the information for each file and ensure they're on one row
        summary_data["Filename"] = fastqc_data[i].get("Filename", "").strip()
        summary_data["File type"] = fastqc_data[i + 1].get("File type", "").strip()
        summary_data["Encoding"] = fastqc_data[i + 2].get("Encoding", "").strip()
        summary_data["Total Sequences"] = fastqc_data[i + 3].get("Total Sequences", "").strip()
        summary_data["Sequences flagged as poor quality"] = (
            fastqc_data[i + 4].get("Sequences flagged as poor quality", "").strip()
        )
        summary_data["Sequence length"] = fastqc_data[i + 5].get("Sequence length", "").strip()
        summary_data["%GC"] = fastqc_data[i + 6].get("%GC", "").strip()

        # Append the dictionary to the list
        summary_data_list.append(summary_data)

    # Convert summary_data_list into a pandas DataFrame
    df = pd.DataFrame(summary_data_list)

    # Remove rows with NaN values (optional, based on your needs)
    df.dropna(how="all", inplace=True)

    # Convert the DataFrame into an HTML table and return it
    fastqc_summary_html = df.to_html(index=False, na_rep="")

    # Clean the HTML output to remove any unnecessary newline characters
    fastqc_summary_html = fastqc_summary_html.replace("\n", "").strip()

    return fastqc_summary_html


# ----------------------- UNICYCLER SUMMARY -----------------------


def generate_unicycler_table(unicycler_data):
    """Generates a table with contig details from Unicycler data."""
    n50 = unicycler_data.get("assembly_stats", {}).get("n50")
    total_contigs = unicycler_data.get("assembly_stats", {}).get("total_contigs")
    contigs = unicycler_data.get("contigs", [])

    contig_id = [contig.get("contig_id") for contig in contigs]
    lengths = [contig.get("length") for contig in contigs]
    gc_contents = [contig.get("gc_content") for contig in contigs]

    df = pd.DataFrame({"Contig ID": contig_id, "Length": lengths, "GC Content": gc_contents})

    summary = {"n50": n50, "Total Contigs": total_contigs}

    return df, summary


def extract_and_plot_gc_content_unicycler(data):
    """
    Extracts the GC content from the 'contigs' data of Unicycler and creates a line plot.

    :param data: JSON-like data containing 'contigs'.

    :return: Plotly figure in HTML format.
    """

    # Check if the required 'contigs' field exists in the data
    if "contigs" not in data:
        logging.error("'contigs' key not found in the provided data.")
        return None

    # Extract the gc_content values (ignoring contig_ids)
    gc_contents = [contig.get("gc_content") for contig in data["contigs"] if contig.get("gc_content") is not None]

    if not gc_contents:
        logging.error("No valid GC content values found.")
        return None

    # Create a line graph showing GC content values per contig
    fig = go.Figure(
        data=[
            go.Scatter(
                x=list(range(1, len(gc_contents) + 1)),  # Sequential count (1, 2, 3, ...)
                y=gc_contents,  # GC Content values
                mode="lines+markers",  # Line with markers
                line=dict(color="skyblue", width=2),
            )
        ]
    )

    # Update layout with labels and title
    fig.update_layout(
        title="GC Content per Contig",
        xaxis_title="Contig Number",
        yaxis_title="GC Content (%)",
        template="plotly_white",
    )

    return fig.to_html(full_html=False)  # Return HTML representation of the figure


# ----------------------- FASTP SUMMARY -----------------------


def generate_fastp_summary(fastp_data):
    """Generates a summary for FastP data, before and after filtering."""
    # Check if 'summary' key exists
    if "summary" in fastp_data:
        before_filtering = fastp_data["summary"].get("before_filtering", {})
        after_filtering = fastp_data["summary"].get("after_filtering", {})
    else:
        # If no 'summary' key is found, log an error and return empty data
        logging.error("Missing 'summary' in FastP data")
        before_filtering = {}
        after_filtering = {}

    # Prepare data for the table display
    metrics = [
        "Total Reads",
        "Total Bases",
        "Q20 Bases",
        "Q30 Bases",
        "Q20 Rate",
        "Q30 Rate",
        "Read1 Mean Length",
        "Read2 Mean Length",
        "GC Content",
    ]

    before_values = [
        before_filtering.get("total_reads", "N/A"),
        before_filtering.get("total_bases", "N/A"),
        before_filtering.get("q20_bases", "N/A"),
        before_filtering.get("q30_bases", "N/A"),
        before_filtering.get("q20_rate", "N/A"),
        before_filtering.get("q30_rate", "N/A"),
        before_filtering.get("read1_mean_length", "N/A"),
        before_filtering.get("read2_mean_length", "N/A"),
        before_filtering.get("gc_content", "N/A"),
    ]

    after_values = [
        after_filtering.get("total_reads", "N/A"),
        after_filtering.get("total_bases", "N/A"),
        after_filtering.get("q20_bases", "N/A"),
        after_filtering.get("q30_bases", "N/A"),
        after_filtering.get("q20_rate", "N/A"),
        after_filtering.get("q30_rate", "N/A"),
        after_filtering.get("read1_mean_length", "N/A"),
        after_filtering.get("read2_mean_length", "N/A"),
        after_filtering.get("gc_content", "N/A"),
    ]

    # Return the full set of data for before and after filtering
    return {
        "Metric": metrics,
        "Before Filtering": before_values,
        "After Filtering": after_values,
    }


def generate_filtering_summary(filtering_results):
    """Generates a summary for FastP filtering results."""
    metrics = ["Passed Filter Reads", "Low Quality Reads", "Too Many N Reads", "Too Short Reads", "Too Long Reads"]

    filtering_results_values = [
        filtering_results.get("passed_filter_reads", "N/A"),
        filtering_results.get("low_quality_reads", "N/A"),
        filtering_results.get("too_many_N_reads", "N/A"),
        filtering_results.get("too_short_reads", "N/A"),
        filtering_results.get("too_long_reads", "N/A"),
    ]

    return [{"Metric": metric, "Count": count} for metric, count in zip(metrics, filtering_results_values)]


def extract_and_plot_histogram_fastp(duplication):
    # Check if 'duplication' is a dictionary
    if not isinstance(duplication, dict):
        logging.error("Expected 'duplication' to be a dictionary.")
        return None

    # Ensure 'mean_gc' exists inside 'duplication'
    if "mean_gc" not in duplication:
        logging.error("'mean_gc' key not found in 'duplication'.")
        return None

    # Extract mean GC values (multiply by 100)
    mean_gc_values = [value * 100 for value in duplication["mean_gc"]]  # Fix: Directly iterate over the list

    # Generate X-axis values as sequential counts (1, 2, 3, ...)
    x_values = list(range(1, len(mean_gc_values) + 1))  # 1-based index

    # Create the histogram using Plotly
    fig = go.Figure(
        data=[
            go.Bar(
                x=x_values,  # Sequential count (1, 2, 3, ...)
                y=mean_gc_values,  # GC Content (%)
                orientation="v",
                marker_color="skyblue",
            )
        ]
    )

    # Update layout with labels and title
    fig.update_layout(
        title="GC Content at Different Duplication Levels",
        xaxis_title="Duplication Count",
        yaxis_title="GC Content (%)",
        template="plotly_white",
    )

    return fig.to_html(full_html=False)  # Return HTML representation of the figure


# ----------------------- JSON REPORT PROCESSING -----------------------


def find_json_reports(input_directory):
    """Finds and processes JSON reports from the given directory."""
    sample_reports = []

    for sample_id in os.listdir(input_directory):
        sample_path = os.path.join(input_directory, sample_id)

        if not os.path.isdir(sample_path):
            continue

        report_data = {"sample_name": sample_id, "modules": {}}

        for module in os.listdir(sample_path):
            module_path = os.path.join(sample_path, module)

            if not os.path.isdir(module_path):
                continue

            for file in os.listdir(module_path):
                if file.endswith(".json"):
                    file_path = os.path.join(module_path, file)
                    logging.info(f"Processing file: {file_path}")

                    try:
                        with open(file_path, "r") as f:
                            data = json.load(f)

                            if "fastp.json" in file:
                                process_fastp_json(data, report_data, module)
                            elif "unicycler_report.json" in file:
                                process_unicycler_json(data, report_data, module)
                            elif file.endswith(("_1.fastq.json", "_2.fastq.json")):  # New check for .fastq.json
                                process_fastqc_json(data, report_data, module)

                    except Exception as e:
                        logging.error(f"Error processing file {file_path}: {e}")

        sample_reports.append(report_data)

    return sample_reports


def process_fastqc_json(data, report_data, module):
    """Processes the FastQC JSON file and updates the report data."""
    logging.info(f"Processing FastQC JSON for module {module}")

    # Check if the 'fastqc_summary' key exists in the data
    if "fastqc_summary" in data:
        fastqc_summary_html = extract_fastqc_summary(data["fastqc_summary"])

        # Add the FastQC summary to the report
        if module not in report_data["modules"]:
            report_data["modules"][module] = {}

        if "fastqc_summary" not in report_data["modules"][module]:
            report_data["modules"][module]["fastqc_summary"] = []

        # Append the cleaned HTML table to the summary list
        report_data["modules"][module]["fastqc_summary"].append(fastqc_summary_html)
    else:
        logging.warning(f"Missing 'fastqc_summary' in FastQC file: {data.get('file_name', 'unknown file')}")


def process_fastp_json(data, report_data, module):
    """Processes the FastP JSON file and updates the report data."""
    logging.info(f"Processing FastP JSON for module {module}")

    # Check if the 'summary' key exists
    if "summary" in data:
        # Generate the summary for before and after filtering
        before_after_summary = generate_fastp_summary(data)

        # Add the extracted before_after_summary to the report
        if module not in report_data["modules"]:
            report_data["modules"][module] = {}

        report_data["modules"][module]["before_after_filtering_summary"] = before_after_summary

        # Create the zipped data for the table (before and after filtering)
        zipped_data = zip(
            before_after_summary["Metric"],
            before_after_summary["Before Filtering"],
            before_after_summary["After Filtering"],
        )
        data["zipped_fastp_summary"] = list(zipped_data)

        # Add the zipped data to the report
        report_data["modules"][module]["zipped_fastp_summary"] = data["zipped_fastp_summary"]
    else:
        logging.warning(f"Missing 'summary' in file: {data.get('file_name', 'unknown file')}")

    if "duplication" in data:
        duplication_data = data["duplication"]
        if "mean_gc" in duplication_data:
            mean_gc_counts = {idx + 1: value for idx, value in enumerate(duplication_data["mean_gc"])}  # FIXED

            # Store in report data
            report_data["modules"][module]["mean_gc_counts"] = mean_gc_counts

            # Generate the GC content histogram plot
            mean_gc_plot = extract_and_plot_histogram_fastp(duplication_data)
            report_data["modules"][module]["gc_fastp_plot"] = mean_gc_plot

    if "filtering_result" in data:
        filtering_summary = generate_filtering_summary(data["filtering_result"])
        report_data["modules"][module]["filtering_summary"] = filtering_summary


def process_unicycler_json(data, report_data, module):
    """Processes the Unicycler JSON file and updates the report data."""
    if "contigs" in data:
        unicycler_df, unicycler_summary = generate_unicycler_table(data)
        if module not in report_data["modules"]:
            report_data["modules"][module] = {}
        report_data["modules"][module]["unicycler_table"] = unicycler_df.to_html(classes="unicycler-table")
        report_data["modules"][module]["unicycler_summary"] = unicycler_summary
        gc_plot_html = extract_and_plot_gc_content_unicycler(data)

        report_data["modules"][module]["unicycler_gc_plot"] = gc_plot_html


# ----------------------- HTML REPORT GENERATION -----------------------


def generate_html_report(sample_reports, output_file):
    """Generates an HTML report using Jinja2 templates."""

    # Process the sample reports and generate the HTML content
    report_content = template.render(sample_reports=sample_reports)

    # Write the HTML content to the output file
    with open(output_file, "w") as f:
        f.write(report_content)
