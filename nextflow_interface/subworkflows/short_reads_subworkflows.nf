#!/usr/bin/env nextflow

include {FASTQC} from '../modules/fastqc/main.nf'
include {FASTP} from '../modules/fastp/main.nf'
include {UNICYCLER} from '../modules/unicycler/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf' 

workflow SHORT_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_short_reads

    main:
        FASTQC(ch_short_reads.flatMap { sample ->
            [tuple(sample.meta, sample.r1), tuple(sample.meta, sample.r2)]
        })

        // Process the short reads with FASTP
        // TODO replace FASTQC with fastp
        // TODO add multiqc pre and post trimming
        ch_trimmed_reads = FASTP(ch_short_reads.map { sample ->
            tuple(sample.meta, sample.r1, sample.r2)
        })

        // Pass R1, R2, SE, and empty long_reads to UNICYCLER
        ch_unicycler_input = ch_trimmed_reads.trimmed_reads.map { meta, r1, r2, se ->
            tuple(meta, r1, r2, se, file("empty.long.fq.gz"))
        }

        // Assemble with UNICYCLER
        ch_scaffolds = UNICYCLER(ch_unicycler_input).scaffolds

        // Reorient the scaffolds with DNAAPLER
        ch_reoriented = DNAAPLER(ch_scaffolds)

    // Emit the final output
    emit:

        final_output = ch_reoriented.assembly
}