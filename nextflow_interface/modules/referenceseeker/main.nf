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
         path("${meta.sample_id}.json.gz"), emit: json

     script:
     """
     referenceseeker --bidirectional --threads ${task.cpus} ${params.databaseDir}/bacteria-refseq ${assembly} > ${meta.sample_id}.ani.tsv
     parse_referenceseeker.py ${meta.sample_id}.ani.tsv ${meta.sample_id}
     """

    stub:
    """
    touch ${meta.sample_id}.ani.tsv
    touch ${meta.sample_id}.json.gz
    """
}
