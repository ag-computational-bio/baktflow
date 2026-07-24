#!/usr/bin/env nextflow

process RGI{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/rgi", mode: 'copy'
    conda "${projectDir}/modules/rgi/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 4.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("${meta.sample_id}.card.txt"), emit: card_txt
        tuple val(meta), path("${meta.sample_id}.card.json"), emit: card_json

    script:
    """
    rgi main -i ${assembly} --output_file ${meta.sample_id}.card --input_type contig --data wgs --orf_finder PYRODIGAL --alignment_tool DIAMOND --threads ${task.cpus}
    """

    stub:
    """
    touch ${meta.sample_id}.card.txt
    touch ${meta.sample_id}.card.json
    """
}