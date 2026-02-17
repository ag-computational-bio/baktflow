#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/fastp"
params.OUTPUT_DIR = "$baseDir/../output"



process FASTP {
    tag "$meta.sample_id"
    input:
    tuple val(meta), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.sample_id}_R1_processed.fastq.gz"), path("${meta.sample_id}_R2_processed.fastq.gz"), emit: processed_reads
    tuple val(meta), path('*.json'), emit: json
    tuple val(meta), path('*.html'), emit: html
    errorStrategy 'retry'  // Retry on failure
    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/fastp", mode: 'copy'
    conda "${params.CONDA_ENV_PATH}"
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries
    cpus (params.threads >= 2 ? 2 : params.threads)
    memory {1.GB * task.attempt}

    script:
    """
    fastp --in1 ${r1} --in2 ${r2} --out1 ${meta.sample_id}_R1_processed.fastq.gz --out2 ${meta.sample_id}_R2_processed.fastq.gz --thread  $task.cpus
    """
}





















