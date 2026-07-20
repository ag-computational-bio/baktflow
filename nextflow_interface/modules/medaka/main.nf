#!/usr/bin/env nextflow

process MEDAKA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/medaka", mode: 'copy'
    conda "${projectDir}/modules/medaka/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(long_reads), path(scaffolds)

    output:
        tuple val(meta), path("${meta.sample_id}_polished_assembly.fasta"), emit: fasta
        path("${meta.sample_id}.json.gz"), emit: json

    script:
    """
    medaka_consensus -i ${long_reads} -d ${scaffolds} -o ./ -t ${task.cpus} --bacteria || \
    medaka_consensus -i ${long_reads} -d ${scaffolds} -o ./ -t ${task.cpus}

    mv consensus.fasta ${meta.sample_id}_polished_assembly.fasta

    parse_assembly.py ${meta.sample_id}_polished_assembly.fasta ${meta.sample_id} medaka
    """

    stub:
    """
    touch ${meta.sample_id}_polished_assembly.fasta
    touch ${meta.sample_id}.json.gz
    """
}
