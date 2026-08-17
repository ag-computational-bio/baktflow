#!/usr/bin/env nextflow

process REPORTS {
    tag "$meta.sample_id" + "#" + "$tool"
    publishDir "${params.output}/${meta.sample_id}/${tool}", mode: 'copy'
    conda "${projectDir}/modules/reports/environment.yaml"
    queue "${params.long_queue}"

    input:
        tuple val(meta), val(tool), path(files)

    output:
        path("*.json.gz"), emit: json

    script:
    if ( tool == 'amrfinderplus' )
        """
        parse_amrfinder.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'autocycler' )
        """
        parse_assembly.py ${files} ${meta.sample_id} autocycler
        """
    else if ( tool == 'checkm2' )
        """
        parse_checkm2.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'chewbbaca' )
        """
        parse_chewbbaca.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'dnaapler' )
        """
        parse_assembly.py ${files} ${meta.sample_id} dnaapler
        """
    else if ( tool == 'ectyper' )
        """
        parse_ectyper.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'filtlong' )
        """
        parse_assembly.py ${files} ${meta.sample_id} filtlong
        """
    else if ( tool == 'flye' )
        """
        parse_assembly.py ${files} ${meta.sample_id} flye
        """
    else if ( tool == 'gecco' )
        """
        parse_gecco.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'genomestats' && ( meta.sample_type == 'short' || meta.sample_type == 'long' ) )
        """
        parse_genomestats.py ${files} ${meta.sample_id} ${meta.sample_type}
        """
    else if (tool == 'genomestats' && meta.sample_type == 'hybrid' )
        """
        parse_genomestats.py ${files[0]} ${meta.sample_id} hybrid ${files[1]}
        """
    else if ( tool == 'gtdbtk' )
        """
        parse_gtdbtk.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'kleborate' )
        """
        parse_kleborate.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'macsyfinder' )
        """
        parse_macsyfinder.py ${files} ${meta.sample_id} ${meta.finder}
        """
    else if ( tool == 'medaka' )
        """
        parse_assembly.py ${files} ${meta.sample_id} medaka
        """
    else if ( tool == 'mob_suite' )
        """
        parse_mob.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'pling' )
        """
        parse_pling.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'polypolish' )
        """
        parse_assembly.py ${files} ${meta.sample_id} polypolish
        """
    else if ( tool == 'pypolca' )
        """
        parse_assembly.py ${files} ${meta.sample_id} pypolca
        """
    else if ( tool == 'referenceseeker' )
        """
        parse_referenceseeker.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'silva-16s' )
        """
        parse_silva16s.py ${files} ${meta.sample_id}
        """
    else if ( tool == 'unicycler' )
        """
        parse_assembly.py ${files} ${meta.sample_id} unicycler
        """
    else if ( tool == 'vfdb' )
        """
        parse_vfdb.py ${files} ${meta.sample_id}
        """
    else
        error "Invalid tool name: ${tool}"

    stub:
    """
    touch report-${meta.sample_id}.json.gz
    """
}
