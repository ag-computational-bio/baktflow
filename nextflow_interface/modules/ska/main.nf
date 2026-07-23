#!/usr/bin/env nextflow

process SKA{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/ska", mode: 'copy'
    conda "${projectDir}/modules/ska/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("${meta.sample_id}.skf"), emit: skf

    script:
    """
    ska build -o ${meta.sample_id} ${assembly}
    """

    stub:
    """
    touch ${meta.sample_id}.skf
    """
}