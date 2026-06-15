#!/usr/bin/env nextflow

include {ECTYPER} from '../modules/ectyper/main.nf'
include {KLEBORATE} from '../modules/kleborate/main.nf'
include {CHEWBBACA} from '../modules/chewbbaca/main.nf'

workflow TYPING_SUBWORKFLOW {
    take:
        ch_input

    main:
        ch_chewbacca_organisms = channel.fromPath(
            "${params.databaseDir}/chewBBACA/*",
            maxDepth: 1,
            type: "dir"
        ).map{ subDbPath -> subDbPath.baseName }
        ch_chewbacca = ch_input.combine(ch_chewbacca_organisms).filter { meta, _assembly, chewbacca_organism -> chewbacca_organism == meta.species.replace(" ", "_") }
        
        ch_e_coli = ch_input.filter { meta, _assembly -> meta.species == "Escherichia coli" }
        ch_klebsiella = ch_input.filter { meta, _assembly -> meta.taxonomy[5] == "Klebsiella" }

        ECTYPER(ch_e_coli)
        KLEBORATE(ch_klebsiella)

        CHEWBBACA(ch_chewbacca)

}