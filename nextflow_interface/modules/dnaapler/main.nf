#!/usr/bin/env nextflow

process DNAAPLER {
    publishDir "${params.output}/${meta.sample_id}/dnaapler", mode: 'copy'
    conda "${projectDir}/modules/dnaapler/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 2.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(gfa)

    output:
        tuple val(meta), path("${meta.sample_id}_reoriented.gfa"), emit: gfa
        tuple val(meta), path("${meta.sample_id}_reoriented.fasta"), emit: fasta
        tuple val(meta), val('dnaapler'), path("${meta.sample_id}_reoriented.fasta"), emit: report

    script:
    """
    dnaapler all --prefix ${meta.sample_id} --input ${gfa} --output out --threads $task.cpus

    mv out/${meta.sample_id}_reoriented.* ./
    rm -r out
    """

    stub:
    """
    touch ${meta.sample_id}_reoriented.gfa
    touch ${meta.sample_id}_reoriented.fasta
    """
}
