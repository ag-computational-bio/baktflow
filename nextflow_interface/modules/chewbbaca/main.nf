#!/usr/bin/env nextflow

process CHEWBBACA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/chewbbaca", mode: 'copy'
    conda "${projectDir}/modules/chewbbaca/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 2 ? 2 : params.threads) }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("results/cds_coordinates.tsv"), emit: cds_coordinates
        tuple val(meta), path("results/invalid_cds.txt"), emit: invalid_cds
        tuple val(meta), path("results/loci_summary_stats.tsv"), emit: loci_summary_stats
        tuple val(meta), path("results/results_statistics.tsv"), emit: results_statistics
        tuple val(meta), path("results/results_contigsInfo.tsv"), emit: results_contigsInfo
        tuple val(meta), path("results/results_alleles.tsv"), emit: results_alleles
        tuple val(meta), path("results/paralogous_counts.tsv"), emit: paralogous_counts
        tuple val(meta), path("results/paralogous_loci.tsv"), emit: paralogous_loci
        tuple val(meta), path("results/logging_info.txt"), emit: logging_info

    script:
    """
    realpath ${assembly} > fasta_list.txt
    chewBBACA.py AlleleCall -i fasta_list.txt -g ${params.databaseDir}/chewBBACA/{species} -o ./results --cpu ${task.cpus}
    """

    stub:
    """
        mkdir -p results
        touch results/cds_coordinates.tsv
        touch results/invalid_cds.txt
        touch results/loci_summary_stats.tsv
        touch results/results_statistics.tsv
        touch results/results_contigsInfo.tsv
        touch results/results_alleles.tsv
        touch results/paralogous_counts.tsv
        touch results/paralogous_loci.tsv
        touch results/logging_info.txt
    """
}