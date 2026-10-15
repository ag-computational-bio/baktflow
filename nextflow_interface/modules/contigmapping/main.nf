#!/usr/bin/env nextflow

process CONTIGMAPPING {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/contigmapping/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 32.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 32 ? 32 : params.threads) }
    scratch true

    input:
        tuple val(meta), path(assembly), path(reads)

    output:
        tuple val(meta), path("${meta.sample_id}.bam.bai"), path("${meta.sample_id}.bam"), emit: mapped_reads

    script:
    if ( meta.sample_type == 'meta-long' )
        """
        minimap2 -t ${task.cpus} -a -x map-ont ${assembly} ${reads} | samtools sort - -@ ${task.cpus} -o ${meta.sample_id}.bam

        samtools index -@ ${task.cpus} ${meta.sample_id}.bam
        """
    else
        error "Invalid sample type: ${meta.sample_type}"

    stub:
    """
    touch ${meta.sample_id}.bam
    """
}
