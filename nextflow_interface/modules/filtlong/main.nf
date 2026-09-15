#!/usr/bin/env nextflow

process FILTLONG {
    tag "$meta.sample_id"
    // publishDir "${params.output}/${meta.sample_id}/filtlong", mode: 'copy'
    conda "${projectDir}/modules/filtlong/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }

    input:
        tuple val(meta), val(genome_size), val(coverage), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_filtered.fastq.gz"), emit: filtered_long_reads
        tuple val(meta), val('filtlong'), path("${meta.sample_id}_filtered.fastq.gz"), emit: report

    script:
    def adjusted_genome_size = ( genome_size.toInteger() == 1 ) ? "500000000 --keep_percent 95" : "${genome_size}00"

    if ( meta.sample_type.startsWith("meta") )
        """
        filtlong --min_length 500 --keep_percent 95 ${long_reads} | gzip -c > ${meta.sample_id}_filtered.fastq.gz
        """
    else
        """
        filtlong --min_length 500 --target_bases ${adjusted_genome_size} --length_weight 0 --window_q_weight 0 ${long_reads} | \
        gzip -c > ${meta.sample_id}_filtered.fastq.gz
        """

    stub:
    """
    touch ${meta.sample_id}_filtered.fastq.gz
    """
}
