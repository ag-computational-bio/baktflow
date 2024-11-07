import java.nio.file.*


def chInputIllBranch = null
def chInputOntBranch = null
def chAssembly = null
def chAssemblyGraph = Channel.empty()
def chQcIllPlot = null


Path pathOutput = Paths.get(params.output).toAbsolutePath()
if(!Files.exists(pathOutput))
    Files.createDirectory(pathOutput)

if(params.setupdir == null) {
    println('Setup directory is null! Please provide the Baktflow setup directory via --params.setupdir')
    System.exit(-1)
}

def pathData = null
if(params.data != null) {
    pathData = Paths.get(params.data).toAbsolutePath()
    print("Data: ${pathData}")
}

if(params.sample != null) {
    
    def sample = params.sample
    print("Sample: ${sample}")
    print("Start single execution:")
    if(params.assembly != null) {
        
        def pathAssembly = params.assembly.trim()
        if(pathAssembly != null  &&  pathAssembly != 'None'  &&  pathAssembly != ''  &&  pathAssembly != '-') {
            print("Start assembly characterization:")
            chAssembly = Channel.of( [sample, pathAssembly] )
        }

        // Workflow channel creations
        chQcIllPlot = Channel.empty()
        chInputIllBranch = Channel.empty()
        chInputOntBranch = Channel.empty()

    } else if((params.r1 != null  &&  params.r2 != null)  ||  params.ont != null) {

        def pathR1 = null
        def pathR2 = null
        def pathOnt = null
        
        boolean ill = false
        if(params.r1 != null  &&  params.r2 != null) {
            pathR1 = params.r1.trim()
            pathR2 = params.r2.trim()
            if( pathR1 != null  &&  pathR1 != 'None'  &&  pathR1 != ''  &&  pathR1 != '-'  &&  pathR2 != null  &&  pathR2 != 'None'  &&  pathR2 != ''  &&  pathR2 != '-') {
                pathR1 = pathData != null ? pathData.resolve(pathR1).toAbsolutePath() : Paths.get(pathR1)
                pathR2 = pathData != null ? pathData.resolve(pathR2).toAbsolutePath() : Paths.get(pathR2)
                ill = true
            }
        }
        
        boolean ont = false
        if(params.ont != null) {
            pathOnt = params.ont.trim()
            if( pathOnt != null && pathOnt != 'None' && pathOnt != ''  &&  pathOnt != '-') {
                pathOnt = pathData != null ? pathData.resolve(pathOnt).toAbsolutePath() : Paths.get(pathOnt)
                ont = true
            }
        }
        
        String type
        if(ill  &&  ont) {
            type = 'hybrid'
            print("Start hybrid assembly:")
        } else if(ill) {
            type = 'ill'
            print("Start short read assembly:")
        } else if(ont) {
            type = 'ont'
            print("Start long read assembly:")
        } else {
            type = '?'
        }

        // Workflow channel creations
        chInputIllBranch = Channel.create()
        chInputOntBranch = Channel.create()
        chTapQcOnt = Channel.create()
        chQcIllPlot = Channel.empty()
        chAssembly = Channel.empty()

        Channel.of( [sample, type, pathR1, pathR2, pathOnt] )
            .dump( { "chInput: sample=${it[0]}, type=${it[1]}" } )
            .tap( chInputIllBranch )
            .tap( chInputOntBranch )
    }

} else if(params.samples != null) {
    
    def pathSamples = Paths.get(params.samples).toAbsolutePath()
    print("Samples: ${pathSamples}")
    print("Start batch execution per sample file:")

    // Workflow channel creations
    chInputIllBranch = Channel.create()
    chInputOntBranch = Channel.create()
    chTapQcOnt = Channel.create()
    chQcIllPlot = Channel.empty()
    chAssembly = Channel.empty()

    Channel.fromPath( pathSamples )
        .splitCsv( sep: '\t' )
        .map( {
            def sample = it[0].trim()
            def pathR1 = it[1].trim()
            def pathR2 = it[2].trim()
            boolean ill = false
            if( pathR1 != null  &&  pathR1 != 'None'  &&  pathR1 != ''  &&  pathR1 != '-'  &&  pathR2 != null  &&  pathR2 != 'None'  &&  pathR2 != ''  &&  pathR2 != '-') {
                pathR1 = pathData != null ? pathData.resolve(pathR1).toAbsolutePath() : Paths.get(pathR1)
                pathR2 = pathData != null ? pathData.resolve(pathR2).toAbsolutePath() : Paths.get(pathR2)
                ill = true
            }
            def pathOnt = it[3] ?: null
            if(pathOnt != null)
                pathOnt = pathOnt.trim()
            boolean ont = false
            if( pathOnt != null  &&  pathOnt != 'None'  &&  pathOnt != ''  &&  pathOnt != '-') {
                pathOnt = pathData != null ? pathData.resolve(pathOnt).toAbsolutePath() : Paths.get(pathOnt)
                ont = true
            }
            String type
            if(ill  &&  ont) {
                type = 'hybrid'
            } else if(ill) {
                type = 'ill'
            } else if(ont) {
                type = 'ont'
            } else {
                type = '?'
            }
            return [sample, type, pathR1, pathR2, pathOnt]
        } )
        .dump( { "chInput: sample=${it[0]}, type=${it[1]}" } )
        .tap( chInputIllBranch )
        .tap( chInputOntBranch )

} else {
    print("Wrong parameters!")
}

chInputIllBranch
.filter( { it[1] == 'ill'  ||  it[1] == 'hybrid' } )
.dump( { "chInputIllBranch: sample=${it[0]}, type=${it[1]}" } )
.map( { [ it[0], it[1], it[2], it[3] ] } )
.set( { chInputIll } )

chInputOntBranch
.filter( { it[1] == 'ont'  ||  it[1] == 'hybrid' } )
.dump( { "chInputOntBranch: sample=${it[0]}, type=${it[1]}" } )
.map( { [ it[0], it[1], it[4] ] } )
.set( { chInputOnt } )


process qcIll {

    tag "${sample}"
    cpus 4
    memory { 4.GB * task.attempt }
    conda "${params.containerdir}/qc-ill"

    input:
    tuple val(sample), val(type), path('R1.fastq.gz'), path('R2.fastq.gz') from chInputIll

    output:
    tuple val(sample), val(type), path("${sample}.R1.fastq.gz"), path("${sample}.R2.fastq.gz"), path("${sample}.SE.fastq.gz") into chQcIll, chPolishShort
    tuple val(sample), val(type), val('R1'), path("${sample}.R1.fastq.gz") into chQcIllPlotR1
    tuple val(sample), val(type), val('R2'), path("${sample}.R2.fastq.gz") into chQcIllPlotR2
    tuple val(sample), val(type), val('SE'), path("${sample}.SE.fastq.gz") into chQcIllPlotSE
    path("${sample}.fastp.*") into chEndQcIll
    
    publishDir pattern: "${sample}.*", path: "${pathOutput}/${sample}/qc/", mode: 'copy'

    script:
    """
    fastp --in1 R1.fastq.gz --in2 R2.fastq.gz \
        --out1 ${sample}.R1.fastq.gz --out2 ${sample}.R2.fastq.gz --unpaired1 ${sample}.SE.fastq.gz --unpaired2 ${sample}.SE.fastq.gz \
        --detect_adapter_for_pe --trim_poly_g --cut_front --cut_tail --length_required 21 --low_complexity_filter --correction \
        --json ${sample}.fastp.json --html ${sample}.fastp.html --thread ${task.cpus}
    """

    stub:
    """
    touch ${sample}.R1.fastq.gz
    touch ${sample}.R2.fastq.gz
    touch ${sample}.SE.fastq.gz
    touch ${sample}.fastp.json
    """
}


chQcIllPlot.concat( chQcIllPlotR1, chQcIllPlotR2, chQcIllPlotSE )
.set{ chQcIllPlotConcat }


process qcIllPlot {

    tag "${sample}"
    cpus 1
    memory { 2.GB * task.attempt }
    conda "${params.containerdir}/qc-ill-plot"

    input:
    tuple val(sample), val(type), val(frs), path("${sample}.${frs}.fastq.gz") from chQcIllPlotConcat

    output:
    path("${frs}/${sample}.${frs}_fastqc/Images/*.png") into chEndQcIllPlot
    
    publishDir path: "${pathOutput}/${sample}/qc/img/${frs}", mode: 'copy'

    script:
    """
    mkdir ${frs}
    fastqc --extract --format fastq --threads ${task.cpus} --outdir ${frs} ${sample}.${frs}.fastq.gz
    """

    stub:
    """
    mkdir -p ${frs}/${sample}.${frs}_fastqc/Images
    touch ${frs}/${sample}.${frs}_fastqc/Images/mock.png
    """
}

chQcIll
.dump( { "chQcIll: sample=${it[0]}, type=${it[1]}" } )
.branch {
    hybrid: it[1] == 'hybrid'
    ill: it[1] == 'ill'
}
.set( { chQcIllAssembly } )


process qcOnt {

    tag "${sample}"
    cpus 4
    memory { 8.GB * task.attempt }
    conda "${params.containerdir}/qc-ont"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('ONT.fastq.gz') from chInputOnt

    output:
    tuple val(sample), val(type), path("${sample}.ONT.fastq.gz") into chQcOnt, chQcPlotOnt

    publishDir path: "${pathOutput}/${sample}/qc/", mode: 'copy'

    script:
    """
    porechop --input ONT.fastq.gz --output tmp.fastq.gz --threads ${task.cpus}
    filtlong --min_length ${params.minOntReadLength} --target_bases ${params.qcOntTargetBases} tmp.fastq.gz | pigz --processes ${task.cpus} --stdout > ${sample}.ONT.fastq.gz
    """

    stub:
    """
    touch ${sample}.ONT.fastq.gz
    """
}


process qcOntPlot {

    tag "${sample}"
    cpus 1
    memory { 2.GB }
    conda "${params.containerdir}/qc-ont-plot"

    input:
    tuple val(sample), val(type), path('ONT.qc.fastq.gz') from chQcPlotOnt

    output:
    tuple path("${sample}.nanoplot.tsv"), path("${sample}.*.png") into chEndQcPlotOnt

    publishDir pattern: "${sample}.*.png", path: "${pathOutput}/${sample}/qc/img/ont/", mode: 'copy'
    publishDir pattern: "${sample}.nanoplot.tsv", path: "${pathOutput}/${sample}/qc/", mode: 'copy'

    script:
    """
    NanoPlot --fastq ONT.qc.fastq.gz --prefix ${sample}. --plots dot --N50 --dpi 300 --tsv_stats --threads ${task.cpus}
    mv ${sample}.NanoStats.txt ${sample}.nanoplot.tsv
    """

    stub:
    """
    touch ${sample}.nanoplot.tsv
    touch ${sample}.xyz.png
    """
}


def chTapQcOnt = Channel.create()

chQcOnt
.dump( { "chQcOnt: sample=${it[0]}, type=${it[1]}" } )
.tap( chTapQcOnt )
.set( { chQcOntAssemblyOnt } )

chTapQcOnt
.filter( { it[1] == 'hybrid' } )
.set( { chQcOntAssemblyHybrid } )


process assemblyLong {

    tag "${sample}"
    cpus 16
    memory { 32.GB * task.attempt }
    conda "${params.containerdir}/assembly-long"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('ONT.fastq.gz') from chQcOntAssemblyOnt

    output:
    tuple val(sample), val(type), path("${sample}.long.fna"), path("${sample}.long.gfa"), path('ONT.fastq.gz') into chAssemblyOntBranch
    tuple val(sample), val('long'), path("${sample}.long.gfa") into chAssemblyGraphLong

    path("${sample}.long.*") into chEndAssemblyOnt
    publishDir pattern: "${sample}.long.*", path: "${pathOutput}/${sample}/assembly/", mode: 'copy'

    script:
    """
    flye --nano-hq ONT.fastq.gz --out-dir . --threads ${task.cpus}
    mv assembly.fasta ${sample}.long.fna
    mv assembly_graph.gfa ${sample}.long.gfa
    mv flye.log ${sample}.long.log
    """

    stub:
    """
    touch ${sample}.long.fna
    touch ${sample}.long.gfa
    """
}


chAssemblyOntBranch
.dump( { "chAssemblyOntBranch: sample=${it[0]}, type=${it[1]}" } )
.branch {
    hybrid: it[1] == 'hybrid'
        return [ it[0], it[1], it[3] ]
    ont: it[1] == 'ont'
        return [ it[0], it[1], it[2], it[4] ]
}
.set( { chAssemblyOnt } )


process polishLongRacon {

    tag "${sample}"
    cpus 8
    memory { 8.GB * task.attempt }
    conda "${params.containerdir}/polish-long-racon"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('assembly.fna'), path('ONT.fastq.gz') from chAssemblyOnt.ont

    output:
    tuple val(sample), path('long.racon.fna'), path('ONT.fastq.gz') into chPolishOntRaconMedaka

    script:
    """
    minimap2 -x map-ont -o mapping.1.paf -t ${task.cpus} assembly.fna ONT.fastq.gz
    racon ONT.fastq.gz mapping.1.paf assembly.fna --threads ${task.cpus} > racon.1.fna

    minimap2 -x map-ont -o mapping.2.paf -t ${task.cpus} racon.1.fna ONT.fastq.gz
    racon ONT.fastq.gz mapping.2.paf racon.1.fna --threads ${task.cpus} > racon.2.fna

    minimap2 -x map-ont -o mapping.3.paf -t ${task.cpus} racon.2.fna ONT.fastq.gz
    racon ONT.fastq.gz mapping.3.paf racon.2.fna --threads ${task.cpus} > racon.3.fna
    mv racon.3.fna long.racon.fna
    """

    stub:
    """
    touch long.racon.fna
    """

}


process polishLongMedaka {

    tag "${sample}"
    cpus 2
    memory { 12.GB * task.attempt }
    conda "${params.containerdir}/polish-long-medaka"

    input:
    tuple val(sample), path(assembly), path(reads) from chPolishOntRaconMedaka

    output:
    tuple val(sample), path("${sample}.long.polished.fna") into chPolishOntEnd

    script:
    """
    medaka_consensus -i ${reads} -d ${assembly} -o medaka -t ${task.cpus}
    mv medaka/consensus.fasta ${sample}.long.polished.fna
    """

    stub:
    """
    touch ${sample}.fna
    touch ${sample}.long.polished.fna
    """

}


process assemblyShort {

    tag "${sample}"
    cpus 16
    memory { 32.GB * task.attempt }
    conda "${params.containerdir}/assembly-short"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('R1.fastq.gz'), path('R2.fastq.gz'), path('SE.fastq.gz') from chQcIllAssembly.ill

    output:
    tuple val(sample), path("${sample}.short.fna") into chAssemblyIll
    tuple val(sample), val('short'), path("${sample}.short.gfa") into chAssemblyGraphShort

    path("${sample}.short.*") into chEndAssemblyIll
    publishDir path: "${pathOutput}/${sample}/assembly/", mode: 'copy'

    script:
    """
    unicycler --short1 R1.fastq.gz --short2 R2.fastq.gz --unpaired SE.fastq.gz --out . --threads ${task.cpus}
    mv assembly.fasta ${sample}.short.fna
    mv assembly.gfa ${sample}.short.gfa
    mv unicycler.log ${sample}.short.log
    """

    stub:
    """
    touch ${sample}.short.fna
    touch ${sample}.short.gfa
    touch ${sample}.short.log
    """
}


process assemblyHybrid {

    tag "${sample}"
    cpus 16
    memory { 32.GB * task.attempt }
    conda "${params.containerdir}/assembly-hybrid"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('R1.fastq.gz'), path('R2.fastq.gz'), path('SE.fastq.gz') from chQcIllAssembly.hybrid
    tuple val(sample), val(type), path('ONT.fastq.gz') from chQcOntAssemblyHybrid
    tuple val(sample), val(type), path('assembly_graph.gfa') from chAssemblyOnt.hybrid

    output:
    tuple val(sample), path("${sample}.hybrid.fna") into chAssemblyHybrid
    tuple val(sample), val('hybrid'), path("${sample}.hybrid.gfa") into chAssemblyGraphHybrid

    path("${sample}.hybrid.*") into chEndAssemblyHybrid
    publishDir path: "${pathOutput}/${sample}/assembly/", mode: 'copy'

    script:
    """
    unicycler --short1 R1.fastq.gz --short2 R2.fastq.gz --unpaired SE.fastq.gz --long ONT.fastq.gz --existing_long_read_assembly assembly_graph.gfa --out . --threads ${task.cpus}
    mv assembly.fasta ${sample}.hybrid.fna
    mv assembly.gfa ${sample}.hybrid.gfa
    mv unicycler.log ${sample}.hybrid.log
    """

    stub:
    """
    touch ${sample}.hybrid.fna
    touch ${sample}.hybrid.gfa
    touch ${sample}.hybrid.log
    """
}


chPolishShort.into( { chPolishShortPolypolish; chPolishShortPolca } )


process  polishShortPolyPolish {

    tag "${sample}"
    cpus 2
    memory { 16.GB * task.attempt }
    conda "${params.containerdir}/polish-short-polypolish"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('R1.fastq.gz'), path('R2.fastq.gz'), path('SE.fastq.gz') from chPolishShortPolypolish
    tuple val(sample), path('assembly.fna') from chAssemblyHybrid

    output:
    tuple val(sample), path("${sample}.polished.fna") into chPolishShortPolypolishPOLCA

    script:
    """
    bwa index assembly.fna
    bwa mem -t ${task.cpus} -a assembly.fna R1.fastq.gz > alignments_r1.sam
    bwa mem -t ${task.cpus} -a assembly.fna R2.fastq.gz > alignments_r2.sam
    bwa mem -t ${task.cpus} -a assembly.fna SE.fastq.gz > alignments_se.sam
    polypolish filter --in1 alignments_r1.sam --in2 alignments_r2.sam --out1 filtered_r1.sam --out2 filtered_r2.sam
    polypolish polish assembly.fna filtered_r1.sam filtered_r2.sam alignments_se.sam > ${sample}.polished.fna
    """

    stub:
    """
    touch ${sample}.polished.fna
    """

}


process  polishShortPOLCA {

    tag "${sample}"
    cpus 2
    memory { 4.GB * task.attempt }
    conda "${params.containerdir}/polish-short-pypolca"
    scratch = { params.scratch ? params.scratch != null : false }

    input:
    tuple val(sample), val(type), path('R1.fastq.gz'), path('R2.fastq.gz'), path('SE.fastq.gz') from chPolishShortPolca
    tuple val(sample), path('assembly.fna') from chPolishShortPolypolishPOLCA

    output:
    tuple val(sample), path("${sample}.polished.fna") into chPolishShortEnd

    script:
    """
    pypolca run -a assembly.fna -1 R1.fastq.gz -2 R2.fastq.gz --threads ${task.cpus} --output output
    mv output/pypolca_corrected.fasta ${sample}.polished.fna
    """

    stub:
    """
    touch ${sample}.polished.fna
    """
}


chAssemblyGraph.concat( chAssemblyGraphLong, chAssemblyGraphShort, chAssemblyGraphHybrid )
    .set{ chAssemblyViz }


process  assemblyViz {

    tag "${sample}"
    cpus 1
    memory { 1.GB }
    conda "${params.containerdir}/assembly-viz"

    input:
    tuple val(sample), val(type), path('assembly.gfa') from chAssemblyViz

    output:
    tuple val(sample), path("${sample}.${type}.svg") into chAssemblyVizEnd
    publishDir path: "${pathOutput}/${sample}/assembly/", mode: 'copy'

    script:
    """
    Bandage image assembly.gfa ${sample}.${type}.svg
    """

    stub:
    """
    touch ${sample}.${type}.svg
    """
}


chAssembly.concat( chAssemblyIll, chPolishShortEnd, chPolishOntEnd )
    .dump( { "chAssembly: sample=${it[0]}, assembly=${it[1]}" } )
    .set{ chAssemblyReorientate }


process  assemblyReorientate {

    tag "${sample}"
    cpus 2
    memory { 2.GB }
    conda "${params.containerdir}/assembly-reorientate"

    input:
    tuple val(sample), path('assembly.fna') from chAssemblyReorientate

    output:
    tuple val(sample), path("${sample}.fna") into chAssemblyQC

    script:
    """
    dnaapler all --input assembly.fna --output out --threads ${task.cpus} --prefix ${sample} --autocomplete none --db dnaa,repa
    cp out/${sample}_reoriented.fasta ${sample}.fna
    """

    stub:
    """
    touch ${sample}.fna
    """
}


process  assemblyQC {

    tag "${sample}"
    cpus 1
    memory { 1.GB }

    input:
    tuple val(sample), path('assembly.fna') from chAssemblyQC

    output:
    tuple val(sample), path("${sample}.fna") into chAssemblyQCEnd
    publishDir path: "${pathOutput}/${sample}/assembly/", mode: 'copy'

    script:
    """
    assembly-qc.py --min-contig-length 200 --prefix ${sample} --output . assembly.fna
    """

    stub:
    """
    touch ${sample}.fna
    """
}


chAssemblyQCEnd
    .into( { chAssemblyMash; chAssemblyAni; chAssemblyGTDBtk; chAssemblySka; chAssemblyBakta; chAssemblyPlaton; chAssemblyCardRGI; chAssemblyMlst } )


process mash {

    tag "${sample}"
    cpus 1
    memory { 8.GB * task.attempt }
    conda "${params.containerdir}/mash"
    
    input:
    tuple val(sample), path(assembly) from chAssemblyMash

    output:
    path("${sample}.mash-screen.tsv") into chEndMash
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    mash screen -p ${task.cpus} -w -i 0.8 -v 0.0000000001 ${params.mashrefseqdb} ${assembly} | sort -gr > ${sample}.mash-screen.tsv
    """

    stub:
    """
    touch ${sample}.mash-screen.tsv
    """
}


process taxAni {

    tag "${sample}"
    cpus 8
    memory { 2.GB * task.attempt }
    conda "${params.containerdir}/tax-ani"
    
    input:
    tuple val(sample), path(assembly) from chAssemblyAni

    output:
    path("${sample}.ani.tsv") into chEndTaxAni
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    referenceseeker --bidirectional --threads ${task.cpus} ${params.referenceseekerdb} ${assembly} > ${sample}.ani.tsv
    """

    stub:
    """
    touch ${sample}.ani.tsv
    """
}


process taxGTDBtk {

    tag "${sample}"
    cpus 2
    memory {  // either very low (Mash+FastANI) or very high (MSA+pplacer)
        if(task.attempt == 1){
            4.GB;
        } else if(task.attempt == 2){
            64.GB;
        } else{
            128.GB;
        }
    }
    conda "${params.containerdir}/gtdbtk"
    
    input:
    tuple val(sample), path(assembly) from chAssemblyGTDBtk

    output:
    path("${sample}.gtdbtk.tsv") into chEndTaxGTDBtk
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    export GTDBTK_DATA_PATH="${params.gtdbtkdb}"
    mkdir genomes/
    mv ${assembly} genomes/
    gtdbtk classify_wf --genome_dir genomes/ --out_dir . --pplacer_cpus ${task.cpus} --mash_db ${params.gtdbtkdb}/mash/ --cpus ${task.cpus}
    cp classify/gtdbtk.bac120.summary.tsv ${sample}.gtdbtk.tsv
    """

    stub:
    """
    touch ${sample}.gtdbtk.tsv
    """
}


process ska {

    tag "${sample}"
    cpus 1
    memory { 2.GB * task.attempt }
    conda "${params.containerdir}/ska"
    
    input:
    tuple val(sample), path(assembly) from chAssemblySka

    output:
    path("${sample}.skf") into chEndSka
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    ska fasta -o ${sample} ${assembly}
    """

    stub:
    """
    touch ${sample}.skf
    """
}


process bakta {

    tag "${sample}"
    cpus 8
    memory { 16.GB * task.attempt }
    conda "${params.containerdir}/bakta"

    input:
    tuple val(sample), path('assembly.fasta') from chAssemblyBakta

    output:
    tuple val(sample), path("${sample}.faa") into chBaktaCheckM2, chBaktaVfdb
    tuple val(sample), path("${sample}.fna"), path("${sample}.faa"), path("${sample}.gff3") into chBaktaAmrFinderPlus
    tuple val(sample), path("${sample}.ffn") into chBakta16S
    path("${sample}.*") into chEndBakta
    publishDir path: "${pathOutput}/${sample}/annotation/", mode: 'copy'

    String genusOption = params.species != null ? "--genus ${params.genus}" : ''
    String speciesOption = params.species != null ? "--species ${params.species}" : ''
    String compliantOption = params.compliant != null ? '--compliant' : ''
    script:
    """
    bakta --db ${params.baktadb} --prefix ${sample} ${genusOption} ${speciesOption} --strain "${sample}" ${compliantOption} --keep-contig-headers --threads ${task.cpus} --output ${sample} assembly.fasta
    mv ${sample}/* .
    rmdir ${sample}
    """

    stub:
    """
    touch ${sample}.fna
    touch ${sample}.faa
    touch ${sample}.ffn
    touch ${sample}.gbff
    touch ${sample}.gff3
    """
}


process checkm2 {

    tag "${sample}"
    cpus 4
    memory { 8.GB * task.attempt }
    conda "${params.containerdir}/checkm2"
    
    input:
    tuple val(sample), path(proteins) from chBaktaCheckM2

    output:
    path("${sample}.checkm2.tsv") into chEndCheckM2
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
	mkdir ./input
	cp ${proteins} ./input
	checkm2 predict --input ./input --output-directory ./out --database_path ${params.checkm2db} --genes --extension .faa --threads ${task.cpus}
	mv ./out/quality_report.tsv ${sample}.checkm2.tsv
	"""

    stub:
    """
    touch ${sample}.checkm2.tsv
    """
}


process tax16S {

    tag "${sample}"
    cpus 1
    memory { 1.GB * task.attempt }
    conda "${params.containerdir}/tax-16-s"
    
    input:
    tuple val(sample), path(features) from chBakta16S

    output:
    path("${sample}.16s.tsv") into chEndTax16S
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    grep -A 1 '16S ribosomal RNA' ${features} | tr -d '-' | tr -s '\n' > 16S.ffn
    blastn -query 16S.ffn -db ${params.silva} -evalue 1E-10 -outfmt '6 qseqid sseqid length nident bitscore stitle' -num_threads ${task.cpus} > ${sample}.16s.tsv
    """

    stub:
    """
    touch ${sample}.16s.tsv
    """
}


process vf {

    tag "${sample}"
    cpus 1
    memory { 1.GB * task.attempt }
    conda "${params.containerdir}/vf"
    
    input:
    tuple val(sample), path(proteins) from chBaktaVfdb

    output:
    path("${sample}.vf.tsv") into chEndVfdb
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    diamond blastp --query ${proteins} --db ${params.vfdb} --id 80 --query-cover 80 --subject-cover 80 --out ${sample}.vf.tsv --outfmt 6 qseqid sseqid qlen slen qstart qend sstart send length pident evalue bitscore --threads ${task.cpus}
    """

    stub:
    """
    touch ${sample}.vf.tsv
    """
}


process amrFinderPlus {

    tag "${sample}"
    cpus 1
    memory { 1.GB * task.attempt }
    conda "${params.containerdir}/amr-finder-plus"
    
    input:
    tuple val(sample), path(nucleotide), path(protein), path(annotation) from chBaktaAmrFinderPlus

    output:
    path("${sample}.amrfinder.tsv") into chEndAmrFinderPlus
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    amrfinder --nucleotide ${nucleotide} --protein ${protein} --gff ${annotation} --annotation_format bakta --database ${params.amrfinderplusdb} --output ${sample}.amrfinder.tsv --name ${sample} --plus --threads ${task.cpus}
    """

    stub:
    """
    touch ${sample}.amrfinder.tsv
    """
}


process platon {

    tag "${sample}"
    cpus 4
    memory { 8.GB * task.attempt }
    conda "${params.containerdir}/platon"
    
    input:
    tuple val(sample), path(assembly) from chAssemblyPlaton

    output:
    path("${sample}.*") into chEndPlaton
    publishDir pattern: "${sample}.*", path: "${pathOutput}/${sample}/plasmids/", mode: 'copy'

    script:
    """
    platon --db ${params.platondb} --prefix ${sample} --threads ${task.cpus} ${assembly}
    """

    stub:
    """
    touch ${sample}.tsv
    """
}


process cardRgi {

    tag "${sample}"
    cpus 1
    memory { 2.GB * task.attempt }
    conda "${params.containerdir}/card-rgi"
    
    input:
    tuple val(sample), path(assembly) from chAssemblyCardRGI

    output:
    tuple path("${sample}.card.txt"), path("${sample}.card.json") into chEndCardRGI
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    rgi main -i ${assembly} --output_file ${sample}.card --input_type contig --data wgs --orf_finder PYRODIGAL --alignment_tool DIAMOND --num_threads ${task.cpus}
    """

    stub:
    """
    touch ${sample}.card.txt
    touch ${sample}.card.json
    """
}


process mlst {

    tag "${sample}"
    cpus 1
    memory { 1.GB * task.attempt }
    conda "${params.containerdir}/mlst"
    
    input:
    tuple val(sample), path(assembly) from chAssemblyMlst

    output:
    path("${sample}.mlst.tsv") into chEndMlst
    publishDir path: "${pathOutput}/${sample}/", mode: 'copy'

    script:
    """
    mlst --json ${sample}.json --label ${sample} --mincov 80 ${assembly} > ${sample}.mlst.tsv
    """

    stub:
    """
    touch ${sample}.mlst.tsv
    """
}