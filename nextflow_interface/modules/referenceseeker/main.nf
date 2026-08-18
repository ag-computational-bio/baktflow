#!/usr/bin/env nextflow

process REFERENCESEEKER{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/referenceseeker", mode: 'copy'
    conda "${projectDir}/modules/referenceseeker/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
         tuple val(meta), path(assembly)

     output:
         tuple val(meta), path("${meta.sample_id}.ani.tsv"), emit: ani_tsv
         tuple val(meta), val('referenceseeker'), path("${meta.sample_id}.ani.tsv"), emit: report

     script:
     """
     referenceseeker --bidirectional --threads ${task.cpus} ${params.databaseDir}/bacteria-refseq ${assembly} > ${meta.sample_id}.ani.tsv
     """

    stub:
    """
    touch ${meta.sample_id}.ani.tsv
    """
}
