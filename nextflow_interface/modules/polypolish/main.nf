#!/usr/bin/env nextflow

process POLYPOLISH {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/polypolish", mode: 'copy'
    conda "${projectDir}/modules/polypolish/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 4.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(short_pypolca), path(r1), path(r2), path(se)

    output:
        tuple val(meta), path("${meta.sample_id}_polypolish.fasta"), emit: polished_output
        path("${meta.sample_id}.json.gz"), emit: json

    script:
    """
    bwa index ${short_pypolca}
    bwa mem -t $task.cpus -a ${short_pypolca} ${r1} > alignments_1.sam
    bwa mem -t $task.cpus -a ${short_pypolca} ${r2} > alignments_2.sam
    bwa mem -t $task.cpus -a ${short_pypolca} ${se} > alignments_se.sam

    polypolish filter --in1 alignments_1.sam --in2 alignments_2.sam --out1 filtered_1.sam --out2 filtered_2.sam
    polypolish polish ${short_pypolca} filtered_1.sam filtered_2.sam alignments_se.sam > ${meta.sample_id}_polypolish.fasta

    parse_assembly.py ${meta.sample_id}_polypolish.fasta ${meta.sample_id} polypolish
    """

    stub:
    """
    touch ${meta.sample_id}_polypolish.fasta
    touch ${meta.sample_id}.json.gz
    """
}
