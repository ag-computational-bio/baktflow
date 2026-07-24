#!/usr/bin/env nextflow

process ANTISMASH {
    tag "$meta.sample_id"
    conda "${projectDir}/modules/antismash/environment.yaml"
    publishDir "${params.output}/${meta.sample_id}/antismash", mode: 'copy'
    memory { workflow.stubRun ? 64.MB : 6.GB * task.attempt }
    cpus { workflow.stubRun ? 1 : (params.threads >= 4 ? 4 : params.threads) }

    input:
        tuple val(meta), path(genbank)

    output:
        tuple val(meta), path("${meta.sample_id}.gbk"), emit: genbank
        tuple val(meta), path("${meta.sample_id}.json"), emit: json

    script:
    """
    antismash ${genbank} --genefinding-tool none --taxon bacteria --output-basename ${meta.sample_id} \
    --no-region-gbks --clusterhmmer --asf \
    --output-dir ./out --databases ${params.databaseDir}/antismash --cpus ${task.cpus}

    mv out/*.gbk ./
    mv out/*.json ./
    rm -r out
    """

    stub:
    """
    touch ${meta.sample_id}.gbk
    touch ${meta.sample_id}.json
    touch index.html
    """
}
