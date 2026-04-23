#!/usr/bin/env nextflow

params.amrfinderplusdb = "${params.databaseDir}/amrfinderplus/latest"

process AMRFINDERPLUS{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/amrfinderplus", mode: 'copy'
    conda "${projectDir}/modules/amrfinderplus/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(annotation), path(prot), path(nuc)

     output:
            tuple val(meta), path("${meta.sample_id}.amrfinder.tsv"), emit: amrfinder_tsv

     script:
     """
    amrfinder --nucleotide ${nuc} --protein ${prot} --gff ${annotation} --annotation_format bakta --output ${meta.sample_id}.amrfinder.tsv --name ${meta.sample_id} --plus --threads ${task.cpus} --database ${params.amrfinderplusdb}

     """

    stub:
    """
    touch ${meta.sample_id}.amrfinder.tsv
    """
}