#!/usr/bin/env nextflow

process ANTISMASH {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/antismash/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/antismash", mode: 'copy'
    memory { workflow.stubRun ? 64.MB : 1.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(assembly), path(gbff)

    output:
        tuple val(meta), path("${meta.sample_id}.gbk"), emit: genbank
        tuple val(meta), path("${meta.sample_id}.json"),emit: json
        tuple val(meta), path("index.html"), emit: html

    script:
    """
    mkdir res
    antismash ${gbff} --taxon bacteria --output-basename ${meta.sample_id} --output-dir ./res/ --databases ${params.databaseDir}/antismash --cpus ${task.cpus}
    mv res/* ./
    """

    stub:
    """
    touch ${meta.sample_id}.gbk
    touch ${meta.sample_id}.json
    touch index.html
    """
}
