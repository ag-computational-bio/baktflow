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
        tuple path("fastplong.json.gz"), path("fastplong.html"), emit: log, optional: true

    script:
    """
    fastplong -i ${long_reads} --stdout --cut_front --cut_tail --cut_mean_quality 10 --break --break_mean_quality 10 \
    --mean_qual 10 --length_required 500 --thread $task.cpus | \
    pigz -9 -p ${task.cpus} > ${meta.sample_id}_trimmed.fastq.gz

    # Fallback to use the complete input file if overall quality is to low
    BEFORE=\$(grep -A 1 "before_filtering" fastplong.json | head -n 2 | grep "total_reads" | cut -d: -f 2 | sed 's/,//')
    AFTER=\$(grep -A 1 "after_filtering" fastplong.json | head -n 2 | grep "total_reads" | cut -d: -f 2 | sed 's/,//')
    FRACTION=\$((\$AFTER/\$BEFORE*100))

    if [[ \$AFTER -eq 0 || \$FRACTION -le 50 ]]; then
        rm ${meta.sample_id}_trimmed.fastq.gz fastplong.json fastplong.html
        cp ${long_reads} ${meta.sample_id}_trimmed.fastq.gz
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
