#!/usr/bin/env nextflow

include {FILTLONG} from '../modules/filtlong/main.nf'
include {GENOMESTATS} from '../modules/genomestats/main.nf'
include {FLYE} from '../modules/flye/main.nf'
include {MINIASM} from '../modules/miniasm/main.nf'
include {AUTOCYCLER_SUBWORKFLOW} from './autocycler_subworkflow.nf'
include {MEDAKA} from '../modules/medaka/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf'


workflow LONG_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_long_reads

    main:
    // Step 0: Create empty stub files
    String[] emptyFiles = ["empty_R1.fastq.gz", "empty_R2.fastq.gz", "empty_SE.fastq.gz"]
    emptyFiles.each { fh ->
        file(fh).setText('')
    }

    // Step 1: Filter long reads
    ch_filtered_long_reads = FILTLONG(ch_long_reads.map { it -> tuple(it.meta, it.long_reads) }).filtered_long_reads

    ch_filtered_long_reads_with_short_stubs = ch_filtered_long_reads.map { meta, long_reads ->
        tuple(meta, file("empty_R1.fastq.gz"), file("empty_R2.fastq.gz"), file("empty_SE.fastq.gz"), long_reads)
    }

    ch_genomestats = GENOMESTATS(ch_filtered_long_reads_with_short_stubs).long_genome_size

    ch_flye_input = ch_genomestats.filter { _meta, genomesize, coverage, _long_reads ->
        genomesize.toInteger() == 1 || coverage.toInteger() < params.minReadDepth
    }

    ch_autocycler_input = ch_genomestats.filter { _meta, genomesize, coverage, _long_reads ->
        genomesize.toInteger() > 1 && coverage.toInteger() >= params.minReadDepth
    }.map { meta, genomesize, _coverage, long_reads ->
        tuple(meta, genomesize, long_reads)
    }

    // Step 2: Assemble with Flye or Autocycler
    ch_autocycler_assembly = AUTOCYCLER_SUBWORKFLOW(ch_autocycler_input).map { meta, assembly, _closed ->
        tuple(meta, assembly)
    }

    ch_flye_assembly = FLYE(ch_flye_input).scaffolds

    // Step 3: Polish with Medaka (only scaffolds + long reads)
    ch_keyed_assembly = ch_flye_assembly.mix(ch_autocycler_assembly).map { meta, assembly ->
        tuple(meta.sample_id, meta, assembly)
    }
    ch_keyed_long_reads = ch_filtered_long_reads.map { meta, long_reads ->
        tuple(meta.sample_id, long_reads)
    }
    ch_combined_reads = ch_keyed_assembly.join(ch_keyed_long_reads)
    .map { _sample_id, meta, assembly, long_reads ->
        tuple(meta, long_reads, assembly)
    }

    ch_medaka_polished = MEDAKA(ch_combined_reads)
    ch_reoriented = DNAAPLER(ch_medaka_polished)

    emit:
        final_output = ch_reoriented.assembly
}