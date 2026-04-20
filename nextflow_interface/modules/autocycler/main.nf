#!/usr/bin/env nextflow

process AUTOCYCLER_SUBSAMPLE {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/autocycler/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 4.GB * task.attempt }

    input:
        tuple val(meta), val(genome_size), path(long_reads)

    output:
        tuple val(meta), val(genome_size), path("sample_01.fastq"), path("sample_02.fastq"), path("sample_03.fastq"), path("sample_04.fastq"), emit: subsamples

    script:
    """
    autocycler subsample --reads ${long_reads} --out_dir ./ --genome_size ${genome_size} --min_read_depth ${params.minReadDepth}
    """

    stub:
    """
    touch sample_01.fastq
    touch sample_02.fastq
    touch sample_03.fastq
    touch sample_04.fastq
    """
}

// TODO use existing flye assembly for plassembler run
process AUTOCYCLER_ASSEMBLY {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/autocycler/environment.yaml"
    errorStrategy { (task.attempt <= 3) ? 'retry' : 'ignore' }  // sometimes an assembly of a subset can fail
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 16 ? 16 : params.threads) }

    input:
        tuple val(assembler), val(meta), val(genome_size), path(subsample)

    output:
        tuple val(meta), path("${meta.sample_id}_${assembler}_*.fasta"), emit: assembly

    script:
    """
    export TERM=xterm-256color
    export PLASSEMBLER_DB="${params.databaseDir}/plassembler_db"

    autocycler helper $assembler --reads $subsample --out_prefix ${meta.sample_id}_${assembler}_${subsample.baseName.tokenize('_')[1]} \
    --threads $task.cpus --genome_size $genome_size --min_depth_rel 0.1

    if [ ! -f ./${meta.sample_id}_${assembler}_${subsample.baseName.tokenize('_')[1]}.fasta ]; then
        touch ${meta.sample_id}_${assembler}_${subsample.baseName.tokenize('_')[1]}.fasta
    fi

    shopt -s nullglob
    for f in ./plassembler*.fasta; do
        sed -i 's/circular=True/circular=True Autocycler_cluster_weight=3/' \$f
    done
    for f in ./canu*.fasta ./flye*.fasta; do
        sed -i 's/^>.*\$/& Autocycler_consensus_weight=2/' \$f
    done
    shopt -u nullglob
    """

    stub:
    """
    touch ${assembler}_${subsample.baseName.tokenize('_')[1]}.fasta
    """
}

// TODO catch Error: the mean number of contigs per input assembly (46.2) exceeds the allowed threshold (25). Are your input assemblies fragmented or contaminated? in autocycler compress
process AUTOCYCLER_CONSENSUS {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/autocycler", mode: 'copy'
    conda "${projectDir}/modules/autocycler/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 16.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path("assemblies/*")

    output:
        tuple val(meta), path("${meta.sample_id}_consensus_assembly.fasta"), env("COMPLETE"), emit: assembly
        path("${meta.sample_id}_consensus_assembly.gfa"), emit: gfa

    script:
    """
    # Exclude failed empty assemblies
    for f in assemblies/*.fasta; do
        if [ ! -s \$f ]; then
            rm \$f
        fi
    done

    autocycler compress -i assemblies -a autocycler_out --threads $task.cpus

    autocycler cluster -a autocycler_out

    for c in autocycler_out/clustering/qc_pass/cluster_*; do
        autocycler trim -c \$c --threads $task.cpus
        autocycler resolve -c \$c
    done

    autocycler combine -a autocycler_out -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa

    autocycler table -a autocycler_out -n ${meta.sample_id} > metrics.tsv
    COMPLETE=\$(cut -f 13)

    mv autocycler_out/consensus_assembly.fasta ${meta.sample_id}_consensus_assembly.fasta
    mv autocycler_out/consensus_assembly.gfa ${meta.sample_id}_consensus_assembly.gfa
    """

    stub:
    """
    touch ${meta.sample_id}_consensus_assembly.fasta
    COMPLETE="true"
    """
}