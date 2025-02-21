#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/unicycler"
params.OUTPUT_DIR = "$baseDir/../output"


process UNICYCLER {
    tag "$meta.sample_id"
    
    input:
    tuple val(meta), path(r1), path(r2), path(long_reads)

    output:
    tuple val(meta), path("${meta.sample_id}_assembly.scaffolds.fa.gz"), emit: scaffolds
    tuple val(meta), path("${meta.sample_id}_assembly.graph.gfa.gz"), emit: gfa
    tuple val(meta), path("${meta.sample_id}_unicycler.log"), emit: log

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/unicycler", mode: 'copy'
    conda "${params.CONDA_ENV_PATH}"
    cpus 8
    memory '16GB'
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries


    script:
    def prefix = "${meta.sample_id}_assembly"
    def short_reads = "--short1 ${r1} --short2 ${r2}"
    def long_reads_option = (long_reads && long_reads.size() > 0) ? "--long ${long_reads[0]}" : ""

    """
    unicycler \\
        $short_reads \\
        $long_reads_option \\
        --out output \\
        --threads $task.cpus
        

    mv output/assembly.fasta ${prefix}.scaffolds.fa
    gzip -n ${prefix}.scaffolds.fa

    mv output/assembly.gfa ${prefix}.graph.gfa
    gzip -n ${prefix}.graph.gfa

    mv output/unicycler.log ${meta.sample_id}_unicycler.log
    """
}



















