#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Define parameters with default values
params.INPUT_TSV = params.INPUT_TSV ?: 'input_files.tsv'
params.OUTPUT_DIR = params.OUTPUT_DIR ?: '.'
params.BASE_PATH = params.BASE_PATH ?: '.'
params.CONDA_ENV_DIR = params.CONDA_ENV_DIR ?: "./setup/conda_envs"

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
    .splitCsv(header: false, sep: '\t')
    .map { row ->
        def id = row[0]
        def type = row[1]
        def file_1 = row.size() > 2 && row[2] ? file("${params.BASE_PATH}/${row[2]}") : null
        def file_2 = row.size() > 3 && row[3] ? file("${params.BASE_PATH}/${row[3]}") : null
        def file_3 = row.size() > 4 && row[4] ? file("${params.BASE_PATH}/${row[4]}") : null
        return [id, type, [file_1, file_2, file_3].findAll { it != null }]
    }
    .filter { row ->
        // Ensure at least one file path is not null
        def (id, type, files) = row
        return files.size() > 0
    }
    .set { INPUT_CHANNEL }





// Define the workflow
workflow {
    // Run FASTQC analysis on parsed input
    fastqc_results = FASTQC_ANALYSIS(INPUT_CHANNEL)

    // Pass the output directory from fastqcAnalysis to getVersionInfo
    GET_VERSION_FASTQC(fastqc_results)
}