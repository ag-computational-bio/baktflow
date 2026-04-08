#!/usr/bin/env nextflow

process FLYE {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/flye/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(filtered_long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_assembly.fasta"), emit: scaffolds
        tuple val(meta), path("${meta.sample_id}_assembly_graph.gfa"), emit: graph
        tuple val(meta), path("${meta.sample_id}_assembly_info.txt"), emit: info

    script:
    """
    flye --pacbio-raw ${filtered_long_reads} --genome-size 4.6m --out-dir flye_output --threads ${task.cpus}

    cp flye_output/assembly.fasta ${meta.sample_id}_assembly.fasta
    cp flye_output/assembly_graph.gfa ${meta.sample_id}_assembly_graph.gfa
    cp flye_output/assembly_info.txt ${meta.sample_id}_assembly_info.txt
    """

    stub:
    """
    touch ${meta.sample_id}_assembly.fasta
    touch ${meta.sample_id}_assembly_graph.gfa
    touch ${meta.sample_id}_assembly_info.txt
    """
}
