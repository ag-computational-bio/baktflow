#!/usr/bin/env nextflow

process NANOLYSE {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/nanolyse/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_filtered.fastq.gz"), emit: filtered_reads
        tuple val(meta), val('nanolyse'), path("${meta.sample_id}_filtered.fastq.gz"), emit: report

    script:
    """
    pigz -dck ${long_reads} | NanoLyse | pigz -9 -p ${task.cpus} > ${meta.sample_id}_filtered.fastq.gz
    """

    stub:
    """
    touch ${meta.sample_id}_filtered.fastq.gz
    """
}
