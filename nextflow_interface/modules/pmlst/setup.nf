#!/usr/bin/env nextflow

process SETUP_PMLST{
        publishDir path: "${params.databaseDir}", mode: 'move'
        tag "SETUP_PMLST"
        conda "${projectDir}/modules/pmlst/environment.yaml"

        output:
         path "pmlst_db", emit: db

        script:
        """
        git clone 'https://bitbucket.org/genomicepidemiology/pmlst_db.git'
        cd pmlst_db
        python3 INSTALL.py kma_index
        echo 'Finished mamba environment setup.'
        """
}