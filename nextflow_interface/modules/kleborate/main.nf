#!/usr/bin/env nextflow

process KLEBORATE {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/kleborate", mode: 'copy'
    conda "${projectDir}/modules/kleborate/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("*_output.txt"), emit: txt
        tuple val(meta), val('kleborate'), path("*_output.txt"), emit: report

    script:
    """
    kleborate -a ${assembly} -o ./ -p kpsc --trim_headers
    """

    stub:
    """
    touch klebsiella_pneumo_complex_output.txt
    """
}