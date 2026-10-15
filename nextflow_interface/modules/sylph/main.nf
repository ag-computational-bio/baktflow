#!/usr/bin/env nextflow

process SYLPH {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/sylph", pattern: "*.log", mode: 'copy'
    conda "${projectDir}/modules/sylph/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("profiling.tsv"), emit: taxonomy

    script:
    """
    sylph profile -d ${params.databaseDir}/sylph/globdb_r232_sylph_v2_c200.syl2db -r ${long_reads} -t ${task.cpus} -o profiling.tsv
    """

    stub:
    """
    touch profiling.tsv
    """
}
