#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Include individual install scripts
include { installBakta } from './bakta/setup.nf'
include { installFastp } from './fastp/setup.nf'
include { installFastqc } from './fastqc/setup.nf'

// Workflow Definition
workflow {
    installBakta()
    installFastp()
    installFastqc()
}

