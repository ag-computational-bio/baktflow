#!/usr/bin/env nextflow

// Process parameters
params.filtlong_keep_percent = 80  
params.filtlong_min_length = 1000  
params.filtlong_target_bases = 500000000  

process FILTLONG {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/filtlong", mode: 'copy'
    conda "${projectDir}/modules/filtlong/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_filtered.fastq.gz"), emit: filtered_long_reads
        tuple val(meta), path("${meta.sample_id}_filtlong.log"), emit: log

    script:
    """
    filtlong \\
        --min_length ${params.filtlong_min_length} \\
        --keep_percent ${params.filtlong_keep_percent} \\
        --target_bases ${params.filtlong_target_bases} \\
        --verbose ${long_reads}\\
         2> ${meta.sample_id}_filtlong.log | gzip > ${meta.sample_id}_filtered.fastq.gz
    """
}
