#!/usr/bin/env nextflow

process FLYE {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/flye/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/flye", mode: 'copy'
    errorStrategy { (task.attempt <= 3) ? 'retry' : 'ignore' }
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 16 ? 16 : params.threads) }

    input:
        tuple val(meta), val(genome_size), val(coverage), path(filtered_long_reads)

    output:
        tuple val(meta), path("${meta.sample_id}_assembly.fasta"), emit: scaffolds
        tuple val(meta), path("${meta.sample_id}_assembly_graph.gfa"), emit: graph
        tuple val(meta), path("${meta.sample_id}_assembly_info.txt"), emit: info

    script:
    """
    if [[ ${genome_size} -eq 1 ]]; then
        flye --scaffold --nano-hq ${filtered_long_reads} --out-dir ./ --threads ${task.cpus}
    elif [[ ${coverage} -gt 100 ]]; then
        flye --scaffold --genome-size ${genome_size} --asm-coverage 100 --nano-hq ${filtered_long_reads} --out-dir ./ --threads ${task.cpus}
    else
        flye --scaffold --genome-size ${genome_size} --nano-hq ${filtered_long_reads} --out-dir ./ --threads ${task.cpus}
    fi

    mv assembly.fasta ${meta.sample_id}_assembly.fasta
    mv assembly_graph.gfa ${meta.sample_id}_assembly_graph.gfa
    mv assembly_info.txt ${meta.sample_id}_assembly_info.txt
    """

    stub:
    """
    touch ${meta.sample_id}_assembly.fasta
    touch ${meta.sample_id}_assembly_graph.gfa
    touch ${meta.sample_id}_assembly_info.txt
    """
}
