#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Process to create the setup directory and subdirectories
// Process to create the setup directory and subdirectories
process CREATE_SETUPDIR {
    tag "createSetupDir"

    script:
    """
    echo "Creating setup directory..."
    mkdir -p ${params.BAKTFLOW_SETUPDIR}
    mkdir -p ${params.CONDA_DIR}
    mkdir -p ${params.DATABASE_DIR}
    """
    
}

// Include setup processes from modules
include { SETUP_FASTQC } from './modules/fastqc/setup.nf'
include { SETUP_FASTP } from './modules/fastp/setup.nf'
include { SETUP_BAKTA } from './modules/bakta/setup.nf'

// Workflow Definition
workflow {
    // Create the setup directory and subdirectories first
    CREATE_SETUPDIR()

    
    SETUP_FASTQC ()
    
    SETUP_FASTP()

    SETUP_BAKTA()
    
}




