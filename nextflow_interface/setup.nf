#!/usr/bin/env nextflow

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
    log.info "${''.center(60, '=')}"
    log.info "Check Conda Environment Directory: ${params.cacheDir}"
    log.info "Check Database Directory: ${params.databaseDir}"
    log.info "Duration: ${workflow.duration}"
    log.info "Success: ${workflow.success}"
    log.info "Error Report: ${workflow.errorReport ?: '-'}"
    log.info "Launch Dir: ${workflow.launchDir}"
    log.info "${''.center(60, '=')}"
}
