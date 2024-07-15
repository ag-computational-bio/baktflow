#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// ANSI color codes
ANSI_BOLD = "\033[1m"
ANSI_GREEN = "\033[1;32m"
ANSI_RED = "\033[1;31m"
ANSI_RESET = "\033[0m"


// Include setup processes from modules
include { SETUP_FASTQC } from './modules/fastqc/setup.nf'
include { SETUP_FASTP } from './modules/fastp/setup.nf'
include { SETUP_BAKTA } from './modules/bakta/setup.nf'

// Workflow definition
workflow {
    SETUP_FASTQC()
    SETUP_FASTP()
    SETUP_BAKTA()
}


workflow.onComplete {
   

    
    log.info "${ANSI_GREEN}${ANSI_BOLD}${''.center(60, '=')}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Check Conda Environment Directory: ${params.CONDA_ENVS_PATH}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Check Database Directory: ${params.DATABASE_DIR}${ANSI_RESET}"
    // log.info "${ANSI_GREEN}${ANSI_BOLD}FastQC Version: ${fastqc_version}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Duration: ${workflow.duration}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Success: ${workflow.success}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Error Report: ${workflow.errorReport ?: '-'}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Launch Dir: ${workflow.launchDir}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}${''.center(60, '=')}${ANSI_RESET}"
}



