#!/usr/bin/env nextflow

process MYLOASM {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/myloasm/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/myloasm", mode: 'copy'
    memory { workflow.stubRun ? 64.MB : 32.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 32 ? 32 : params.threads) }

    input:
        tuple val(meta), path(filtered_long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_assembly.fasta"), emit: fasta
        tuple val(meta), path("${meta.sample_id}_assembly_graph.gfa"), emit: gfa
        tuple val(meta), val('myloasm'), path("${meta.sample_id}_assembly.fasta"), emit: report

    script:
    """
    myloasm ${filtered_long_reads} -o ./ --clean-dir -t ${task.cpus}
    mv assembly_primary.fa ${meta.sample_id}_assembly.fasta
    mv final_contig_graph.gfa ${meta.sample_id}_assembly_graph.gfa
    """

    stub:
    """
    touch ${meta.sample_id}_assembly.fasta
    touch ${meta.sample_id}_assembly_graph.gfa
    """
}
