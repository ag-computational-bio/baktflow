#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Define parameters with default values
params.INPUT_TSV = params.INPUT_TSV ?: 'input_files.tsv'
params.OUTPUT_DIR = params.OUTPUT_DIR ?: '.'
params.BASE_PATH = params.BASE_PATH ?: '.'


include { SETUP_FASTQC } from './modules/fastqc/setup.nf'


println """\
          BAKTFLOW   P I P E L I N E
         ===================================
         input_tsv    : ${params.INPUT_TSV}
         output_dir   : ${params.OUTPUT_DIR}
         conda_env    : ${params.CONDA_ENV_PATH}
         base_path    : ${params.BASE_PATH}
         """
         .stripIndent()

// Define the input channel from the TSV file
Channel
    .fromPath(params.INPUT_TSV)
    .splitCsv(header: false, sep: '\t')  // Read TSV file without header
    .map { row ->
        def id = row.size() > 0 ? row[0] : null
        def type = row.size() > 1 ? row[1] : null
        
        // Collect all non-null and non-empty files starting from column 2 onward
        def files = row[2..-1].findAll { it != null && it.trim() }

        // Convert to file paths and ensure each is trimmed properly
        def file_paths = files.collect { file("${params.BASE_PATH}/${it.trim()}") }

        // Debugging: Print sample ID and file paths
        println "Sample ID: ${id}, File paths: ${file_paths*.toString()}"

        // Return structured output for Nextflow processing
        return [id, type, file_paths]
    }
    .set { INPUT_CHANNEL }

// Define the workflow
workflow {
    // Run FASTQC analysis on parsed input
    fastqc_results = FASTQC_ANALYSIS(INPUT_CHANNEL)

    
}