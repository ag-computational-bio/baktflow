#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/fastqc"

// FastQC Process
process FASTQC_ANALYSIS {
    tag { file_map.sample_ID }
    label 'fastqc'  
    
    // Set the retry strategy to handle transient errors
    errorStrategy 'retry'
    maxRetries 3
    
    input:
    val(file_map)  // Expecting a hashmap as input

    output:
    tuple val(file_map.sample_ID), file('fastqc/*'), val(file_map)

    publishDir "${params.OUTPUT_DIR}/${file_map.sample_ID}/${file_map.file_type}", mode: 'copy'

    script:
    """
    mkdir -p fastqc
    fastqc ${file_map.file_path} -o fastqc

    # Log the metadata (for debugging)
    echo "Running FastQC on ${file_map.file_type} for sample: ${file_map.sample_ID}"
    """
}















