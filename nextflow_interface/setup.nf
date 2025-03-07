#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.CONDA_ENVS_PATH = "$baseDir/../setup/conda_envs"
params.DATABASE_DIR = "$baseDir/../setup/databases"

// ANSI color codes
ANSI_BOLD = "\033[1m"
ANSI_GREEN = "\033[1;32m"
ANSI_RED = "\033[1;31m"
ANSI_RESET = "\033[0m"


// Include setup processes from modules
include { SETUP_FASTQC } from './modules/fastqc/setup.nf'
include { SETUP_FASTP } from './modules/fastp/setup.nf'
include { SETUP_FILTLONG} from './modules/filtlong/setup.nf'
include { SETUP_FLYE } from './modules/flye/setup.nf'
include { SETUP_UNICYCLER } from './modules/unicycler/setup.nf'
include { SETUP_MEDAKA } from './modules/medaka/setup.nf'
include { SETUP_POLYPOLISH } from './modules/polypolish/setup.nf'
include { SETUP_PYPOLCA } from './modules/pypolca/setup.nf'
include { SETUP_DNAAPLER } from './modules/dnaapler/setup.nf'
include { SETUP_BAKTA } from './modules/bakta/setup.nf'



// Workflow definition

workflow {
    SETUP_FASTP()
    SETUP_FASTQC()
    SETUP_FILTLONG()
    SETUP_FLYE()
    SETUP_UNICYCLER()
    SETUP_MEDAKA()
    SETUP_POLYPOLISH()
    SETUP_PYPOLCA()
    SETUP_DNAAPLER()
    SETUP_BAKTA()


}

workflow.onComplete {
    log.info "${ANSI_GREEN}${ANSI_BOLD}${''.center(60, '=')}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Check Conda Environment Directory: ${params.CONDA_ENVS_PATH}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Check Database Directory: ${params.DATABASE_DIR}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Duration: ${workflow.duration}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Success: ${workflow.success}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Error Report: ${workflow.errorReport ?: '-'}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}Launch Dir: ${workflow.launchDir}${ANSI_RESET}"
    log.info "${ANSI_GREEN}${ANSI_BOLD}${''.center(60, '=')}${ANSI_RESET}"
}



