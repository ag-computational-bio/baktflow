#!/usr/bin/env nextflow

process SKA{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/ska", mode: 'copy'
    conda "${projectDir}/modules/ska/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(assembly)

     output:
            tuple val(meta), path("${meta.sample_id}.skf"), emit: skf

     script:
     """
     ska fasta -o ${meta.sample_id} ${assembly}
     """

    stub:
    """
    touch ${meta.sample_id}.skf
    """
}