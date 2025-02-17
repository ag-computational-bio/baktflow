#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/pypolca"
params.OUTPUT_DIR = "$baseDir/../output"

process PYPOLCA {
    input:
    tuple val(meta), path(input_fasta), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.sample_id}_pypolca.fasta"), emit: short_pypolca
    tuple val(meta), path("${meta.sample_id}_pypolca.report"), emit: short_pypolca_report

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/pypolca", mode: 'copy'
    conda "${params.CONDA_ENV_PATH }"
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries


    script:
    """
    pypolca run -a ${input_fasta} -1 ${r1} -2 ${r2} -o ${meta.sample_id}_pypolca --prefix ${meta.sample_id}
    mv ${meta.sample_id}_pypolca/${meta.sample_id}_corrected.fasta ${meta.sample_id}_pypolca.fasta
    mv ${meta.sample_id}_pypolca/${meta.sample_id}.report ${meta.sample_id}_pypolca.report
    """
}
























