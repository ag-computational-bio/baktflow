#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/flye"
params.OUTPUT_DIR = "$baseDir/../output"

process FLYE {
    input:
    tuple val(meta), path(filtered_long_reads)

    output:
    tuple val(meta), path("${meta.sample_id}_assembly.fasta"), emit: scaffolds
    tuple val(meta), path("${meta.sample_id}_assembly_graph.gfa"), emit: graph
    tuple val(meta), path("${meta.sample_id}_assembly_info.txt"), emit: info

    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 8 ? 8 : params.threads)
        memory {16.GB * task.attempt}
    }

    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries

    script:
    """
    flye --pacbio-raw ${filtered_long_reads} --genome-size 4.6m --out-dir flye_output --threads ${task.cpus}

    cp flye_output/assembly.fasta ${meta.sample_id}_assembly.fasta
    cp flye_output/assembly_graph.gfa ${meta.sample_id}_assembly_graph.gfa
    cp flye_output/assembly_info.txt ${meta.sample_id}_assembly_info.txt
    """
}
























