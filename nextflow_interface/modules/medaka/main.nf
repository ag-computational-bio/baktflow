#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// Define parameters with default values
params.CONDA_ENV_DIR = "$projectDir/../setup/conda_envs"
params.CONDA_ENV_PATH = "${params.CONDA_ENV_DIR}/medaka"
params.OUTPUT_DIR = "$projectDir/../output"


process MEDAKA {
    tag "$meta.sample_id"
    
    input:
    tuple val(meta), path(long_reads), path(scaffolds)

    output:
    tuple val(meta), path("${meta.sample_id}_polished_assembly.fasta"), emit: input_fasta

    publishDir "${params.OUTPUT_DIR}/${meta.sample_id}/medaka", mode: 'copy'
    conda "${projectDir}/../setup/conda_envs/medaka"
    if ( "${workflow.stubRun}" == "false" ) {
        cpus (params.threads >= 8 ? 8 : params.threads)
        memory {1.GB * task.attempt}
    }
    
    script:
    def prefix = meta.sample_id
    """
    # Convert long reads to bgzip if necessary
    if [[ "${long_reads}" == *.gz ]]; then
        gunzip -c ${long_reads} | bgzip -c > ${prefix}.fastq.bgz
        echo "${prefix}.fastq.bgz" > reads_bgzip_out.txt
    else
        cp ${long_reads} ${prefix}.fastq.bgz
        echo "${prefix}.fastq.bgz" > reads_bgzip_out.txt
    fi

    # Convert scaffolds to bgzip if necessary
    if [[ "${scaffolds}" == *.gz ]]; then
        gunzip -c ${scaffolds} | bgzip -c > ${prefix}.fasta.bgz
        echo "${prefix}.fasta.bgz" > assembly_bgzip_out.txt
    else
        cp ${scaffolds} ${prefix}.fasta.bgz
        echo "${prefix}.fasta.bgz" > assembly_bgzip_out.txt
    fi

    # Read variables back into Nextflow
    reads_bgzip_out=\$(cat reads_bgzip_out.txt)
    assembly_bgzip_out=\$(cat assembly_bgzip_out.txt)

    # Run medaka consensus polishing
    medaka_consensus \\
        -i "\$reads_bgzip_out" \\
        -d "\$assembly_bgzip_out" \\
        -o medaka_output \\
        -t ${task.cpus}

    # Move the polished assembly to the output location
    mv medaka_output/consensus.fasta ${meta.sample_id}_polished_assembly.fasta
    """
}






















