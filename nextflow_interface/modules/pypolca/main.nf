#!/usr/bin/env nextflow

process PYPOLCA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/pypolca", mode: 'copy'
    conda "${projectDir}/modules/pypolca/environment.yaml"
    memory { workflow.stubRun ? 1.GB : 2.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }


    input:
        tuple val(meta), path(input_fasta), path(r1), path(r2)

    output:
        tuple val(meta), path("${meta.sample_id}_pypolca.fasta"), emit: short_pypolca
        tuple val(meta), path("${meta.sample_id}_pypolca.report"), emit: short_pypolca_report

    script:
    """
    MEM=\$(echo $task.memory | awk '{print \$1"G"}')
    pypolca run -a ${input_fasta} -1 ${r1} -2 ${r2} -o out --prefix ${meta.sample_id} --careful --threads $task.cpus --memory_limit \$MEM
    mv out/${meta.sample_id}_corrected.fasta ${meta.sample_id}_pypolca.fasta
    mv out/${meta.sample_id}.report ${meta.sample_id}_pypolca.report
    rm -r out
    """

    stub:
    """
    touch ${meta.sample_id}_pypolca.fasta
    touch ${meta.sample_id}_pypolca.report
    """
}
