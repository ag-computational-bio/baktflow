#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/filtlong"
params.OUTPUT_DIR = "$baseDir/../output"

// Process parameters
params.filtlong_keep_percent = 80  
params.filtlong_min_length = 1000  
params.filtlong_target_bases = 500000000  

// Process for FiltLong (long reads)
process FILTLONG {
    input:
    tuple val(meta), path(long_reads)

    output:
    tuple val(meta), path("${meta.sample_id}_filtered.fastq.gz"), emit: filtered_long_reads
    tuple val(meta), path("${meta.sample_id}_filtlong.log"), emit: log

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/filtlong", mode: 'copy'
    conda "${params.CONDA_ENV_PATH}"

    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries
    cpus 8
    memory '1GB'

    script:
    """
    # Run filtlong with configurable parameters
    filtlong \\
        --min_length ${params.filtlong_min_length} \\
        --keep_percent ${params.filtlong_keep_percent} \\
        --target_bases ${params.filtlong_target_bases} \\
        --verbose ${long_reads} 2> ${meta.sample_id}_filtlong.log | gzip > ${meta.sample_id}_filtered.fastq.gz
    """
}
















