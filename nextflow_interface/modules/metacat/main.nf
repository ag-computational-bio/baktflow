#!/usr/bin/env nextflow

process METACAT {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/metacat/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 40.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(assembly), path(bai), path(bam)

    output:
        tuple val(meta), path("metacat_bins"), emit: bins

    script:
    """
    MetaCAT coverage --long --bam ${bam} --output ${meta.sample_id}.metacat.coverage --no-index --threads-count ${task.cpus}
    MetaCAT seed --fasta ${assembly} --output ${meta.sample_id}.metacat.seed --threads ${task.cpus}

    MetaCAT cluster --fasta ${assembly} --coverage ${meta.sample_id}.metacat.coverage \
    --seed ${meta.sample_id}.metacat.seed --output ${meta.sample_id}.metacat --threads ${task.cpus}

    mkdir metacat_bins
    mv ${meta.sample_id}.metacat.*.fasta metacat_bins/
    """

    stub:
    """
    touch metacat_bins
    """
}
