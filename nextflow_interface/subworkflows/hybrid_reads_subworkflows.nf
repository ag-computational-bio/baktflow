#!/usr/bin/env nextflow

include {FASTP} from '../modules/fastp/main.nf'
include {FILTLONG} from '../modules/filtlong/main.nf'
include {GENOMESTATS} from '../modules/genomestats/main.nf'
include {UNICYCLER} from '../modules/unicycler/main.nf'
include {AUTOCYCLER_SUBWORKFLOW} from './autocycler_subworkflow.nf'
include {POLYPOLISH} from '../modules/polypolish/main.nf'
include {PYPOLCA} from '../modules/pypolca/main.nf'
include {DNAAPLER} from '../modules/dnaapler/main.nf'
 
// Hybrid Read Processing Subworkflow
workflow HYBRID_READ_PROCESSING_SUBWORKFLOW {
    take:
        ch_hybrid_reads

    main:
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
        // Key channels with sample_id for easy joining
        ch_keyed_short_reads = ch_processed_short_reads.trimmed_reads.map { meta, r1, r2, se ->
            tuple(meta.sample_id, meta, r1, r2, se)
        }
        ch_keyed_long_reads = ch_filtered_long_reads.filtered_long_reads.map { meta, long_reads ->
            tuple(meta.sample_id, long_reads)
        }
        combined_reads = ch_keyed_short_reads.join(ch_keyed_long_reads)
            .map { _sample_id, meta_short, r1, r2, se, long_reads ->
                tuple(meta_short, r1, r2, se, long_reads)
            }

        ch_genomestats = GENOMESTATS(combined_reads).hybrid_genome_size

        /*
        Assembly based on read set depths
        shallow: 0–50×, medium: 50–100×, deep: >100×
        - short-read set is deep but your long-read set is shallow -> Unicycler hybrid assembly
        - Long-read-first hybrid assembly -> Long-read-first hybrid assembly (long-read-only assembly followed by short-read polishing)
        - Shallow reads -> ?
        */

        ch_unicycler_input = ch_genomestats.filter { _meta, genomesize, _short_coverage, _long_coverage, _r1, _r2, _se, _long_reads ->
            genomesize.toInteger() == 1
        }.map { meta, genomesize, _short_coverage, _long_coverage, r1, r2, se, long_reads ->
            tuple(meta, genomesize, r1, r2, se, long_reads)
        }

        ch_assembler_input = ch_genomestats.filter { _meta, genomesize, _short_coverage, _long_coverage, _r1, _r2, _se, _long_reads ->
            genomesize.toInteger() > 1
        }.branch { _meta, _genomesize, short_coverage, long_coverage, _r1, _r2, _se, _long_reads ->
            autocycler: long_coverage.toInteger() >= 50
            unicycler: short_coverage.toInteger() >= 50
            other: true  // for now use unicycler for assembly
        }

        // Hybrid Unicycler Assembly
        ch_assembly_unicylcer = UNICYCLER(ch_unicycler_input.mix(
            ch_assembler_input.unicycler.map { meta, _genomesize, _short_coverage, _long_coverage, r1, r2, se, long_reads ->
                tuple(meta, r1, r2, se, long_reads)
            }
        ).mix(
            ch_assembler_input.other.map { meta, _genomesize, _short_coverage, _long_coverage, r1, r2, se, long_reads ->
                tuple(meta, r1, r2, se, long_reads)
            }
        )).scaffolds

        // Long read only Assembly with Autocycler with short read polishing
        ch_autocycler_assembly = AUTOCYCLER_SUBWORKFLOW(ch_assembler_input.autocycler
        .map { meta, genomesize, _short_coverage, _long_coverage, _r1, _r2, _se, long_reads ->
            tuple(meta, genomesize, long_reads)
        }).map { meta, assembly, _closed -> tuple(meta, assembly) }

        // Combine assembly with short reads for Pypolca polishing
        ch_combined_for_pypolca = ch_autocycler_assembly.map { meta, scaffolds ->
            tuple(meta.sample_id, meta, scaffolds)
        }.join(ch_keyed_short_reads)
            .map { _sample_id, meta, scaffolds, _meta_short, r1, r2, _se ->
                tuple(meta, scaffolds, r1, r2)
            }

        // Pypolca Polishing
        ch_pypolca_polished = PYPOLCA(ch_combined_for_pypolca).short_pypolca

        // Combine Pypolca-polished assembly with short reads for Polypolish polishing
        ch_combined_for_pollypolish = ch_pypolca_polished.map { meta, pypolca ->
            tuple(meta.sample_id, meta, pypolca)
        }.join(ch_keyed_short_reads)
            .map { _sample_id, meta, pypolca, _meta_short, r1, r2, se ->
                tuple(meta, pypolca, r1, r2, se)
            }

        // Final Polishing with Polypolish
        ch_final_polished_assembly = POLYPOLISH(ch_combined_for_pollypolish).polished_output
        
        ch_reoriented = DNAAPLER(ch_assembly_unicylcer.mix(ch_final_polished_assembly))

        emit:

            final_output = ch_reoriented.assembly
}