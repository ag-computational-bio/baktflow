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
   python3 ${script}

   echo 'Finished mamba environment setup.'
   """
}
