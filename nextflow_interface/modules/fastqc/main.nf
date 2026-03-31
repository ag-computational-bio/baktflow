#!/usr/bin/env nextflow

params.REPORT_SCRIPT = "$projectDir/modules/fastqc/report.py"

process FASTQC {
    tag "$meta.sample_id"

    publishDir "${params.output}/${meta.sample_id}/fastqc", mode: 'copy'
    conda "${projectDir}/modules/fastqc/environment.yaml"

    input:
        tuple val(meta), path(reads)

    output:
        tuple val(meta), path("${reads.baseName}.html"), emit: html
        tuple val(meta), path("${reads.baseName}.zip"), emit: zip

    script:
    """
    fastqc ${reads} -o ./ --threads $task.cpus
    mv *fastqc.html ${reads.baseName}.html
    mv *fastqc.zip ${reads.baseName}.zip

    # Run report.py with correct arguments
    python ${params.REPORT_SCRIPT} --zip ${reads.baseName}.zip --output ${params.output}/${meta.sample_id}/fastqc
    """
}
