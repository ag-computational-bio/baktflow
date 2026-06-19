#!/usr/bin/env nextflow

process GTDBTK{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/gtdbtk", mode: 'copy', pattern: "*.gtdbtk.tsv"
    conda "${projectDir}/modules/gtdbtk/environment.yaml"
    scratch true
    memory { workflow.stubRun ? 64.MB : 150.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

     input:
         tuple val(meta), path("genomes/*")

     output:
         tuple val(meta), path("${meta.sample_id}.gtdbtk.tsv"), emit: tsv
         tuple val(meta), path("tax.txt"), emit: tax
         path("${meta.sample_id}.json"), emit: json

     script:
     """
     export GTDBTK_DATA_PATH="${params.databaseDir}/gtdbtk_db"
     gtdbtk classify_wf --genome_dir genomes/ --out_dir . --pplacer_cpus ${task.cpus} --cpus ${task.cpus} --extension fasta
     mv classify/gtdbtk.bac120.summary.tsv ${meta.sample_id}.gtdbtk.tsv
     cut -f 2 ${meta.sample_id}.gtdbtk.tsv | tail -n 1 > tax.txt
     parse_gtdbtk.py ${meta.sample_id}.gtdbtk.tsv ${meta.sample_id}
     """

    stub:
    """
    touch ${meta.sample_id}.gtdbtk.tsv
    touch ${meta.sample_id}.json
    """
}