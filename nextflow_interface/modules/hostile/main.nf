#!/usr/bin/env nextflow

process HOSTILE {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/hostile/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 32 ? 32 : params.threads) }
    scratch true

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_depleted.fastq.gz"), emit: depleted_reads
        tuple val(meta), val('hostile'), path("${meta.sample_id}_depleted.fastq.gz"), emit: report

    script:
    """
    export HOSTILE_CACHE_DIR="${params.databaseDir}/hostile"

    hostile clean --fastq1 ${long_reads} --output - --index human-t2t-hla-argos985-mycob140 --airplane --aligner minimap2 --threads ${task.cpus} | \
    pigz -9 -p ${task.cpus} > ${meta.sample_id}_depleted.fastq.gz
    """

    stub:
    """
    touch ${meta.sample_id}_depleted.fastq.gz
    """
}
