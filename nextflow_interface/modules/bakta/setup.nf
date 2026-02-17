#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Parameters
params.BAKTA_ENV_FILE = "${baseDir}/modules/bakta/environment.yaml"
params.BAKTA_DB_TYPE = "light"  // Valid options: light, full
params.BAKTA_DB_DIR = "$baseDir/../setup/databases/bakta"
params.BAKTA_ENV_PATH= "${baseDir}/../setup/conda_envs/bakta"

// Create the main process for setting up Bakta
process SETUP_BAKTA {
    label 'SETUP_BAKTA'
    tag "Install Bakta and Download DB"

    // Define output paths to be published
    output:
    path "bakta_db", emit: db

    // Publish outputs to the BAKTA_DB_DIR
    publishDir path: params.BAKTA_DB_DIR, mode: 'copy'
    
    memory '4GB'
    cpus (params.threads >= 2 ? 2 : params.threads)

    // Script section for installing Bakta and handling databases
    script:
    """
    echo 'Starting Bakta environment setup...'
    echo "Conda environments path: ${params.BAKTA_ENV_PATH}"
    # Create the conda environment using mamba
    mamba create -y -p ${params.BAKTA_ENV_PATH} -c bioconda bakta
    
    # Download the Bakta databases directly into the subdirectory using mamba run
    mamba run -p ${params.BAKTA_ENV_PATH} bakta_db download --type ${params.BAKTA_DB_TYPE} --output bakta_db
    echo 'Finished Bakta environment setup.'

    """
}



