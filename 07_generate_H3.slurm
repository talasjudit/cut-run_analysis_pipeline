#!/bin/bash -e
#SBATCH -p jic-short
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --mem 80G
#SBATCH -c 32
#SBATCH --array=0
#SBATCH --job-name=peak_calling

# === end SBATCH directives ===

# === begin ENVIRONMENT SETUP ===

source package 6daf0c37-1c5e-4cd6-9884-2d0b4d5f9d8f
source bedtools-2.27.0
source samtools-1.9

#1. list of sample names
libraries=(
WT_embryo_H3 \
)

chromsize=220358409

#2. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"

genes_annotation="/jic/scratch/groups/Phil-Carella/talas/Marchantia/BS-seq/annotations/MpTak_v6.1r1_genes_only.bed"
TEs_annotation="/jic/scratch/groups/Phil-Carella/talas/Marchantia/BS-seq/annotations/tak1_20190222_repeatmodeler_withdata.bed"
genome_chrom_sizes="/jic/scratch/groups/Phil-Carella/talas/Marchantia/BS-seq/annotations/tak_v6/genome_size.txt"

#3. Current libraries value
library=${libraries[$SLURM_ARRAY_TASK_ID]}

cd ${work_folder}/07_peaks_alt_Jimmy

bigwigCompare -b1 ${library}_rep1_normalised.bw -b2 ${library}_rep2_normalised.bw \
    --operation mean \
    --skipNAs \
    -o ${library}_combined_ratio.bw