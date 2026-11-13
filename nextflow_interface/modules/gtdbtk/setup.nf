#!/usr/bin/env nextflow

process SETUP_GTDBTK{
        publishDir path: "${params.databaseDir}/versions", mode: 'move', pattern: "*.txt"
        publishDir path: "${params.databaseDir}", mode: 'move', pattern: "gtdbtk_db"
        tag "SETUP_GTDBTK"
        conda "${projectDir}/modules/gtdbtk/environment.yaml"

        output:
        path "gtdbtk_db", emit: db
        path "gtdbtk.txt", emit: version

        script:
        """
        date '+%Y-%m-%d %H:%M:%S' > gtdbtk.txt
        download-db.sh -d ./gtdbtk_db
        echo 'Finished mamba environment setup.'
        """
}
