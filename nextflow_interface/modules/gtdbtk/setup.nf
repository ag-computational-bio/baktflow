#!/usr/bin/env nextflow

process SETUP_GTDBTK{
        publishDir path: "${params.databaseDir}", mode: 'move'
        tag "SETUP_GTDBTK"
        conda "${projectDir}/modules/gtdbtk/environment.yaml"

        output:
        path "gtdbtk_db", emit: db

        script:
        """
        download-db.sh ./gtdbtk_db
        echo 'Finished mamba environment setup.'
        """
}