#!/usr/bin/env nextflow

process PLASMIDFINDER{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/plasmidfinder", mode: 'copy'
    conda "${projectDir}/modules/plasmidfinder/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 512.MB * task.attempt }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("results_tab.tsv"), emit: tsv, optional: true
        tuple val(meta), path("results.txt"), emit: txt, optional: true
        tuple val(meta), path("data.json"), emit: json
        tuple val(meta), path("Hit_in_genome_seq.fsa"), emit: hits, optional: true
        tuple val(meta), path("Plasmid_seqs.fsa"), emit: plasmid_seqs, optional: true

    script:
    """
    plasmidfinder.py -i ${assembly} -o ./
    """

    stub:
    """
    touch data.json
    """
}