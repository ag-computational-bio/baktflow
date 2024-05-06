


# Baktaflow: Automated Bacterial Genome Analysis Pipeline
Baktflow is an automated pipeline designed for seamless assembly, annotation, and advanced analyses of bacterial genomes. With its modular architecture, Baktflow orchestrates the analysis process seamlessly, automatically executing each step without user intervention. 
It efficiently preprocesses diverse sequence data types, saving time and addressing versatile genomic analysis needs.

It uses Nextflow which ensures portability and reliability across diverse computing environments.


## Pipeline Objectives

The automated pipeline is built with the following key objectives in mind:

- **User-Friendly Interface:** Prioritize a user-friendly design to facilitate seamless interaction with the pipeline.
- **Technical Abstraction:** Abstract technical complexities to shield users from intricate details.
- **End-to-End Automation:** Offer end-to-end automation from data input to result generation.
- **Accessibility Across Expertise Levels:** Design the pipeline to cater to users with varying levels of expertise.

# Features

- **Quality Check** Perform a quality check
- **Assembly:** Perform  assembly of bacterial genomes.
- **Annotation:** Annotate assembled genomes with functional and structural annotations.


# Installation

To install Bakta, follow these steps:

1. Clone the repository: `git clone https://github.com/your/repository.git`
2. Set up configuration: `cp config.example.yaml config.yaml` and edit `config.yaml` as needed.


## Setup and Configuration
- **`home/directory` or `-d`**: Specifies the directory for setting up the pipeline. (single word)
    
    - Example: `baktflow setup directory /path/to/home`

### Input 

#### `single` 

For single analysis, the following flags are available:

1. **`--id` or `-i`**: Specifies the ID for a specific single analysis.
    - Example: `baktflow single --id analysis123`

2. **`--type`**: Specifies the type of analysis (e.g., short, long, assembly).
    - Options: `short`, `long`, `assembly`
    - Example: `baktflow single --id analysis123 --type short`

For single analysis, the following data types are accepted:

- **FASTQ**: Fastq file containing sequence reads.
- **FASTA**: Fasta file containing the genome sequence.

Example usage for single analysis:

- Analyzing a short-read dataset in FASTQ format:
    ```bash
    baktflow single --id analysis123 --type short --file /path/to/short_read.fastq

#### `Batch` 

For batch analyses, a TSV file containing sample information is required. The file must contain the following columns:

- `id`: sample ID
- `type`: type of sample (hybrid, long, short, etc.)
- `file_1`: path to the first FASTQ file
- `file_2`: path to the second FASTQ file (if paired-end)
- `file_3`: path to the third FASTQ file (if applicable)

Example:

| id  | type   | file_1                  | file_2                         | file_3                         |
| --- | ------ | ----------------------- | ------------------------------ | ------------------------------ |
|     | hybrid |                         | /path/to/illumina1_R1.fastq.gz | /path/to/illumina1_R2.fastq.gz |
|     | long   | /path/to/long1.fastq.gz |                                |                                |
|     | short  |                         |                                |                                |

To specify the sample file for analysis, use the following command:

Example: `baktflow batch -data path_to_input --samples batch_data.tsv`

### Output

The `output_directory` can be provided as a default location or created if not mentioned explicitly. It contains module-specific subdirectories for each sample.
```
output
├── sample_id1
│   ├── annotation_results
│   │   ├── annotation_result1.txt
│   │   ├── annotation_result2.txt
│   │   ├── assembly_results
│   │   ├── annotation_results
│   │   └── ...
│   ├── sample_report.txt
│   └── ...
├── sample_id2
│   ├── sample_report.txt
│   └── ...
```

## License



## Credits




## FAQ



