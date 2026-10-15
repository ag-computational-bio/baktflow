#!/usr/bin/env nextflow

include { NANOPLOT as NANOPLOT_RAW } from '../modules/nanoplot/main.nf'
include { NANOPLOT as NANOPLOT_FILTERED } from '../modules/nanoplot/main.nf'
include { FASTPLONG } from '../modules/fastplong/main.nf'
include { NANOLYSE } from '../modules/nanolyse/main.nf'
include { HOSTILE } from '../modules/hostile/main.nf'
include { SYLPH } from '../modules/sylph/main.nf'
include { MYLOASM } from '../modules/myloasm/main.nf'
include { MEDAKA } from '../modules/medaka/main.nf'
include { DNAAPLER } from '../modules/dnaapler/main.nf'
include { CONTIGMAPPING } from '../modules/contigmapping/main.nf'
include { METABINNER } from '../modules/metabinner/main.nf'
include { SEMIBIN } from '../modules/semibin/main.nf'
include { METACAT } from '../modules/metacat/main.nf'
include { METAWRAP } from '../modules/metawrap/main.nf'


workflow META_LONG_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_long_reads

    main:
    // Raw QC with NanoPlot
    NANOPLOT_RAW(channel.of('raw').combine(ch_long_reads.map { it -> tuple(it.meta, it.long_reads) }))

    // Trim long reads
    ch_trimmed_long_reads = FASTPLONG(ch_long_reads.map { it -> tuple(it.meta, it.long_reads) }).trimmed_long_reads

    // Host depletion
    if ( params.nanolyse == 'true' ) {
        ch_filtered_long_reads = NANOLYSE(ch_trimmed_long_reads).filtered_reads
        ch_delpeted_long_reads = HOSTILE(ch_filtered_long_reads).depleted_reads
    } else {
        ch_delpeted_long_reads = HOSTILE(ch_trimmed_long_reads).depleted_reads
    }
    ch_keyed_long_reads = ch_delpeted_long_reads.map { meta, long_reads ->
        tuple(meta.sample_id, long_reads)
    }    

    // Raw QC with NanoPlot
    NANOPLOT_FILTERED(channel.of('filtered').combine(ch_delpeted_long_reads))

    // Get taxonomy of reads
    SYLPH(ch_delpeted_long_reads)

    // Assembly with Myloasm
    MYLOASM(ch_delpeted_long_reads)
    ch_medaka_input = MYLOASM.out.fasta.map { meta, assembly ->
        tuple(meta.sample_id, meta, assembly)
    }.join(ch_keyed_long_reads).map { _sample_id, meta, assembly, long_reads -> tuple(meta, long_reads, assembly) }

    // Polish with Medaka
    ch_medaka_polished = MEDAKA(ch_medaka_input).fasta
    
    // Reorient GFA with DNAAPLER
    ch_reoriented = DNAAPLER(ch_medaka_polished)

    ch_contigmapping_input = ch_reoriented.fasta.map { meta, assembly ->
        tuple(meta.sample_id, meta, assembly)
    }.join(ch_keyed_long_reads).map { _sample_id, meta, assembly, long_reads -> tuple(meta, assembly, long_reads) }

    // Map reads to assembly
    ch_mapped_reads = CONTIGMAPPING(ch_contigmapping_input).mapped_reads

    // Binning
    ch_binner_input = ch_reoriented.fasta.map { meta, assembly ->
        tuple(meta.sample_id, meta, assembly)
    }.join(ch_mapped_reads.map { meta, bai, bam -> tuple(meta.sample_id, bai, bam) })
    .map { _sample_id, meta, assembly, bai, bam -> tuple(meta, assembly, bai, bam) }

    METABINNER(ch_binner_input)
    SEMIBIN(ch_binner_input)
    METACAT(ch_binner_input)

    // Bin refinement
    ch_metawrap_input = METABINNER.out.bins.map{ meta, bins -> tuple(meta.sample_id, meta, bins) }
    .join(SEMIBIN.out.bins.map{ meta, bins -> tuple(meta.sample_id, bins) })
    .join(METACAT.out.bins.map{ meta, bins -> tuple(meta.sample_id, bins) })
    .map { _sample_id, meta, metabinner_bins, semibin_bins, metacat_bins -> tuple(meta, metabinner_bins, semibin_bins, metacat_bins) }
    METAWRAP(ch_metawrap_input)

    ch_binned_genomes = METAWRAP.out.bins.transpose().map{ meta, metabinned_genome ->
        def new_meta = [
            sample_id: meta.sample_id + "-" + metabinned_genome.baseName,
            sample_type: meta.sample_type,
        ]
        return tuple(new_meta, metabinned_genome)
    }

   ch_binned_genomes_report = ch_binned_genomes.map{ meta, metabinned_genome -> tuple(meta, 'metawrap', metabinned_genome) }

    if ( params.nanolyse == 'true' ) {
        ch_reports = NANOLYSE.out.report.mix(
            HOSTILE.out.report, MYLOASM.out.report, MEDAKA.out.report, ch_reoriented.report, ch_binned_genomes_report
        )
    } else {
        ch_reports = HOSTILE.out.report.mix(
            MYLOASM.out.report, MEDAKA.out.report, ch_reoriented.report, ch_binned_genomes_report
        )
    }

    emit:
        assembly_gfa = MYLOASM.out.gfa
        assembly_fasta = ch_binned_genomes
        //assembly_fastq = ch_medaka_polished.fastq
        reports = ch_reports

}
