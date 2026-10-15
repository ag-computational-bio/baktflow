#!/usr/bin/env nextflow

process SEMIBIN {
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/semibin", pattern: "*.log", mode: 'copy'
    conda "${projectDir}/modules/semibin/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(assembly), path(bai), path(bam)

    output:
        tuple val(meta), path("semibin_bins"), emit: bins
        path("SemiBinRun.log"), emit: log

    script:
    """
    SemiBin2 single_easy_bin --input-fasta ${assembly} --input-bam ${bam} -o ./out --orf-finder prodigal \
    --sequencing-type long_read --min-len 1000 --tag-output ${meta.sample_id} --reference-db ${params.databaseDir}/gtdbtk_db \
    --self-supervised --engine cpu --compression none --threads ${task.cpus}

    mv out/output_bins ./semibin_bins
    mv out/SemiBinRun.log ./
    """

    stub:
    """
    touch ${meta.sample_id}_depleted.fastq.gz
    """
}
