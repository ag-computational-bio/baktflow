#!/usr/bin/env nextflow

process SETUP_CHEWBBACA {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_CHEWBBACA"
    conda "${projectDir}/modules/chewbbaca/environment.yaml"
    cpus { workflow.stubRun ? 1 : (params.threads >= 16 ? 16 : params.threads) }

    output:
        path "chewBBACA", emit: db

   script:
   """
   chewbbaca_download_cgmlst_schemas.py --threads ${task.cpus}

   echo 'Finished mamba environment setup.'
   """
}
