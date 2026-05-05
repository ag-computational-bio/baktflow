#!/usr/bin/env nextflow


process BLAST{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/blast", mode: 'copy'
    conda "${projectDir}/modules/blast/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(features)

    output:
        tuple val(meta), path("${meta.sample_id}.16s.tsv"), emit: tsv


    script:
    """
    grep -A 1 '16S ribosomal RNA' ${features} | tr -d '-' | tr -s '\n' > 16S.ffn
    blastn -query 16S.ffn -db ${params.databaseDir}/silva_db/silva_db -evalue 1E-10 -outfmt '6 qseqid sseqid length nident bitscore stitle' -num_threads ${task.cpus} > ${meta.sample_id}.16s.tsv
    """

    stub:
    """
    touch ${meta.sample_id}.16s.tsv
    """

}