#!/usr/bin/env nextflow

include {AUTOCYCLER_SUBSAMPLE} from '../modules/autocycler/main.nf'
include {AUTOCYCLER_ASSEMBLY} from '../modules/autocycler/main.nf'
include {AUTOCYCLER_CONSENSUS} from '../modules/autocycler/main.nf'

workflow AUTOCYCLER_SUBWORKFLOW {
    take:
        ch_long_reads

    main:
    ch_subsamples = AUTOCYCLER_SUBSAMPLE(ch_long_reads).subsamples.flatMap { meta, genomesize, s1, s2, s3, s4 ->
        [tuple(meta, genomesize, s1), tuple(meta, genomesize, s2), tuple(meta, genomesize, s3), tuple(meta, genomesize, s4)]
    }

    ch_assembler_input = channel.fromList(params.assemblers).combine(ch_subsamples)
    ch_assemblies = AUTOCYCLER_ASSEMBLY(ch_assembler_input).assembly.groupTuple(size: params.subsamples * params.assemblers.size())

    ch_final_assembly = AUTOCYCLER_CONSENSUS(ch_assemblies)

    emit:
        assembly_gfa = ch_final_assembly.gfa
        assembly_scaffolds = ch_final_assembly.assembly
        reports = ch_final_assembly.report
}