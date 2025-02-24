#!/usr/bin/env nextflow
nextflow.enable.dsl=2
include { FASTQC} from '../modules/fastqc/main.nf' 
include { FASTP} from '../modules/fastp/main.nf' 
include { UNICYCLER} from '../modules/unicycler/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf' 

workflow SHORT_READ_PROCESSING_SUBWORKFLOW {
    take:
    ch_short_reads

    main:
    def ch_fastqc_results = ch_short_reads.flatMap { sample -> 
        [tuple(sample.meta, sample.r1), tuple(sample.meta, sample.r2)] 
    } | FASTQC

    // Process the short reads with FASTP
    def ch_processed_reads = FASTP(ch_short_reads.map { sample -> 
        tuple(sample.meta, sample.r1, sample.r2)
    })
    def short_reads_for_assembly = ch_processed_reads.processed_reads

    // Pass R1, R2, and an empty list for long_reads to UNICYCLER
    def ch_unicycler_input = short_reads_for_assembly.map { processed ->
        def (meta, r1_processed, r2_processed) = processed
        tuple(meta, r1_processed, r2_processed, [])  // Empty list for long_reads
    }

    // Assemble with UNICYCLER
    def ch_scaffolds = UNICYCLER(ch_unicycler_input).scaffolds

    // Reorient the scaffolds with DNAAPLER
    def ch_reoriented = DNAAPLER(ch_scaffolds)

    // Emit the final output
    emit:
    final_output = ch_reoriented
}






























