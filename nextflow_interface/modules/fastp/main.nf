#!/usr/bin/env nextflow

process FASTP {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/fastp", pattern: "*.json", mode: 'copy'
    publishDir "${params.output}/${meta.sample_id}/fastp", pattern: "*.html", mode: 'copy'
    conda "${projectDir}/modules/fastp/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 2.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(r1), path(r2)

    output:
        tuple val(meta), path("${meta.sample_id}_R1_processed.fastq.gz"), path("${meta.sample_id}_R2_processed.fastq.gz"), path("${meta.sample_id}_SE_processed.fastq.gz"), emit: trimmed_reads
        tuple val(meta), path("*.json"), path("*.html"), emit: log

    script:
    """
    fastp --in1 ${r1} --in2 ${r2} --out1 ${meta.sample_id}_R1_processed.fastq.gz --out2 ${meta.sample_id}_R2_processed.fastq.gz \
    --unpaired1 ${meta.sample_id}_SE_processed.fastq.gz --unpaired2 ${meta.sample_id}_SE_processed.fastq.gz \
    --detect_adapter_for_pe --trim_poly_g --cut_front --cut_tail --length_required 21 --low_complexity_filter \
    --correction --compression 9 --thread $task.cpus
    """

    stub:
    """
    touch ${meta.sample_id}_R1_processed.fastq.gz
    touch ${meta.sample_id}_R2_processed.fastq.gz
    touch ${meta.sample_id}_SE_processed.fastq.gz
    touch ${meta.sample_id}.SE.fastq.gz
    touch ${meta.sample_id}.fastp.json
    touch ${meta.sample_id}.fastp.html
    """
}
