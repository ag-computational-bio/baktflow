#!/usr/bin/env nextflow

process MOB_SUITE{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/mob_suite", mode: 'copy'
    conda "${projectDir}/modules/mob_suite/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("results/${meta.sample_id}.contig_report.txt"), emit: contig_report
        tuple val(meta), path("results/${meta.sample_id}.mge_report.txt"), emit: mge_report
        tuple val(meta), path("results/${meta.sample_id}.chromosome.fasta"), emit: chromosome_fasta
        tuple val(meta), path("results/${meta.sample_id}.plasmid_*.fasta"), emit: plasmids

    script:
    """
    mob_recon --infile ${assembly} --num_threads ${task.cpus} --outdir results --prefix ${meta.sample_id} -d ${params.databaseDir}/mob_suite
    """

    stub:
    """
    mkdir -p results
    touch results/${meta.sample_id}.mge_report.txt
    touch results/${meta.sample_id}.contig_report.txt
    touch results/${meta.sample_id}.chromosome.fasta
    touch results/${meta.sample_id}.plasmid_XX.fasta
    """

}