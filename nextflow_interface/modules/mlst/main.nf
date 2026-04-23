#!/usr/bin/env nextflow

process MLST{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/mlst", mode: 'copy'
    conda "${projectDir}/modules/mlst/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(assembly)

     output:
            tuple val(meta), path("${meta.sample_id}.json"), emit: json
            tuple val(meta), path("${meta.sample_id}.mlst.tsv"), emit: mlst_tsv

     script:
     """
     mlst --json ${meta.sample_id}.json --label ${meta.sample_id} --mincov 80 ${assembly} > ${meta.sample_id}.mlst.tsv
     """

    stub:
    """
    touch ${meta.sample_id}.json
    touch ${meta.sample_id}.mlst.tsv
    """
}