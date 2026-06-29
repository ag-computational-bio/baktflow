#!/usr/bin/env nextflow

// Include setup processes from modules
include { SETUP_AUTOCYCLER } from './modules/autocycler/setup.nf'
include { SETUP_GENOMESTATS } from './modules/genomestats/setup.nf'
include { SETUP_FASTP } from './modules/fastp/setup.nf'
include { SETUP_FILTLONG} from './modules/filtlong/setup.nf'
include { SETUP_FLYE } from './modules/flye/setup.nf'
include { SETUP_UNICYCLER } from './modules/unicycler/setup.nf'
include { SETUP_MEDAKA } from './modules/medaka/setup.nf'
include { SETUP_POLYPOLISH } from './modules/polypolish/setup.nf'
include { SETUP_PYPOLCA } from './modules/pypolca/setup.nf'
include { SETUP_DNAAPLER } from './modules/dnaapler/setup.nf'
include { SETUP_BAKTA } from './modules/bakta/setup.nf'
include { SETUP_CHECKM2 } from './modules/checkm2/setup.nf'
include { SETUP_MOB_SUITE  } from './modules/mob_suite/setup.nf'
include { SETUP_MLST } from './modules/mlst/setup.nf'
include { SETUP_SKA } from './modules/ska/setup.nf'
include { SETUP_RGI } from './modules/rgi/setup.nf'
include { SETUP_VFDB } from './modules/vfdb/setup.nf'
include { SETUP_AMRFINDERPLUS } from './modules/amrfinderplus/setup.nf'
include { SETUP_REFERENCESEEKER } from './modules/referenceseeker/setup.nf'
include { SETUP_PLATON } from './modules/platon/setup.nf'
include { SETUP_SILVA_16S } from './modules/silva-16s/setup.nf'
include { SETUP_BANDAGE } from './modules/bandage/setup.nf'
include { SETUP_MACSYFINDER} from './modules/macsyfinder/setup.nf'
include { SETUP_GTDBTK} from './modules/gtdbtk/setup.nf'
include { SETUP_PMLST} from './modules/pmlst/setup.nf'
include { SETUP_ECTYPER } from './modules/ectyper/setup.nf'
include { SETUP_KLEBORATE } from './modules/kleborate/setup.nf'
include { SETUP_PLING } from './modules/pling/setup.nf'
include { SETUP_PLASMIDFINDER } from './modules/plasmidfinder/setup.nf'
include { SETUP_CHEWBBACA } from './modules/chewbbaca/setup.nf'

// Workflow definition
workflow {

        SETUP_AUTOCYCLER()
        SETUP_GENOMESTATS()
        SETUP_FASTP()
        SETUP_FILTLONG()
        SETUP_FLYE()
        SETUP_UNICYCLER()
        SETUP_MEDAKA()
        SETUP_POLYPOLISH()
        SETUP_PYPOLCA()
        SETUP_DNAAPLER()
        SETUP_BAKTA()
        SETUP_CHECKM2()
        SETUP_MOB_SUITE()
        SETUP_DIAMOND()
        SETUP_AMRFINDERPLUS()
        SETUP_SKA()
        SETUP_RGI()
        SETUP_REFERENCESEEKER()
        SETUP_MLST()
        SETUP_PLATON()
        SETUP_SILVA_16S()
        SETUP_MACSYFINDER()
        SETUP_BANDAGE()
        SETUP_PMLST()
        SETUP_GTDBTK()
        SETUP_ECTYPER()
        SETUP_KLEBORATE()
        SETUP_PLING()
        SETUP_PLASMIDFINDER()
        SETUP_CHEWBBACA()


    /*
    workflow.onComplete {
        def separator = "=" * 60 // Creates a 60-character separator line
        log.info "\n${separator}"
        log.info "Check Conda Environment Directory: ${params.cacheDir}"
        log.info "Check Database Directory: ${params.databaseDir}"
        log.info "Duration: ${workflow.duration}"
        log.info "Success: ${workflow.success}"
        log.info "Error Report: ${workflow.errorReport ?: '-'}"
        log.info "Launch Dir: ${workflow.launchDir}"
        log.info "\n${separator}"
    }
    */
}
