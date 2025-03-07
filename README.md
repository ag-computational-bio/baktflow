# Baktflow: Automated Bacterial Genome Analysis Pipeline

Welcome to the documentation for **Baktflow**, a user-friendly bacterial genome analysis pipeline built on Python and Nextflow. It is designed to handle both single and batch processing of genomic data. Baktflow ensures portability and reliability across diverse computing environments, making it ideal for both novice and advanced users.

## Pipeline Objectives

The Baktflow pipeline is designed with the following key objectives in mind to ensure a seamless and efficient experience for users at all expertise levels:
- **Technical Abstraction**: Shields users from complex technical processes, allowing them to focus on their analysis.
- **End-to-End Automation**: Fully automates the process from data input to result generation.
- **Accessibility Across Expertise Levels**: Suitable for both beginners and advanced users.

## Features

- **Sequencing Data Types**: Supports Paired-End Illumina Reads for high-coverage short-read applications, Long Reads (Nanopore) for structural variant analysis and complex genome assembly, Hybrid Data combining short and long reads for enhanced genome assemblies, and Assembled Genomes in FASTA format for downstream analysis like annotation or comparative genomics.
 - **Automated Preprocessing and Annotation** Baktflow handles preprocessing steps including quality checks,read trimming , and genome assembly . These steps prepare the data for downstream analysis, which includes genome annotation.

- **Aggregated Report** Baktflow generates a summarized report that consolidates key analysis results across all samples, including quality assessments from FastQC, assembly statistics from Unicycler, and read trimming data from FastP. This report provides an overview of the entire analysis pipeline, summarizing results from different sequencing technologies and sample types.


## Installation

### Prerequisites

Before starting the installation, ensure you have the following prerequisites installed:

- **Python**: Version 3.9 or higher
- **Nextflow**: Version 23.3+ (or compatible version)
- **Mamba**: Recommended for environment management (alternative to Conda for faster package management)

### Installation Steps

1. **Install Nextflow**  
   Follow the installation instructions on the [Nextflow website](https://www.nextflow.io/).

2. **Install Python Dependencies**  
   Install the required Python packages by running:
   ```bash
   pip install -r requirements.txt
    ```
   This will install the following dependencies:

    - **pandas>=1.0.0**: For reading and manipulating TSV files.
    
    - **jinja2>=2.10**: For generating reports from templates.
                                                             
    - **plotly>=4.0.0**: For visualizing data in reports.


 3. **Install Baktflow**

   The pipeline also requires the Baktflow package. You can install it using 
    pip:

   ```bash
   pip install baktflow
   ```


## Input
The pipeline accepts the following input data types:

FASTQ files: Sequencing data files from various platforms (e.g., Illumina, Nanopore).
FASTA files: Assembly or reference genome files (if applicable).
TSV files: Metadata file that provides information about the samples and their corresponding sequencing files. The file must contain the following columns:
- `id`: sample ID
- `type`: type of sample (hybrid, long, short, etc.)
- `file_1`: path to the first FASTQ file
- `file_2`: path to the second FASTQ file (if paired-end)
- `file_3`: path to the third FASTQ file (if applicable)
```
| id  | type   | file_1               | file_2             | file_3            |
| --- | ------ | -------------------- | ------------------ | ----------------- |
|     | hybrid | R1.fastq.gz          | R2.fastq.gz        | long.fastq.gz     |
|     | long   | /path/to/long1.fastq.gz |                   |                   |
```

## Output

Each sample is stored in its own folder within the output/ directory, containing subfolders for differents modules.Additionally, an aggregated report (aggregated_report.html) at the top level summarizes results across all samples.
```
output
├── sample_id1
│   ├── quality_check
│   │   ├── sample_id1_fastqc.html
│   │   ├── sample_id1_fastqc.zip
│   │   └── ...
│   ├── assembly
│   │   ├── sample_id1_assembly.gfa
│   │   ├── sample_id1_assembly.fa
│   │   └── ...
│   ├── annotation
│   │   ├── sample_id1_annotation.gtf
│   │   ├── sample_id1_annotation.gff
│   │   └── ...
│   
│
├── aggregated_report.html  
```

## Main Subcommands

### Setup
The `setup` subcommand initializes the pipeline environment, ensuring all necessary configurations and dependencies are in place.

**Example Execution:**
```bash
baktflow setup --directory /path/to/home --nextflow_path /path/to/nextflow
```
Parameters:

**`--directory (Optional)`**: Home directory for the pipeline setup.

**`--nextflow_path (Optional)`**: Path to the Nextflow installation.


### Single 
The single subcommand processes an individual sample by specifying sequencing files directly. Ideal for analyzing a single dataset without needing a TSV file.

Example Execution:
```bash
baktflow single --r1 /path/to/m3.fastq.gz --r2 /path/to/m4.fastq.gz --id sample_32 --output /path/to/results
```
**Parameters:**

**`--r1`**: Specifies the path for the R1 (forward) read file for Illumina short-read sequencing.
**`--r2`**: Specifies the path for the R2 (reverse) read file for Illumina short-read sequencing.

**`--long`**:  Specifies the path for the long-read sequencing data 

**`--assembly`**: Specifies the path for the assembly data.

**`--id`**: Specifies the ID for a specific single analysis.

**`--output`**(Optional): Specifies the output directory for the analysis results.

### Batch
For batch analyses, a TSV file containing sample information and the input directory for the sequencing data are required. 

**Example Execution:**
```bash
baktflow batch --input_tsv /path/to/samples.tsv --input_dir /path/to/reads --output /path/to/results
```
Parameters:

**`--input_tsv (Required)`**: Path to the TSV file containing sample details.

**`--input_dir (Required)`**: Directory where sequencing files are located.

**`--output (Optional)`**: Output directory for results.

### Reporting
The report subcommand generates summary reports from previously processed data, consolidating results into structured outputs.

**Example Execution:**
```bash
baktflow report --input_dir /path/to/output --output_dir /path/to/reports
```
Parameters:

**`--input_dir (Required)`**: Directory containing output files (e.g., JSON files) from previous pipeline steps like FastQC.

**`--output_dir (Required)`**: Directory to save the aggregated report.


## Workflow Overview

The Baktflow pipeline combines a Python-based command-line interface (CLI) with Nextflow to streamline and automate sequencing data analysis. Users interact with Baktflow through the CLI, providing input data and parameters, while Baktflow handles data preprocessing, validation, and formatting.

Nextflow orchestrates the analysis by parallelizing tasks and triggering subworkflows based on sequencing technology (Illumina, Nanopore, or Hybrid). It manages the execution of processes such as quality control, read trimming, assembly, polishing, and annotation, ensuring tasks are run efficiently and in the correct order. Nextflow also handles resource management, running the pipeline across local machines, clusters, or cloud platforms, and provides error handling for robust execution.

Once the analysis is complete, Baktflow organizes the results by sample ID and compiles them into user-friendly reports for easy interpretation.



## Sequencing Data Types and Tools
Baktflow supports multiple sequencing data types, each requiring specific preprocessing and analysis steps. The workflow includes quality control, read trimming, genome assembly, polishing, reorientation, and annotation to ensure high-quality genomic data for downstream applications.

- **Paired-End** Illumina Reads undergo quality control (FastQC) [1], trimming (FastP) [2], and assembly (Unicycler) [3].Following the reorientation (Dnaapler) [4], the data is annotated (Bakta) [5].

- **Long Reads** (Nanopore) are processed using quality control (FastQC), trimming (Filtlong) [6], assembly (Flye) [7], and polishing (Medaka) [8]. The final reoriented assembly (Dnaapler) is annotated with Bakta.

- **Hybrid Data** combines Illumina (short-read) and Nanopore (long-read) technologies, integrating FastQC, FastP (Illumina), Filtlong (Nanopore), Unicycler (assembly), Medaka (long-read polishing), and Pypolca [9] / PolyPolish [110] (short-read polishing). After reorientation with Dnaapler, the data is annotated with Bakta.

- **Assembled Genomes** skip trimming, assembly, and polishing steps, proceeding directly to annotation (Bakta).


```
| **Sequencing Technology**       | **Quality Control Tool**  | **Read Trimming Tool**                | **Assembly Tool**    | **Polishing Tool**                     | **Reorientation Tool**  | **Annotation Tool**  |
|----------------------------------|---------------------------|---------------------------------------|----------------------|----------------------------------------|-------------------------|----------------------|
| **Paired-End Illumina Reads**    | FastQC                    | FastP                                 | Unicycler            | None                                   | Dnaapler                | Bakta                |
| **Long Reads (Nanopore)**        | FastQC                    | Filtlong                              | Flye                 | Medaka                                 | Dnaapler                | Bakta                |
| **Hybrid Data**                  | FastQC                    | FastP Filtlong                        | Unicycler            | Medaka Pypolca / PolyPolish           | Dnaapler                | Bakta                |
| **Assembled Genomes (FASTA)**    |                           | No trimming                           | No assembly          | No polishing                                                     | Bakta                |




```

## Usage 

```
 
Baktflow: An Automated Bacterial Genome Analysis Pipeline

Setup Subcommand
baktflow setup --directory /path/to/home --nextflow_path /path/to/nextflow

Flags for Setup
--directory (Optional): Home directory for the pipeline setup.
--nextflow_path (Optional): Path to the Nextflow installation.

Single Subcommand
baktflow single --r1 /path/to/r1 --r2 /path/to/r2 --id sample_32 --output /path/to/results

Flags for Single Analysis
--id (Required): Specifies the ID for the analysis.
--type (Required): Specifies the type of analysis. Options: illumina, nanopore, hybrid.
--r1 (Required): Specifies the path to the first read file.
--r2 (Required): Specifies the path to the second read file (for paired-end reads).
--long (Optional): Specifies the path to the nanopore file (if applicable).
--assembly (Optional): Specifies the path to the assembly file (if applicable).

Batch Subcommand
baktflow batch --input_tsv /path/to/samples.tsv --input_dir /path/to/reads --output /path/to/results

Flags for Batch Analysis
--input_tsv (Required): Path to the TSV file containing sample details.
--input_dir (Required): Location where the sequencing data is stored.
--output (Optional): Output directory for the analysis results.

Report Subcommand
baktflow report --input_dir /path/to/json --output_dir /path/to/output 

Flags for Report Analysis
--input_dir (Required): Path to the JSON files produced during the Nextflow workflow execution.
--output (Optional): Output directory for the aggregated report.tput directory for the aggregated report. 

General Flags
--help: Show help message.
--version: Show program's version number.

```

## Troubleshooting
Common Issues
Error in Processing Sample Data: Ensure that the paths to input files in the TSV are correct and files are accessible.
Dependencies: If any dependencies are missing, ensure the requirements.txt is properly installed

## FAQs
How can I customize my pipeline configuration?
You can modify the env.yaml inside the nextflow modules.


## References
[1] Babraham Bioinformatics - FastQC A Quality Control tool for High Throughput Sequence Data. (2025). Retrieved March 6, 2025, from Babraham.ac.uk website: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/


[2] Chen, S., Zhou, Y., Chen, Y., & Gu, J. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. Bioinformatics, 34(17), i884–i890. https://doi.org/10.1093/bioinformatics/bty560

[3] Wick, R. R., Judd, L. M., Gorrie, C. L., & Holt, K. E. (2017). Unicycler: Resolving bacterial genome assemblies from short and long sequencing reads. PLoS Computational Biology, 13(6), e1005595–e1005595. https://doi.org/10.1371/journal.pcbi.1005595

[4] Bouras, G., Grigson, S. R., Bhavya Papudeshi, Vijini Mallawaarachchi, & Roach, M. J. (2024). Dnaapler: A tool to reorient circular microbial genomes. The Journal of Open Source Software, 9(93), 5968–5968. https://doi.org/10.21105/joss.05968

[5] Schwengers, O., Jelonek, L., Dieckmann, M. A., Beyvers, S., Blom, J., & Goesmann, A. (2021). Bakta: rapid and standardized annotation of bacterial genomes via alignment-free sequence identification. Microbial Genomics, 7(11). https://doi.org/10.1099/mgen.0.000685

[6] https://github.com/rrwick/Filtlong

[7] Mikhail Kolmogorov, Yuan, J., Lin, Y., & Pevzner, P. A. (2019). Assembly of long, error-prone reads using repeat graphs. Nature Biotechnology, 37(5), 540–546. https://doi.org/10.1038/s41587-019-0072-8

[8] nanoporetech. (2024, October 11). GitHub - nanoporetech/medaka: Sequence correction provided by ONT Research. Retrieved March 6, 2025, from GitHub website: https://github.com/nanoporetech/medaka

‌[9]Bouras, G., Judd, L. M., Edwards, R. A., Vreugde, S., Stinear, T. P., & Wick, R. R. (2024). How low can you go? Short-read polishing of Oxford Nanopore bacterial genome assemblies. Microbial Genomics, 10(6). https://doi.org/10.1099/mgen.0.001254

[9] Zimin, A. V., & Salzberg, S. L. (2020). The genome polishing tool POLCA makes fast and accurate corrections in genome assemblies. PLoS Computational Biology, 16(6), e1007981–e1007981. https://doi.org/10.1371/journal.pcbi.1007981

[10] Wick, R. R., & Holt, K. E. (2022). Polypolish: Short-read polishing of long-read bacterial genome assemblies. PLOS Computational Biology, 18(1), e1009802. https://doi.org/10.1371/journal.pcbi.1009802










