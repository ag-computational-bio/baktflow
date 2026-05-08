#!/usr/bin/env nextflow

include { HYBRID_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/hybrid_reads_subworkflows.nf'
include { SHORT_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/short_reads_subworkflows.nf'
include { LONG_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/long_reads_subworkflows.nf'
include { BAKTA } from './modules/bakta/main.nf'
include { MLST } from './modules/mlst/main.nf'
include { MOB_SUITE } from './modules/mob_suite/main.nf'
include { SKA } from './modules/ska/main.nf'
include { RGI } from './modules/rgi/main.nf'
include { AMRFINDERPLUS } from './modules/amrfinderplus/main.nf'
include { DIAMOND } from './modules/diamond/main.nf'
include { CHECKM2 } from './modules/checkm2/main.nf'
include { PLATON } from './modules/platon/main.nf'
include { BLAST } from './modules/blast/main.nf'
include { BANDAGE } from './modules/bandage/main.nf'
include { PLING } from './modules/pling/main.nf'
include { PMLST } from './modules/pmlst/main.nf'
include { REFERENCESEEKER} from './modules/referenceseeker/main.nf'
include { CASFINDER } from './modules/macsyfinder/main.nf'
include { TXSSCAN } from './modules/macsyfinder/main.nf'
include { CONJSCAN } from './modules/macsyfinder/main.nf'
include { GTDBTK } from './modules/gtdbtk/main.nf'
include { PLASMIDFINDER } from './modules/plasmidfinder/main.nf'


workflow {
    log.info """
        BAKTFLOW   P I P E L I N E
        ===================================
        inputTsv    : ${params.inputTsv}
        output      : ${params.output}
    """.stripIndent()

    // Parse the input TSV file with absolute paths
    ch_samples = channel
        .fromPath(params.inputTsv)  // Path to the TSV file
        .splitCsv(header: false, sep: '\t')  // Splitting by tab
        .map { row ->
            // Extracting metadata from each row
            def sample_id = row[0]?.trim()
            def sample_type = row[1]?.trim()
            def r1 = row[2]?.trim() ? file(row[2].trim()) : null
            def r2 = row[3]?.trim() ? file(row[3].trim()) : null
            def long_file = row[4]?.trim() ? file(row[4].trim()) : null
            def assembly_file = row[5]?.trim() ? file(row[5].trim()) : null

            // Create metadata object for each sample
            def meta = [
                sample_id: sample_id,
                sample_type: sample_type,
            ]

            return [
                meta: meta,
                r1: r1,
                r2: r2,
                long_reads: long_file,
                assembly: assembly_file
            ]
        }

    // Classify samples based on sample_type
    ch_short_reads = ch_samples.filter { it -> it.meta.sample_type == 'short' }
    ch_long_reads = ch_samples.filter { it -> it.meta.sample_type == 'long' }
    ch_hybrid_reads = ch_samples.filter { it -> it.meta.sample_type == 'hybrid' }
    ch_assemblies = ch_samples.filter { it -> it.meta.sample_type == 'assembly' }
        .map { sample ->
            // Modify the assembly channel to include only meta and assembly path
            return [
                meta: sample.meta,  // Only include metadata
                assembly: sample.assembly // Only include the assembly path
            ]
        }

    // Process each type of read and gather the outputs
    ch_short_processed = SHORT_READ_PROCESSING_SUBWORKFLOW(ch_short_reads)
    ch_short_output = ch_short_processed.final_output
    ch_short_gfa = ch_short_processed.assembly_gfa

    ch_long_processed = LONG_READ_PROCESSING_SUBWORKFLOW(ch_long_reads)
    ch_long_output = ch_long_processed.final_output
    ch_long_gfa = ch_long_processed.assembly_gfa

    ch_hybrid_processed = HYBRID_READ_PROCESSING_SUBWORKFLOW(ch_hybrid_reads)
    ch_hybrid_output = ch_hybrid_processed.final_output
    ch_hybrid_gfa = ch_hybrid_processed.assembly_gfa

    // Combine all outputs into a single channel
    combined_output = ch_short_output.mix(ch_long_output, ch_hybrid_output, ch_assemblies)
    combined_gfa = ch_short_gfa.mix(ch_long_gfa, ch_hybrid_gfa)

    // Call BAKTA with the combined output channel
    bakta_annotation = BAKTA(combined_output)

    // Call MLST with the combined output channel
    MLST(combined_output)

    // Call MOB_RECON with the combined output channel
    mob_results = MOB_SUITE(combined_output)

    // Call SKA with the combined output channel
    SKA(combined_output)

    // Call RGI with the combined output channel
    RGI(combined_output)

    // Call CheckM2
    CHECKM2(bakta_annotation.faa)

    // Call ReferenceSeeker (bacteria refseq database)
    REFERENCESEEKER(combined_output)

    //Call AMRFINDERPLUS
    amr_input = bakta_annotation.gff
        .join(bakta_annotation.faa)
        .join(bakta_annotation.fna)

    AMRFINDERPLUS(amr_input)

    // Call DIAMOND (VF database)
    DIAMOND(bakta_annotation.faa)

    // Call PLATON
    PLATON(combined_output)

    // Call BLAST (SILVA database)
    BLAST(bakta_annotation.ffn)

    //Call Bandage
    BANDAGE(combined_gfa)

    // Call MacSyFinder using TXSSCAN model
    TXSSCAN(bakta_annotation.faa)

    // Call MacSyFinder using CASFINDER model
    CASFINDER(bakta_annotation.faa)

    // Call MacSyFinder using CONJSCAN model
    CONJSCAN(bakta_annotation.faa)

    // Call PLING
    // PLING(mob_results.plasmids)

    //Call pMLST
    PMLST(combined_output)

    GTDBTK(combined_output)

    PLASMIDFINDER(combined_output)

    /*
    workflow.onComplete {
        def separator = "=" * 60 // Creates a 60-character separator line
        log.info "\n${separator}"
        log.info "Pipeline completed at: ${workflow.complete}"
        log.info "Check Output Directory: ${params.output}"
        log.info "Duration: ${workflow.duration}"
        log.info "Success: ${workflow.success}"
        log.info "Launch Dir: ${workflow.launchDir}"
        log.info "${separator}\n"
    }
    */
}