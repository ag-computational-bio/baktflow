#!/usr/bin/env nextflow

process ECTYPER{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/ectyper", mode: 'copy'
    conda "${projectDir}/modules/ectyper/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(assembly)

     output:
            tuple val(meta), path("output.tsv"), emit: tsv
            tuple val(meta), path("ectyper.log"), emit: log
            tuple val(meta), path("blastn_output_alleles.txt"), emit: blast

     script:
     """
     ectyper -i ${assembly} -o ./ -c ${task.cpus}

     """

    stub:
    """
    touch output.csv
    touch ectyper.log
    touch blast_output_alleles.txt
    """
}