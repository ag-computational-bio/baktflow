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
        tuple val(meta), path("${meta.sample_id}.genes.tsv"), emit: genes
        tuple val(meta), path("${meta.sample_id}.features.tsv"), emit: features
        tuple val(meta), path("${meta.sample_id}.clusters.tsv"), emit: clusters
        tuple val(meta), path("${meta.sample_id}.*.gbk"), emit: genbank
        path("${meta.sample_id}.json.gz"), emit: json

    script:
    """
    gecco run -j ${task.cpus} --genome ${genbank} --cds-feature CDS --merge-gbk --output ./
    parse_gecco.py ${meta.sample_id}.genes.tsv ${meta.sample_id}.features.tsv ${meta.sample_id}.clusters.tsv ${meta.sample_id}
    """

    stub:
    """
    touch ${meta.sample_id}.genes.tsv
    touch ${meta.sample_id}.features.tsv
    touch ${meta.sample_id}.clusters.tsv
    touch ${meta.sample_id}.1.gbk
    touch ${meta.sample_id}.json.gz
    """
}
