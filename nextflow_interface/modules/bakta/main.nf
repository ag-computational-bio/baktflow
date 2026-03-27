#!/usr/bin/env nextflow

params.baktaDb = "${params.databaseDir}/bakta/db-${params.baktaDbType}"

process BAKTA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/bakta", mode: 'copy'
    conda "${projectDir}/modules/bakta/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.sample_id}.embl"), emit: embl
    tuple val(meta), path("${meta.sample_id}.faa"), emit: faa
    tuple val(meta), path("${meta.sample_id}.ffn"), emit: ffn
    tuple val(meta), path("${meta.sample_id}.fna"), emit: fna
    tuple val(meta), path("${meta.sample_id}.gbff"), emit: gbff
    tuple val(meta), path("${meta.sample_id}.gff3"), emit: gff
    tuple val(meta), path("${meta.sample_id}.hypotheticals.tsv"), emit: hypotheticals_tsv
    tuple val(meta), path("${meta.sample_id}.hypotheticals.faa"), emit: hypotheticals_faa
    tuple val(meta), path("${meta.sample_id}.tsv"), emit: tsv
    tuple val(meta), path("${meta.sample_id}.txt"), emit: txt

    script:
    """
    # Run Bakta
    bakta --db "${params.baktaDb}" --prefix ${meta.sample_id} --output ./ --threads $task.cpus ${assembly}
    """
}
