#!/usr/bin/env nextflow

process ANTISMASH {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/antismash/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/antismash", mode: 'copy'
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(assemlby), path(gff3)

    output:
        tuple val(meta), path("${meta.sample_id}.genes.tsv"), emit: genes
        tuple val(meta), path("${meta.sample_id}.features.tsv"), emit: features
        tuple val(meta), path("${meta.sample_id}.clusters.tsv"), emit: clusters
        tuple val(meta), path("${meta.sample_id}.*.gbk"), emit: genbank

    script:
    """
    mkdir res
    antismash ${assemlby} --genefinding-gff3 ${gff3} --taxon bacteria --output-basename ${meta.sample_id} --output-dir ./res/ --databases ${params.databaseDir}/antismash --cpus ${task.cpus}
    """

    stub:
    """
    touch ${meta.sample_id}.genes.tsv
    touch ${meta.sample_id}.features.tsv
    touch ${meta.sample_id}.clusters.tsv
    touch ${meta.sample_id}.1.gbk
    """
}
