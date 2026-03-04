#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.REPORT_SCRIPT = "$projectDir/modules/fastqc/report.py"
params.OUTPUT_DIR = "$projectDir/../output"

// FastQC Process
process FASTQC {
    tag { meta.sample_id }
    label 'fastqc'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${reads.baseName}.html"), emit: html
    tuple val(meta), path("${reads.baseName}.zip"), emit: zip

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/fastqc", mode: 'copy'

    conda "${projectDir}/modules/fastqc/environment.yaml"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 2 ? 2 : params.threads)
        memory {1.GB * task.attempt}
    }

    script:
    """
    fastqc ${reads} -o ./ --threads $task.cpus
    mv *fastqc.html ${reads.baseName}.html
    mv *fastqc.zip ${reads.baseName}.zip

    # Run report.py with correct arguments
    python ${params.REPORT_SCRIPT} --zip ${reads.baseName}.zip --output ${params.OUTPUT_DIR}/${meta.sample_id}/fastqc
    """
}




















