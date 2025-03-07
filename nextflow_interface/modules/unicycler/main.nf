#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$baseDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/unicycler"
params.OUTPUT_DIR = "$baseDir/../output"
params.REPORT_SCRIPT = "$baseDir/nextflow/modules/unicycler/report.py"


process UNICYCLER {
    tag "$meta.sample_id"
    
    input:
    tuple val(meta), path(r1), path(r2), path(long_reads)

    output:
    tuple val(meta), path("${meta.sample_id}.fasta"), emit: scaffolds
    tuple val(meta), path("${meta.sample_id}.gfa"), emit: gfa
    tuple val(meta), path("${meta.sample_id}.log"), emit: log

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/unicycler", mode: 'copy'
    conda "${params.CONDA_ENV_PATH}"
    cpus 8
    memory '16GB'
    errorStrategy { task.attempt <= 3 ? 'retry' : 'ignore' }  // Retry up to 3 times, then ignore
    maxRetries 3  // Ensure maxRetries is set to allow up to 3 retries


    script:
    def prefix = "${meta.sample_id}"
    def long_reads_option = (long_reads && long_reads.size() > 0) ? "--long ${long_reads[0]}" : ""

    """
    unicycler --short1 ${r1} --short2 ${r2} ${long_reads_option} --out ./ --threads ${task.cpus}
        

    mv ./assembly.fasta ${prefix}_assembly.fasta
    mv ./assembly.gfa ${prefix}_assembly.gfa
    mv ./unicycler.log ${prefix}_unicycler.log

    python ${params.REPORT_SCRIPT} \\
    --fasta ${prefix}_assembly.fasta \\
    --log ${meta.sample_id}_unicycler.log \\
    --output ${params.OUTPUT_DIR}/${meta.sample_id}/unicycler
    """
}



















