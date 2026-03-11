#!/usr/bin/env nextflow

process FASTP {
    tag "$meta.sample_id"
    input:
    tuple val(meta), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.sample_id}_R1_processed.fastq.gz"), path("${meta.sample_id}_R2_processed.fastq.gz"), path("${meta.sample_id}_SE_processed.fastq.gz"), emit: processed_reads
    tuple val(meta), path('*.json'), emit: json
    tuple val(meta), path('*.html'), emit: html

    publishDir "${params.output}/${meta.sample_id}/fastp", mode: 'copy'
    conda "${projectDir}/modules/fastp/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {1.GB * task.attempt}
    }

    script:
    """
    fastp --in1 ${r1} --in2 ${r2} --out1 ${meta.sample_id}_R1_processed.fastq.gz --out2 ${meta.sample_id}_R2_processed.fastq.gz \
    --unpaired1 ${meta.sample_id}_SE_processed.fastq.gz --unpaired2 ${meta.sample_id}_SE_processed.fastq.gz --detect_adapter_for_pe --trim_poly_g --cut_front --cut_tail \
    --length_required 21 --low_complexity_filter --correction --thread  $task.cpus
    """
}
