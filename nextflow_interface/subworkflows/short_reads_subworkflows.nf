#!/usr/bin/env nextflow

include {FASTP} from '../modules/fastp/main.nf'
include {UNICYCLER} from '../modules/unicycler/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf'

workflow SHORT_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_short_reads

    main:
        // Process the short reads with FASTP
        ch_trimmed_reads = FASTP(ch_short_reads.map { sample ->
            tuple(sample.meta, sample.r1, sample.r2)
        })

        // Pass R1, R2, SE, and empty long_reads to UNICYCLER
        ch_unicycler_input = ch_trimmed_reads.trimmed_reads.map { meta, r1, r2, se ->
            tuple(meta, r1, r2, se, file("empty.long.fq.gz"))
        }

        // Assemble with UNICYCLER
        assembly = UNICYCLER(ch_unicycler_input)

        // Reorient GFA with DNAAPLER
        ch_reoriented = DNAAPLER(assembly.gfa)

    // Emit the final output
    emit:
        reads_trimmed = ch_trimmed_reads.trimmed_reads
        assembly_gfa = ch_reoriented.gfa
        assembly_fasta = ch_reoriented.fasta
        reports = assembly.report.mix(ch_reoriented.report)
}