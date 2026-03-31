#!/usr/bin/env nextflow

include { HYBRID_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/hybrid_reads_subworkflows.nf'
include { SHORT_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/short_reads_subworkflows.nf'
include { LONG_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/long_reads_subworkflows.nf'
include { BAKTA } from './modules/bakta/main.nf'


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
    ch_short_output = SHORT_READ_PROCESSING_SUBWORKFLOW(ch_short_reads)
    ch_long_output = LONG_READ_PROCESSING_SUBWORKFLOW(ch_long_reads)
    ch_hybrid_output = HYBRID_READ_PROCESSING_SUBWORKFLOW(ch_hybrid_reads)

    // Combine all outputs into a single channel
    combined_output = ch_short_output.mix(ch_long_output, ch_hybrid_output, ch_assemblies)

    // Call BAKTA with the combined output channel
    BAKTA(combined_output)

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
