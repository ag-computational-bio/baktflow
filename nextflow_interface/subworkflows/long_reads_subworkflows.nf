#!/usr/bin/env nextflow
nextflow.enable.dsl=2
include { FASTQC} from '../modules/fastqc/main.nf' 
include { FILTLONG} from '../modules/filtlong/main.nf' 
include {FLYE} from '../modules/flye/main.nf' 
include {MEDAKA} from '../modules/medaka/main.nf' 
include {DNAAPLER} from '../modules/dnaapler/main.nf' 


workflow LONG_READ_PROCESSING_SUBWORKFLOW {
    take:
    ch_long_reads

    main:
    // Step 1: Perform FastQC analysis on long reads
    def ch_fastqc_results = ch_long_reads.flatMap { sample ->
        sample.long_reads.collect { long_read -> tuple(sample.meta, long_read) }
    } | FASTQC

    // Step 2: Filter long reads
    def ch_filtered_long_reads = FILTLONG(ch_long_reads.flatMap { it.long_reads.collect { long_file -> tuple(it.meta, long_file) } })
    def long_reads_for_assembly = ch_filtered_long_reads.filtered_long_reads

    // Step 3: Assemble with Flye
    def flye_assembly = FLYE(long_reads_for_assembly)

    // Step 4: Polish with Medaka (only scaffolds + long reads)
    def ch_medaka_input = flye_assembly.scaffolds.combine(
        ch_long_reads.flatMap { it.long_reads.collect { long_file -> tuple(it.meta, long_file) } }, by: 0
    ).map { meta, scaffolds, long_reads -> tuple(meta, long_reads, scaffolds) }

    def ch_medaka_polished = MEDAKA(ch_medaka_input)
    def ch_reoriented = DNAAPLER(ch_medaka_polished)
    emit:
    final_output=ch_reoriented

}

































