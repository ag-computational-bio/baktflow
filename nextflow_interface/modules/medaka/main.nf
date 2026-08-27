#!/usr/bin/env nextflow

process MEDAKA {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/medaka", mode: 'copy'
    conda "${projectDir}/modules/medaka/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(long_reads), path(scaffolds)

    output:
        tuple val(meta), path("${meta.sample_id}_polished_assembly.fasta"), emit: fasta
        tuple val(meta), path("${meta.sample_id}_polished_assembly.fastq"), emit: fastq
        tuple val(meta), val('medaka'), path("${meta.sample_id}_polished_assembly.fasta"), emit: report

    script:
    """
    medaka_consensus -i ${long_reads} -d ${scaffolds} -o ./out -t ${task.cpus} --bacteria -q || \
    medaka_consensus -i ${long_reads} -d ${scaffolds} -o ./out -t ${task.cpus} -m r1041_e82_400bps_bacterial_methylation -q

    mv out/consensus.fastq ${meta.sample_id}_polished_assembly.fastq
    seqkit fq2fa ${meta.sample_id}_polished_assembly.fastq -o ${meta.sample_id}_polished_assembly.fasta
    rm -r out
    """

    stub:
    """
    touch ${meta.sample_id}_polished_assembly.fasta
    """
}
