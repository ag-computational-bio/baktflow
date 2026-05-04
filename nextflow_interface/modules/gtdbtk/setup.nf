#!/usr/bin/env nextflow

process SETUP_GTDBTK{
        publishDir path: "${params.databaseDir}", mode: 'move'
        tag "SETUP_GTDBTK"
        conda "${projectDir}/modules/gtdbtk/environment.yaml"

        output:
        path "gtdbtk_db", emit: db

        script:
        """
        mkdir gtdbtk_db
        wget -c 'https://data.gtdb.aau.ecogenomic.org//releases/release226/226.0/auxillary_files/gtdbtk_package/full_package/gtdbtk_r226_data.tar.gz'
        tar -xvzf gtdbtk_r226_data.tar.gz -C gtdbtk_db --strip 1 > /dev/null
        rm gtdbtk_r226_data.tar.gz
        echo 'Finished mamba environment setup.'
        """
}