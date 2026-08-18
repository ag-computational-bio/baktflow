#!/usr/bin/env nextflow

process POLYPOLISH {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/polypolish", mode: 'copy'
    conda "${projectDir}/modules/polypolish/environment.yaml"
    errorStrategy { task.exitStatus == 101 ? 'ignore' : 'retry' }
    memory { workflow.stubRun ? 64.MB : 4.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(short_pypolca), path(r1), path(r2), path(se)

    output:
        tuple val(meta), path("${meta.sample_id}_polypolish.fasta"), emit: polished_output
        tuple val(meta), val('polypolish'), path("${meta.sample_id}_polypolish.fasta"), emit: report

    script:
    """
    minibwa index ${short_pypolca}
    minibwa map -t $task.cpus -N 1000 --outn=1000 ${short_pypolca} ${r1} > alignments_1.sam
    minibwa map -t $task.cpus -N 1000 --outn=1000 ${short_pypolca} ${r2} > alignments_2.sam
    if [ \$(wc -l ${se}) -gt 0 ]; then
        minibwa map -t $task.cpus -N 1000 --outn=1000 ${short_pypolca} ${se} > alignments_se.sam
    fi
    rm *.l2b *.mbw

    polypolish filter --in1 alignments_1.sam --in2 alignments_2.sam --out1 filtered_1.sam --out2 filtered_2.sam
    if [ \$(wc -l ${se}) -gt 0 ]; then
        polypolish polish ${short_pypolca} filtered_1.sam filtered_2.sam alignments_se.sam > ${meta.sample_id}_polypolish.fasta
    else
        polypolish polish ${short_pypolca} filtered_1.sam filtered_2.sam > ${meta.sample_id}_polypolish.fasta
    fi
    rm *.sam
    """

    stub:
    """
    touch ${meta.sample_id}_polypolish.fasta
    """
}
