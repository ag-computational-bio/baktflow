#!/usr/bin/env nextflow

process FASTPLONG {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/fastplong", pattern: "*.json.gz", mode: 'copy'
    publishDir "${params.output}/${meta.sample_id}/fastplong", pattern: "*.html", mode: 'copy'
    conda "${projectDir}/modules/fastplong/environment.yaml"
    memory { workflow.stubRun ? 64.MB : ( meta.sample_type.startsWith("meta") ? 4.GB * task.attempt : 2.GB * task.attempt ) }
    cpus { workflow.stubRun ? 1 : ( meta.sample_type.startsWith("meta") ? 16 : ( params.threads >= 8 ? 8 : params.threads )) }

    input:
        tuple val(meta), path(long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_trimmed.fastq.gz"), emit: trimmed_long_reads, optional: true
        tuple path("fastplong.json.gz"), path("fastplong.html"), emit: log, optional: true
        tuple val(meta), val('fastplong'), path("${meta.sample_id}_trimmed.fastq.gz"), emit: report, optional: true

    script:
    def min_lengt = meta.sample_type.startsWith("meta") ? 1000 : 500
    """
    fastplong -i ${long_reads} --stdout --cut_front --cut_tail --cut_mean_quality 10 --break --break_mean_quality 10 \
    --mean_qual 10 --length_required ${min_lengt} --thread $task.cpus | \
    pigz -9 -p ${task.cpus} > ${meta.sample_id}_trimmed.fastq.gz

    # Skip sample if no read passed quality filtering
    AFTER=\$(grep -A 1 "after_filtering" fastplong.json | head -n 2 | grep "total_reads" | cut -d: -f 2 | sed 's/,//')

    if [[ \$AFTER -eq 0 ]]; then
        rm ${meta.sample_id}_trimmed.fastq.gz fastplong.json fastplong.html
    else
        pigz -9 -p ${task.cpus} fastplong.json
    fi
    """

    stub:
    """
    touch ${meta.sample_id}_trimmed.fastq.gz
    touch fastplong.json.gz
    touch fastplong.html
    """
}
