#!/usr/bin/env nextflow

process PYPOLCA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/pypolca", mode: 'copy'
    conda "${projectDir}/modules/pypolca/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }


    input:
        tuple val(meta), path(input_fasta), path(r1), path(r2)

    output:
        tuple val(meta), path("${meta.sample_id}_pypolca.fasta"), emit: short_pypolca
        tuple val(meta), path("${meta.sample_id}_pypolca.report"), emit: short_pypolca_report

    script:
    """
    pypolca run -a ${input_fasta} -1 ${r1} -2 ${r2} -o ${meta.sample_id}_pypolca --prefix ${meta.sample_id} --careful --threads $task.cpus
    mv ${meta.sample_id}_pypolca/${meta.sample_id}_corrected.fasta ${meta.sample_id}_pypolca.fasta
    mv ${meta.sample_id}_pypolca/${meta.sample_id}.report ${meta.sample_id}_pypolca.report
    """
}
