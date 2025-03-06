#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/fastqc"
params.REPORT_SCRIPT = "$baseDir/modules/fastqc/report.py"
params.OUTPUT_DIR = "$baseDir/../output"

// FastQC Process
process FASTQC {
    tag { meta.sample_id }
    label 'fastqc'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${reads.baseName}_fastqc.html"), emit: html
    tuple val(meta), path("${reads.baseName}_fastqc.zip"), emit: zip

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/fastqc", mode: 'copy'

    conda "${params.CONDA_ENV_PATH}"
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries 
    cpus 8
    memory '16GB'

    script:
    """
    mkdir -p fastqc
    fastqc ${reads} -o fastqc
    cp fastqc/*_fastqc.html ${reads.baseName}_fastqc.html
    cp fastqc/*_fastqc.zip ${reads.baseName}_fastqc.zip
    # Run report.py with correct arguments
    python ${params.REPORT_SCRIPT} --zip ${reads.baseName}_fastqc.zip --output ${params.OUTPUT_DIR}/${meta.sample_id}/fastqc
    """
}




















