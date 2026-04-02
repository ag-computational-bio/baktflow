#!/usr/bin/env nextflow

include {FILTLONG} from '../modules/filtlong/main.nf'
include {FLYE} from '../modules/flye/main.nf' 
include {MEDAKA} from '../modules/medaka/main.nf' 
include {DNAAPLER} from '../modules/dnaapler/main.nf' 


workflow LONG_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_long_reads

    main:
    // Step 1: Filter long reads
    ch_filtered_long_reads = FILTLONG(ch_long_reads.map { it -> tuple(it.meta, it.long_reads) })

    // Step 2: Assemble with Flye
    // TODO dragonflye
    // TODO pcbio nanopore input handling
    flye_assembly = FLYE(ch_filtered_long_reads.filtered_long_reads)

    // Step 3: Polish with Medaka (only scaffolds + long reads)
    ch_keyed_assembly = flye_assembly.scaffolds.map { meta, assembly ->
        tuple(meta.sample_id, meta, assembly)
    }
    ch_keyed_long_reads = ch_filtered_long_reads.filtered_long_reads.map { meta, long_reads ->
        tuple(meta.sample_id, meta, long_reads)
    }
    ch_combined_reads = ch_keyed_assembly.join(ch_keyed_long_reads)
    .map { _sample_id, meta_assembly, assembly, _meta_long, long_reads ->
        tuple(meta_assembly, long_reads, assembly)
    }

    ch_medaka_polished = MEDAKA(ch_combined_reads)
    ch_reoriented = DNAAPLER(ch_medaka_polished)

    emit:
        final_output = ch_reoriented.assembly
}