#!/usr/bin/env nextflow

process POLYPOLISH {
    input:
    tuple val(meta), path(short_pypolca), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.sample_id}_polypolish.fasta"), emit:polished_output
    publishDir "${params.output}/${meta.sample_id}/polypolish", mode: 'copy'

    conda "${projectDir}/modules/polypolish/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 8 ? 8 : params.threads)
        memory {16.GB * task.attempt}
    }

    script:
    """
    # Step 1: Index the draft genome
    bwa index ${short_pypolca}

    # Step 2: Align short reads separately
    bwa mem -t $task.cpus -a ${short_pypolca} ${r1} > alignments_1.sam
    bwa mem -t $task.cpus -a ${short_pypolca} ${r2} > alignments_2.sam

    # Step 3: Filter low-quality alignments
    polypolish filter --in1 alignments_1.sam --in2 alignments_2.sam --out1 filtered_1.sam --out2 filtered_2.sam

    # Step 4: Perform polishing with high-quality alignments
    polypolish polish ${short_pypolca} filtered_1.sam filtered_2.sam > polished.fasta

    # Rename output
    mv polished.fasta ${meta.sample_id}_polypolish.fasta
    """
}
