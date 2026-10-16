#!/usr/bin/env nextflow

process NANOPLOT {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/nanoplot/${mode}", pattern: "${mode}_*", mode: 'copy'
    conda "${projectDir}/modules/nanoplot/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 4.GB * task.attempt }

    input:
        tuple val(mode), val(meta), path(long_reads)

    output:
        path("${mode}_*")

    script:
    if ( mode == "raw")
        """
        NanoPlot --fastq ${long_reads} -p raw_ --title ${meta.sample_id}_raw -c darkblue --format pdf --no_static --N50 -t $task.cpus
        """
    else if ( mode == "filtered")
        """
        NanoPlot --fastq ${long_reads} -p filtered_ --title ${meta.sample_id}_filtered -c darkblue --format pdf --no_static --N50 -t $task.cpus
        """
    else
        error "Invalid NanoPlot mode: ${mode}"

    stub:
    """
    touch ${mode}_.pdf
    """
}
