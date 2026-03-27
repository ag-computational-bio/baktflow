#!/usr/bin/env nextflow

include {FASTQC} from '../modules/fastqc/main.nf'
include {FASTP} from '../modules/fastp/main.nf'
include {FILTLONG} from '../modules/filtlong/main.nf'
include {UNICYCLER} from '../modules/unicycler/main.nf'
include {MEDAKA} from '../modules/medaka/main.nf'
include {POLYPOLISH} from '../modules/polypolish/main.nf'
include {PYPOLCA} from '../modules/pypolca/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf'
 
// Hybrid Read Processing Subworkflow
workflow HYBRID_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_hybrid_reads

    main:
    // Perform FastQC analysis on hybrid reads
        FASTQC(ch_hybrid_reads.flatMap { sample ->
            [tuple(sample.meta, sample.r1), tuple(sample.meta, sample.r2)]
        })

        // Separate short and long reads
        short_read_samples = ch_hybrid_reads.filter { it -> it.r1 && it.r2 }
        long_read_samples = ch_hybrid_reads.filter { it -> !it.long_reads.isEmpty() }

        // Process short and long reads using FastP and Filtlong
        ch_processed_short_reads = FASTP(short_read_samples.map { sample -> 
            tuple(sample.meta, sample.r1, sample.r2)
        })
        ch_filtered_long_reads = FILTLONG(long_read_samples.map { sample -> 
            tuple(sample.meta, sample.long_reads)
        })

        // Get processed reads for assembly
        short_reads_for_assembly = ch_processed_short_reads.processed_reads
        long_reads_for_assembly = ch_filtered_long_reads.filtered_long_reads

        // Key channels with sample_id for easy joining
        ch_keyed_short_reads = short_reads_for_assembly.map { meta, r1, r2, se, _long ->
            tuple(meta.sample_id, meta, r1, r2, se)
        }
        ch_keyed_long_reads = long_reads_for_assembly.map { meta, long_reads -> 
            tuple(meta.sample_id, meta, long_reads) 
        }

        // Combine short and long reads based on sample_id
        combined_reads = ch_keyed_short_reads.join(ch_keyed_long_reads)
            .map { _sample_id, meta_short, r1, r2, se, _meta_long, long_reads ->
                tuple('hybrid', meta_short, r1, r2, se, long_reads)
            }

        // Unicycler Assembly - combining short and long reads
        ch_assembled_scaffolds = UNICYCLER(combined_reads)
        ch_scaffolds_for_medaka = ch_assembled_scaffolds.scaffolds

        // Combine scaffolds with long reads for Medaka polishing
        ch_combined_for_medaka = ch_scaffolds_for_medaka.map { meta, scaffolds -> 
            tuple(meta.sample_id, meta, scaffolds) 
        }.join(ch_keyed_long_reads)
            .map { _sample_id, meta, scaffolds, _meta_long, long_reads ->
                tuple(meta, long_reads, scaffolds) 
            }

        // Medaka Polishing
        ch_polished_with_medaka = MEDAKA(ch_combined_for_medaka)
        ch_medaka_polished = ch_polished_with_medaka.input_fasta

        // Combine Medaka-polished assembly with short reads for Pypolca polishing
        ch_combined_for_pypolca = ch_medaka_polished.map { meta, input_fasta ->
            tuple(meta.sample_id, meta, input_fasta)
        }.join(ch_keyed_short_reads)
            .map { _sample_id, meta, input_fasta, _meta_short, r1, r2, _se ->
                tuple(meta, input_fasta, r1, r2) 
            }

        // Pypolca Polishing
        ch_pypolca_polished = PYPOLCA(ch_combined_for_pypolca).short_pypolca

        // Combine Medaka-polished assembly with short reads for Pypolca polishing
        ch_combined_for_pollypolish = ch_pypolca_polished.map { meta, short_pypolca ->
            tuple(meta.sample_id, meta, short_pypolca)
        }.join(ch_keyed_short_reads)
            .map { _sample_id, meta, short_pypolca, _meta_short, r1, r2, se ->
                tuple(meta, short_pypolca, r1, r2, se)
            }

        // Final Polishing with Polypolish
        ch_final_polished_assembly = POLYPOLISH(ch_combined_for_pollypolish)
        
        ch_reoriented = DNAAPLER(ch_final_polished_assembly)

        emit:
            final_output = ch_reoriented.assembly
}
