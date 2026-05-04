#!/usr/bin/env nextflow

params.checkm2db = "${params.databaseDir}/checkm2db/CheckM2_database/uniref100.KO.1.dmnd"

process CHECKM2{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/checkm2", mode: 'copy'
    conda "${projectDir}/modules/checkm2/environment.yaml"
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

     input:
            tuple val(meta), path(prot)

     output:
            tuple val(meta), path("${meta.sample_id}.checkm2.tsv"), emit: tsv

     script:
     """
     mkdir ./input
     cp ${prot} ./input
     checkm2 predict --input ./input --output-directory ./out --database_path ${params.checkm2db} --genes  --extension .faa --threads ${task.cpus} --lowmem
     mv ./out/quality_report.tsv ${meta.sample_id}.checkm2.tsv
     """

    stub:
    """
    touch ${meta.sample_id}.checkm2.tsv
    """
}