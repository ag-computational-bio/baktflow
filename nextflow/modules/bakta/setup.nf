#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.BAKTA_ENV_FILE = "${baseDir}/modules/bakta/environment.yaml"
params.BAKTA_DB_TYPE = "light"  // Valid options: light, full
params.PUBLISH_DIR_MODE = 'copy'
params.BAKTA_DB_DIR = "${params.DATABASE_DIR}/bakta"

// Create the main process for setting up Bakta
process SETUP_BAKTA {
    label 'SETUP_BAKTA'
    tag "Install Bakta and Download DB"

    // Conda environment setup
    conda "${params.BAKTA_ENV_FILE}"

    // Define output paths to be published
    output:
    path "bakta_db", emit: db


    // Publish outputs to the BAKTA_DB_DIR
    publishDir path: params.BAKTA_DB_DIR, mode: params.PUBLISH_DIR_MODE

    // Script section for installing Bakta and handling databases
    script:
    """
    echo "Installing Bakta..."

    mkdir -p bakta_db

    # Download the Bakta databases directly into a subdirectory
    bakta_db download --type ${params.BAKTA_DB_TYPE} --output bakta_db

    """
}



