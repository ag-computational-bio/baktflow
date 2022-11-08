#!/usr/bin/env bash

mkdir conda
mamba create --yes --quiet -p conda/qc-ill fastp=0.20.1
mamba create --yes --quiet -p conda/qc-ill-plot fastqc=0.11.8
mamba create --yes --quiet -p conda/qc-ont pigz porechop=0.2.4 filtlong=0.2.1
mamba create --yes --quiet -p conda/assembly-long flye=2.8.3 biopython=1.79
mamba create --yes --quiet -p conda/polish-long-racon minimap2 racon=1.4.20
mamba create --yes --quiet -p conda/polish-long-medaka medaka=1.4.3
mamba create --yes --quiet -p conda/polish-short-pilon pilon=1.22 bwa=0.7.17 samtools=1.15.1 htslib=1.15.1
mamba create --yes --quiet -p conda/polish-short-polca masurca=4.0.9
mamba create --yes --quiet -p conda/polish-short-polypolish polypolish=0.5.0
mamba create --yes --quiet -p conda/assembly-short blast=2.10.1 spades=3.13.0 samtools=1.13 unicycler=0.4.8 biopython=1.79
mamba create --yes --quiet -p conda/assembly-hybrid blast=2.10.1 spades=3.13.0 samtools=1.13 unicycler=0.4.8 biopython=1.79
mamba create --yes --quiet -p conda/mash mash=2.3
mamba create --yes --quiet -p conda/bakta bakta=1.3.3
mamba create --yes --quiet -p conda/tax-16-s blast=2.10.1
mamba create --yes --quiet -p conda/vf diamond=2.0.11
mamba create --yes --quiet -p conda/amr-finder-plus ncbi-amrfinderplus=3.10.14
mamba create --yes --quiet -p conda/tax-ani referenceseeker=1.7.3
mamba create --yes --quiet -p conda/platon platon=1.6
mamba create --yes --quiet -p conda/card-rgi rgi=5.2
mamba create --yes --quiet -p conda/mlst blast=2.10.1 mlst=2.19.0

mamba create --yes --quiet -p conda/qc-ont-plot nanoplot=1.38.1
