#!/usr/bin/env nextflow

process PLATON{
    tag "$meta.sample_id"
    publishDir "${params.output}/${meta.sample_id}/platon", mode: 'copy'
    conda "${projectDir}/modules/platon/environment.yaml"
    errorStrategy { (task.attempt <= 3) ? 'retry' : 'ignore' }
    memory { workflow.stubRun ? 64.MB : 8.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 8 ? 8 : params.threads) }

    input:
        tuple val(meta), path(assembly)

    output:
        tuple val(meta), path("${meta.sample_id}.*"), emit: results


    script:
    """
    platon --db ${params.databaseDir}/platon_db --prefix ${meta.sample_id} --threads ${task.cpus} ${assembly}

    if [ -s ${meta.sample_id}.chromosome.fasta ]; then
        pigz -9 -p ${task.cpus} ${meta.sample_id}.chromosome.fasta
    fi
    """

    stub:
    """
    touch ${meta.sample_id}.tsv
    """

}