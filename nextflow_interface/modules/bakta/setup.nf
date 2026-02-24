#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.BAKTA_DB_TYPE = "light"  // Valid options: light, full
params.BAKTA_DB_DIR = "$projectDir/../setup/databases/bakta"

// Create the main process for setting up Bakta
process SETUP_BAKTA {
    label 'SETUP_BAKTA'
    tag "Install Bakta and Download DB"

    // Define output paths to be published
    output:
    path "bakta_db", emit: db

    // Publish outputs to the BAKTA_DB_DIR
    publishDir path: params.BAKTA_DB_DIR, mode: 'copy'

    conda "${projectDir}/modules/bakta/environment.yaml"

    // Script section for installing Bakta and handling databases
    script:
    """
    bakta_db download --type ${params.BAKTA_DB_TYPE} --output bakta_db
    echo 'Finished Bakta environment setup.'
    """
}



