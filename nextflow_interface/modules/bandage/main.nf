#!/usr/bin/env nextflow


process BANDAGE{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/bandage", mode: 'copy'
    conda "${projectDir}/modules/bandage/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(assembly)

     output:
            tuple val(meta), path("${meta.sample_id}.svg"), emit: svg

     script:
     """
     Bandage image ${assembly} ${meta.sample_id}.svg
     """

    stub:
    """
    touch ${meta.sample_id}.svg
    """
}