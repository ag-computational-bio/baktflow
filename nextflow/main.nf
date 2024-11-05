#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Define parameters with default values
params.INPUT_TSV = params.INPUT_TSV ?: 'input.tsv'
params.OUTPUT_DIR = params.OUTPUT_DIR ?: '.'
params.BASE_PATH = params.BASE_PATH ?: '.'


// Include the FastQC analysis module
include { FASTQC_ANALYSIS } from './modules/fastqc/main.nf'
include { FASTP_ANALYSIS } from './modules/fastp/main.nf'  

log.info """
    BAKTFLOW   P I P E L I N E
    ===================================
    input_tsv    : ${params.INPUT_TSV}
    output_dir   : ${params.OUTPUT_DIR}
    base_path    : ${params.BASE_PATH}
""".stripIndent()
// Main Workflow
workflow {
    // Read the input TSV and prepare the input channel
    Channel.fromPath(file(params.INPUT_TSV))
        .splitCsv(header: false, sep: '\t')
        .flatMap { row ->
            def sample_ID = row[0]  // Sample ID
            def sample_type = row[1] // Sample type

            // Ensure that the files are correctly assigned based on the type
            def r1_file = row[2] ? file("${params.BASE_PATH}/${row[2].trim()}") : null
            def r2_file = row[3] ? file("${params.BASE_PATH}/${row[3].trim()}") : null
            def long_file = row[4] ? file("${params.BASE_PATH}/${row[4].trim()}") : null

            // Create a list to hold file maps
            def file_maps = []
            
            // Create a hashmap for each file, storing sample ID, file type, and file path
            if (r1_file) {
                file_maps << [sample_ID: sample_ID, file_type: 'R1', file_path: r1_file]
            }
            if (r2_file) {
                file_maps << [sample_ID: sample_ID, file_type: 'R2', file_path: r2_file]
            }
            if (long_file) {
                file_maps << [sample_ID: sample_ID, file_type: 'Long', file_path: long_file]
            }

            // Return the list of file maps
            return file_maps
        }
        .flatten()  // Ensure that we get a flattened list of file maps
        .set { INPUT_CHANNEL }  // Set the input channel

    // View the contents of the input channel for debugging
    INPUT_CHANNEL.view()

    // Pass the input channel to the FastQC and FastP processes
    INPUT_CHANNEL | FASTQC_ANALYSIS
    INPUT_CHANNEL | FASTP_ANALYSIS
}






