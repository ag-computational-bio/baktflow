#!/usr/bin/env nextflow

process GECCO {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/gecco/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/gecco", mode: 'copy'
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(genbank)

    output:
        tuple val(meta), path("${meta.sample_id}.genes.tsv"), emit: genes, optional: true
        tuple val(meta), path("${meta.sample_id}.features.tsv"), emit: features, optional: true
        tuple val(meta), path("${meta.sample_id}.clusters.tsv"), emit: clusters, optional: true
        tuple val(meta), path("${meta.sample_id}.*.gbk"), emit: genbank, optional: true

    script:
    """
    gecco run -j ${task.cpus} --genome ${genbank} --cds-feature CDS --merge-gbk --output ./
    """

    stub:
    """
    touch ${meta.sample_id}.genes.tsv
    touch ${meta.sample_id}.features.tsv
    touch ${meta.sample_id}.clusters.tsv
    touch ${meta.sample_id}.1.gbk
    """
}
