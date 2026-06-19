#!/usr/bin/env nextflow

process AMRFINDERPLUS{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/amrfinderplus", mode: 'copy'
    conda "${projectDir}/modules/amrfinderplus/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

     input:
         tuple val(meta), path(annotation), path(prot), path(nuc)

     output:
         tuple val(meta), path("${meta.sample_id}.amrfinder.tsv"), emit: amrfinder_tsv
         path("${meta.sample_id}.json.gz"), emit: json


     script:
     """
     amrfinder --nucleotide ${nuc} --protein ${prot} --gff ${annotation} --annotation_format bakta \
     --output ${meta.sample_id}.amrfinder.tsv --name ${meta.sample_id} --plus --threads ${task.cpus} \
     --database ${params.databaseDir}/amrfinderplus/latest
     parse_amrfinder.py ${meta.sample_id}.amrfinder.tsv ${meta.sample_id}
     """

    stub:
    """
    touch ${meta.sample_id}.amrfinder.tsv
    touch ${meta.sample_id}.json.gz
    """
}