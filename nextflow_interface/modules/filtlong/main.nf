#!/usr/bin/env nextflow

process FILTLONG {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/filtlong", mode: 'copy'
    conda "${projectDir}/modules/filtlong/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_filtered.fastq.gz"), emit: filtered_long_reads

    script:
    """
    filtlong --min_length 1000 --keep_percent 95 --target_bases 500000000 \
    ${long_reads} | gzip -c > ${meta.sample_id}_filtered.fastq.gz
    """

    stub:
    """
    touch ${meta.sample_id}_filtered.fastq.gz
    """
}
