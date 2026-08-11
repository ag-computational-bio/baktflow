#!/usr/bin/env nextflow

process FASTPLONG {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/fastplong", pattern: "*.json", mode: 'copy'
    publishDir "${params.output}/${meta.sample_id}/fastplong", pattern: "*.html", mode: 'copy'
    conda "${projectDir}/modules/fastplong/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 2.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 2 ? 2 : params.threads) }

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_trimmed.fastq.gz"), emit: trimmed_long_reads
        tuple path("*.json"), path("*.html"), emit: log

    script:
    """
    fastplong -i ${long_reads} --out ${meta.sample_id}_trimmed.fastq.gz --cut_front --cut_tail --cut_mean_quality 3 \
    --trim_poly_x --break --break_mean_quality 3 --length_required 500 --compression 6 --thread $task.cpus

    # Fallback to use the complete input file if overall quality is to low
    if [ \$(zgrep -c "@" ${meta.sample_id}_trimmed.fastq.gz) -eq 0 ]; then
        rm ${meta.sample_id}_trimmed.fastq.gz
        cp ${long_reads} ${meta.sample_id}_trimmed.fastq.gz
    fi
    """

    stub:
    """
    touch ${meta.sample_id}_trimmed.fastq.gz
    touch ${meta.sample_id}.json
    touch ${meta.sample_id}.html
    """
}
