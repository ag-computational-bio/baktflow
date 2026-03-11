#!/usr/bin/env nextflow

include { HYBRID_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/hybrid_reads_subworkflows.nf'
include { SHORT_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/short_reads_subworkflows.nf'
include { LONG_READ_PROCESSING_SUBWORKFLOW } from './subworkflows/long_reads_subworkflows.nf'
include {BAKTA} from './modules/bakta/main.nf' 
log.info """
    BAKTFLOW   P I P E L I N E
    ===================================
    inputTsv    : ${params.inputTsv}
    output      : ${params.output}
    """.stripIndent()


workflow {
    // Parse the input TSV file with absolute paths
    ch_samples = Channel
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
                long_reads: long_file ? [long_file] : [],
                assembly: assembly_file
            ]
        }

    // Classify samples based on sample_type
    ch_short_reads = ch_samples.filter { it.meta.sample_type == 'short' }
    ch_long_reads = ch_samples.filter { it.meta.sample_type == 'long' }
    ch_hybrid_reads = ch_samples.filter { it.meta.sample_type == 'hybrid' }
    ch_assemblies = ch_samples.filter { it.meta.sample_type == 'assembly' }
        .map { sample ->
            // Modify the assembly channel to include only meta and assembly path
            return [
                meta: sample.meta,  // Only include metadata
                assembly: sample.assembly // Only include the assembly path
            ]
        }

    // Process each type of read and gather the outputs
    final_short_output = ch_short_reads ? SHORT_READ_PROCESSING_SUBWORKFLOW(ch_short_reads) : Channel.empty()
    final_long_output = ch_long_reads ? LONG_READ_PROCESSING_SUBWORKFLOW(ch_long_reads) : Channel.empty()
    final_hybrid_output = ch_hybrid_reads ? HYBRID_READ_PROCESSING_SUBWORKFLOW(ch_hybrid_reads) : Channel.empty()

    // Combine all outputs into a single channel
    combined_output = Channel
        .empty()
        .mix(final_short_output, final_long_output, final_hybrid_output, ch_assemblies)

    // Call BAKTA with the combined output channel
    BAKTA(combined_output)
}

workflow.onComplete {
    def separator = "=".repeat(60) // Creates a 60-character separator line
    
    log.info "\n${separator}"
    println "Pipeline completed at: ${workflow.complete ?: 'Unknown Completion Time'}"
    log.info "Check Output Directory: ${params.output ?: 'Unknown Output Directory'}"
    log.info "Duration: ${workflow.duration ?: 'Unknown Duration'}"
    log.info "Success: ${workflow.success ?: 'Unknown Status'}"
    log.info "Launch Dir: ${workflow.launchDir ?: 'Unknown Launch Directory'}"
    log.info "${separator}\n"
}
