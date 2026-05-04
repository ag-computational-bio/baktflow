#!/usr/bin/env nextflow

params.gtdbtkdb = "${params.databaseDir}/gtdbtk_db"

process GTDBTK{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/gtdbtk", mode: 'copy'
    conda "${projectDir}/modules/gtdbtk/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 128.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(assembly)

     output:
            tuple val(meta), path("${meta.sample_id}.gtdbtk.tsv"), emit: tsv

     script:
     """
     export GTDBTK_DATA_PATH="${params.gtdbtkdb}"
     mkdir genomes/
     mv ${assembly} genomes/
     gtdbtk classify_wf --genome_dir genomes/ --out_dir . --pplacer_cpus ${task.cpus} --cpus ${task.cpus} --extension fasta
     mv classify/gtdbtk.bac120.summary.tsv ${meta.sample_id}.gtdbtk.tsv
     """

    stub:
    """
    touch ${meta.sample_id}.gtdbtk.tsv
    """
}