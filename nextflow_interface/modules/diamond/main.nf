#!/usr/bin/env nextflow
params.vfdb = "${params.databaseDir}/vfdb.dmnd"

process DIAMOND{
     tag "$meta.sample_id"
     publishDir "${params.output}/${meta.sample_id}/diamond", mode: 'copy'
     conda "${projectDir}/modules/diamond/environment.yaml"
     memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
     cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }


    input:
        tuple val(meta), path(prot)

    output:
        path("${meta.sample_id}.vf.tsv"), emit: vf_tsv

    script:
    """
    diamond blastp --query ${prot} --db ${params.vfdb} --id 80 --query-cover 80 --subject-cover 80 --out ${meta.sample_id}.vf.tsv --outfmt 6 qseqid sseqid qlen slen qstart qend sstart send length pident evalue bitscore --threads ${task.cpus}
    """

    stub:
    """
    touch ${meta.sample_id}.vf.tsv
    """
}