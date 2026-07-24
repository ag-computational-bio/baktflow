#!/usr/bin/env nextflow

process CHEWBBACA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/chewbbaca", mode: 'copy'
    conda "${projectDir}/modules/chewbbaca/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 2 ? 2 : params.threads) }

    input:
        tuple val(meta), path(assembly), val(organism)

    output:
        tuple val(meta), path("cds_coordinates.tsv"), emit: cds_coordinates
        tuple val(meta), path("invalid_cds.txt"), emit: invalid_cds
        tuple val(meta), path("loci_summary_stats.tsv"), emit: loci_summary_stats
        tuple val(meta), path("results_statistics.tsv"), emit: results_statistics
        tuple val(meta), path("results_contigsInfo.tsv"), emit: results_contigsInfo
        tuple val(meta), path("results_alleles.tsv"), emit: results_alleles
        tuple val(meta), path("paralogous_counts.tsv"), emit: paralogous_counts
        tuple val(meta), path("paralogous_loci.tsv"), emit: paralogous_loci
        tuple val(meta), path("logging_info.txt"), emit: logging_info

    script:
    """
    realpath ${assembly} > fasta_list.txt
    chewBBACA.py AlleleCall --no-inferred -i fasta_list.txt -o ./results --cpu ${task.cpus} -g ${params.databaseDir}/chewBBACA/${organism}
    mv results/* ./
    rm -r results/
    parse_chewbbaca.py cds_coordinates.tsv loci_summary_stats.tsv results_contigsInfo.tsv results_alleles.tsv paralogous_loci.tsv ${meta.sample_id}
    """

    stub:
    """
        touch cds_coordinates.tsv
        touch invalid_cds.txt
        touch loci_summary_stats.tsv
        touch results_statistics.tsv
        touch results_contigsInfo.tsv
        touch results_alleles.tsv
        touch paralogous_counts.tsv
        touch paralogous_loci.tsv
        touch logging_info.txt
    """
}