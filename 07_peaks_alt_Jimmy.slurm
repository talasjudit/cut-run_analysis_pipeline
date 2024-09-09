#!/bin/bash -e
#SBATCH -p jic-short
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --mem 80G
#SBATCH -c 32
#SBATCH --array=0-3
#SBATCH --job-name=peak_calling

# === end SBATCH directives ===

# === begin ENVIRONMENT SETUP ===

source package 6daf0c37-1c5e-4cd6-9884-2d0b4d5f9d8f
source bedtools-2.27.0
source samtools-1.9

#1. list of sample names
libraries=(\
mu_embryo_H3K27me3 \
WT_embryo_H3K9me1 \
WT_embryo_H3K27me3 \
WT_embryo_H3K36me3)

chromsize=220358409

#2. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"

genes_annotation="/jic/scratch/groups/Phil-Carella/talas/Marchantia/BS-seq/annotations/MpTak_v6.1r1_genes_only.bed"
TEs_annotation="/jic/scratch/groups/Phil-Carella/talas/Marchantia/BS-seq/annotations/tak1_20190222_repeatmodeler_withdata.bed"
genome_chrom_sizes="/jic/scratch/groups/Phil-Carella/talas/Marchantia/BS-seq/annotations/tak_v6/genome_size.txt"

#3. Current libraries value
library=${libraries[$SLURM_ARRAY_TASK_ID]}

replicates=(
"${library}_rep1" \
"${library}_rep2"
)

cd ${work_folder}/07_peaks_alt_Jimmy/150bp

for replicate in "${replicates[@]}"; do

spike_frags=$(samtools view ${work_folder}/05_output_cutnrun/${replicate}/${replicate}.spike.aligned_filtered_sorted_uniq.bam | wc -l)
scale_factor=$(echo " scale=5;100000 / $spike_frags" | bc)

echo " Scale factor: " $scale_factor 

bedtools genomecov -bg \
    -scale $scale_factor \
    -ibam ${work_folder}/05_output_cutnrun/${replicate}/${replicate}.sizednuc150.bam \
    > ${work_folder}/07_peaks_alt_Jimmy/150bp/${replicate}_150_normalised.bedgraph

/jic/research-groups/Xiaoqi-Feng/Judit_Talas/bedGraphToBigWig \
    ${work_folder}/07_peaks_alt_Jimmy/150bp/${replicate}_150_normalised.bedgraph \
    ${genome_chrom_sizes} \
    ${work_folder}/07_peaks_alt_Jimmy/150bp/${replicate}_150_normalised.bw

done


## combine the replicates

bigwigCompare -b1 ${library}_rep1_150_normalised.bw -b2 ${library}_rep2_150_normalised.bw \
    --operation mean \
    --skipNAs \
    -o ${library}_150_combined_ratio.bw

bigwigCompare -b1 ${library}_150_combined_ratio.bw -b2 WT_embryo_H3_150_combined_ratio.bw \
    --operation ratio \
    --pseudocount 1 \
    --binSize 50 \
    -o ${library}_vs_H3_150_combined_ratio.bw


## average the replicates

bigwigCompare -b1 ${library}_rep1_150_normalised.bw -b2  WT_embryo_H3_rep1_150_normalised.bw \
    --operation ratio \
    --pseudocount 1 \
    --binSize 50 \
    -o ${library}_rep1_vs_H3_rep1_150_average_ratio.bw

bigwigCompare -b1 ${library}_rep2_150_normalised.bw -b2  WT_embryo_H3_rep2_150_normalised.bw \
    --operation ratio \
    --pseudocount 1 \
    --binSize 50 \
    -o ${library}_rep2_vs_H3_rep2_150_average_ratio.bw

bigwigCompare -b1 ${library}_rep1_vs_H3_rep1_150_average_ratio.bw -b2 ${library}_rep2_vs_H3_rep2_150_average_ratio.bw \
    --operation mean \
    --skipNAs \
    -o ${library}_vs_H3_150_average_ratio.bw

## calculate heatmaps

samples=(
"${library}_vs_H3_150_combined_ratio.bw"
"${library}_rep1_vs_H3_rep1_150_average_ratio.bw"
"${library}_rep2_vs_H3_rep2_150_average_ratio.bw"
"${library}_vs_H3_150_average_ratio.bw"
)

for sample in "${samples[@]}"; do

computeMatrix \
scale-regions \
   -S ${sample} \
   -R ${genes_annotation} ${TEs_annotation} \
   --samplesLabel "${sample}" \
   -m 1000 --beforeRegionStartLength 1000 --afterRegionStartLength 1000 \
   -out ${sample}_genes_TEs_heatmap.gz

plotHeatmap \
    -m ${sample}_genes_TEs_heatmap.gz \
    --missingDataColor 1 \
    -out ${sample}_genes_TEs_heatmap.pdf

plotProfile \
-m ${sample}_genes_TEs_heatmap.gz \
-out ${sample}_genes_TEs_heatmap.pdf \
--outFileNameData ${sample}_genes_TEs_regions.tab

done