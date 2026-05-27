#!/usr/bin/env nextflow

process SETUP_CHEWBBACA {
    publishDir path: "${params.databaseDir}", mode: 'move'
    tag "SETUP_CHEWBBACA"
    conda "${projectDir}/modules/chewbbaca/environment.yaml"

    output:
        path "chewBBACA", emit: db

   script:
   def script = "${projectDir}/modules/chewbbaca/download_cgmlst_schemas.py"
   """
   ./chewbbaca_download_cgmlst_schemas.py

   echo 'Finished mamba environment setup.'
   """
}
