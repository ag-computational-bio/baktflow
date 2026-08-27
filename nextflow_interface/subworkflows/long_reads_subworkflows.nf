#!/usr/bin/env nextflow

include {FASTPLONG} from '../modules/fastplong/main.nf'
include {FILTLONG} from '../modules/filtlong/main.nf'
include {GENOMESTATS} from '../modules/genomestats/main.nf'
include {FLYE} from '../modules/flye/main.nf'
include {AUTOCYCLER_SUBWORKFLOW} from './autocycler_subworkflow.nf'
include {MEDAKA} from '../modules/medaka/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf'


workflow LONG_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_long_reads

    main:
    // Create empty stub files
    String[] emptyFiles = ["empty_R1.fastq.gz", "empty_R2.fastq.gz", "empty_SE.fastq.gz"]
    emptyFiles.each { fh ->
        file(fh).setText('')
    }

    // Trim and filter long reads
    if ( params.longReadTrimming.toBoolean() ) {
        ch_trimmed_long_reads = FASTPLONG(ch_long_reads.map { it -> tuple(it.meta, it.long_reads) }).trimmed_long_reads
        ch_filtered_long_reads = FILTLONG(ch_trimmed_long_reads).filtered_long_reads
    } else {
        ch_filtered_long_reads = FILTLONG(ch_long_reads.map { it -> tuple(it.meta, it.long_reads) }).filtered_long_reads
    }

    ch_filtered_long_reads_with_short_stubs = ch_filtered_long_reads.map { meta, long_reads ->
        tuple(meta, file("empty_R1.fastq.gz"), file("empty_R2.fastq.gz"), file("empty_SE.fastq.gz"), long_reads)
    }

    ch_genomestats = GENOMESTATS(ch_filtered_long_reads_with_short_stubs).long_genome_size
    ch_genomestats_reports = GENOMESTATS.out.report.mix(GENOMESTATS.out.report_hybrid.map { it -> return [it[0], it[1], it[2..-1]] })

    ch_flye_input = ch_genomestats.filter { _meta, genomesize, coverage, _long_reads ->
        genomesize.toInteger() == 1 || coverage.toInteger() < params.minReadDepth
    }

    ch_autocycler_input = ch_genomestats.filter { _meta, genomesize, coverage, _long_reads ->
        genomesize.toInteger() > 1 && coverage.toInteger() >= params.minReadDepth
    }.map { meta, genomesize, _coverage, long_reads ->
        tuple(meta, genomesize, long_reads)
    }

    // Assemble with Flye or Autocycler
    ch_autocycler = AUTOCYCLER_SUBWORKFLOW(ch_autocycler_input)
    ch_flye = FLYE(ch_flye_input)

    // Reorient GFA with DNAAPLER
    ch_reoriented = DNAAPLER(ch_flye.gfa.mix(ch_autocycler.assembly_gfa))

    // Polish with Medaka (only scaffolds + long reads)
    ch_keyed_assembly = ch_reoriented.fasta.map { meta, fasta ->
        tuple(meta.sample_id, meta, fasta)
    }
    ch_keyed_long_reads = ch_filtered_long_reads.map { meta, long_reads ->
        tuple(meta.sample_id, long_reads)
    }
    ch_combined_reads = ch_keyed_assembly.join(ch_keyed_long_reads)
    .map { _sample_id, meta, fasta, long_reads ->
        tuple(meta, long_reads, fasta)
    }

    // Polish with Medaka
    ch_medaka_polished = MEDAKA(ch_combined_reads)

    emit:
        assembly_gfa = ch_reoriented.gfa
        assembly_fasta = ch_medaka_polished.fasta
        assembly_fastq = ch_medaka_polished.fastq
        reports = FILTLONG.out.report.mix(ch_genomestats_reports).mix(ch_autocycler.reports).mix(ch_flye.report).mix(
            ch_reoriented.report).mix(ch_medaka_polished.report)
}
