#!/usr/bin/env bash

mkdir conda
mamba create --yes --quiet -p conda/qc-ill fastp=0.23.4
mamba create --yes --quiet -p conda/qc-ill-plot fastqc=0.12.1
mamba create --yes --quiet -p conda/qc-ont pigz porechop=0.2.4 filtlong=0.2.1
mamba create --yes --quiet -p conda/qc-ont-plot nanoplot=1.41.0
mamba create --yes --quiet -p conda/assembly-long flye=2.9.4 biopython=1.80
mamba create --yes --quiet -p conda/polish-long-racon minimap2=2.24 racon=1.5.0
mamba create --yes --quiet -p conda/polish-long-medaka medaka=1.11.1
mamba create --yes --quiet -p conda/polish-short-pypolca pypolca=0.3.1
mamba create --yes --quiet -p conda/polish-short-polypolish polypolish=0.6.0
mamba create --yes --quiet -p conda/assembly-short blast=2.12.0 spades=3.15.5 samtools=1.16.1 unicycler=0.5.0 biopython=1.80
mamba create --yes --quiet -p conda/assembly-hybrid blast=2.12.0 spades=3.15.5 samtools=1.16.1 unicycler=0.5.0 biopython=1.80
mamba create --yes --quiet -p conda/assembly-reorientate dnaapler=0.7.0
mamba create --yes --quiet -p conda/assembly-viz bandage=0.8.1
mamba create --yes --quiet -p conda/checkm2 checkm2=1.0.1
mamba create --yes --quiet -p conda/mash mash=2.3
mamba create --yes --quiet -p conda/gtdbtk gtdbtk=2.3.2
mamba create --yes --quiet -p conda/ska ska=1.0
mamba create --yes --quiet -p conda/bakta bakta=1.9.3
mamba create --yes --quiet -p conda/tax-16-s blast=2.12.0
mamba create --yes --quiet -p conda/vf diamond=2.0.14
mamba create --yes --quiet -p conda/amr-finder-plus ncbi-amrfinderplus=3.12.8
mamba create --yes --quiet -p conda/tax-ani referenceseeker=1.7.3
mamba create --yes --quiet -p conda/platon platon=1.6
mamba create --yes --quiet -p conda/card-rgi rgi=6.0.3
mamba create --yes --quiet -p conda/mlst blast=2.12.0 mlst=2.23.0
