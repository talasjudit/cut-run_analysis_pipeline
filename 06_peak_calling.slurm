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

source package /tgac/software/testing/bin/homer-4.11

#1. list of sample names
libraries=(\
mu_embryo_H3K27me3 \
WT_embryo_H3K9me1 \
WT_embryo_H3K27me3 \
WT_embryo_H3K36me3)

chromsize=220358409

#2. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"

#3. Current libraries value
library=${libraries[$SLURM_ARRAY_TASK_ID]}

#4. Define replicates
replicates=(\
"${library}_rep1" \
"${library}_rep2")

#5. Control directory
control_dir="$work_folder/06_peak_calling/HOMER/WT_embryo_H3_combinedTagDir"

#6. Output directory
output_dir="${work_folder}/06_peak_calling/HOMER"

#7. Change to output directory
cd $output_dir

##8. Create individual tag directories (if not already created)
for replicate in "${replicates[@]}"; do
    makeTagDirectory ${replicate}_sortedTagDir ${work_folder}/05_output_cutnrun/${replicate}/${replicate}.aligned_filtered_sorted_uniq.bam
done

#9. Create combined tag directory
combined_tag_dir="${library}_combinedTagDir"
#makeTagDirectory $combined_tag_dir -d ${replicates[@]/%/_sortedTagDir}

#10. Call peaks on the combined tag directory
findPeaks ${combined_tag_dir} \
    -style histone \
    -o ${combined_tag_dir}_vs_WT_embryo_H3_combinedTagDir.txt \
    -i $control_dir \
    -F 0.001 \
    -gsize $chromsize
