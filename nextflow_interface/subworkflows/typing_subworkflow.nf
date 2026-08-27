#!/usr/bin/env nextflow

include {ECTYPER} from '../modules/ectyper/main.nf'
include {KLEBORATE} from '../modules/kleborate/main.nf'
include {MASKING} from '../modules/masking/main.nf'
include {CHEWBBACA} from '../modules/chewbbaca/main.nf'

workflow TYPING_SUBWORKFLOW {
    take:
        ch_input
        ch_short_assembly_fastq
        ch_long_assembly_fastq
        ch_hybrid_assembly_fastq
        _ch_assembly

    main:
        // Create empty stub files
        String[] emptyFiles = ["empty_R1.fastq.gz", "empty_R2.fastq.gz", "empty_SE.fastq.gz", "empty_long.fastq.gz"]
        emptyFiles.each { fh ->
            if ( ! file(fh).exists() ) {
                file(fh).setText('')
            }
        }

        ch_reads_and_assemblies = ch_short_assembly_fastq.map { meta, r1, r2, se ->
            tuple(meta, r1, r2, se, file("empty_long.fastq.gz"))
        }.mix(ch_long_assembly_fastq.map { meta, long_fastq ->
            tuple(meta, file("empty_R1.fastq.gz"), file("empty_R2.fastq.gz"), file("empty_SE.fastq.gz"), long_fastq)
        }).mix(ch_hybrid_assembly_fastq).map { meta, r1, r2, se, long_reads ->
            tuple(meta.sample_id, meta, r1, r2, se, long_reads)
        }
        // TODO handle _ch_assembly

        ch_chewbacca_organisms = channel.fromPath(
            "${params.databaseDir}/chewBBACA/*",
            maxDepth: 1,
            type: "dir"
        ).map{ subDbPath -> subDbPath.baseName }
        ch_chewbacca = ch_input.combine(ch_chewbacca_organisms).filter { meta, _assembly, chewbacca_organism ->
            chewbacca_organism.replace("_", " ").replaceAll("\\s+","") == meta.species.replaceAll("\\s+","")
        }.map { meta, assembly, chewbacca_organism ->
            tuple(meta.sample_id, meta, assembly, chewbacca_organism)
        }.join(ch_reads_and_assemblies).map { _sample_id, meta, assembly, chewbacca_organism, _meta, r1, r2, se, long_reads ->
            tuple(meta, assembly, chewbacca_organism, r1, r2, se, long_reads)
        }

        ch_e_coli = ch_input.filter { meta, _assembly -> meta.species.strip() == "Escherichia coli" }
        ch_klebsiella = ch_input.filter { meta, _assembly -> meta.taxonomy[5].strip() == "Klebsiella" }

        ECTYPER(ch_e_coli)
        KLEBORATE(ch_klebsiella)

        MASKING(ch_chewbacca)
        CHEWBBACA(MASKING.out.assembly)

    emit:
        reports = CHEWBBACA.out.report.map { it -> return [it[0], it[1], it[2..-1]] }.mix(MASKING.out.report).mix(
            ECTYPER.out.report).mix(KLEBORATE.out.report)
}