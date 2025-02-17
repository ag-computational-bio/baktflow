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

    // Define output paths to be published
    output:
    path "bakta_db", emit: db

    // Publish outputs to the BAKTA_DB_DIR
    publishDir path: params.BAKTA_DB_DIR, mode: params.PUBLISH_DIR_MODE

    // Script section for installing Bakta and handling databases
    script:
    """
    # Create the conda environment using mamba
    mamba create -y -p ${params.CONDA_ENV_PATH_BAKTA} -c bioconda bakta

    # Download the Bakta databases directly into the subdirectory using mamba run
    mamba run -p ${params.CONDA_ENV_PATH_BAKTA} ${params.CONDA_ENV_PATH_BAKTA}/bin/bakta_db download --type ${params.BAKTA_DB_TYPE} --output bakta_db
    """
}



