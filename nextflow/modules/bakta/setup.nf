#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.BAKTA_ENV_FILE = "${baseDir}/modules/bakta/environment.yaml"
params.BAKTA_DB_TYPE = "light"  // Valid options: light, full
params.BAKTA_SAVE_AS_TARBALL = false
params.PUBLISH_DIR_MODE = 'copy'

// Ensure the database subdirectory for Bakta
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
    path "bakta-${params.BAKTA_DB_TYPE}.tar.gz", emit: db_tarball, optional: true
    path "*.{log,err}", emit: logs, optional: true
    path ".command.*", emit: nf_logs, optional: true
    path "versions.yml", emit: versions, optional: true

    // Publish outputs to the BAKTA_DB_DIR
    publishDir path: params.BAKTA_DB_DIR, mode: params.PUBLISH_DIR_MODE

    // Script section for installing Bakta and handling databases
    script:
    """
    echo "Installing Bakta..."

    mkdir -p bakta_db

    # Download the Bakta databases directly into a subdirectory
    bakta_db download --type ${params.BAKTA_DB_TYPE} --output bakta_db

    # If save as tarball is enabled, create a tar.gz file
    if [ '${params.BAKTA_SAVE_AS_TARBALL}' == 'true' ]; then
        tar -czf bakta-${params.BAKTA_DB_TYPE}.tar.gz -C bakta_db .
    fi

    # Example: Generate a versions.yml file (replace with actual generation if needed)
    echo "Bakta version: 1.9.3" > versions.yml

    echo "Bakta Installation Summary:"
    echo "---------------------------------"
    echo "Conda Environment Directory: ${params.CONDA_DIR}"
    echo "Database Directory: ${params.BAKTA_DB_DIR}"
    """
}



