#!/bin/bash -e

#SBATCH -p jic-medium # partition (queue)
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --array=0
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16gb
#SBATCH --job-name=SNP_genomes
 
# === begin ENVIRONMENT SETUP ===
 
#1. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"
#2. Fasta file of genome with only autosomes
index1="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/tak_v5/MpTak1v5.1_and_plastids.fasta"

#3. File names of fastq files to create - Change depending on if working with Cam2 or Tak2 SNPs relative to Tak1
#fastq1="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/cam_2/SRR17465121_1.fastq"
#fastq2="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/cam_2/SRR17465121_2.fastq"

fastq1=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/tak_2/DRR120994_1.fastq
fastq2=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/tak_2/DRR120994_2.fastq


#4. Output basename - Change depending on if working with Cam2 or Tak2 SNPs relative to Tak1
#output="Takv6.Cam2snp"
#output=Takv6.Tak2snp
output=Takv5.Tak2snp

cd $work_folder/01_output_dna_snps
export TMPDIR=$work_folder/tmp
# # make sure the directory exists
mkdir -p $TMPDIR

#5. Make environment variables lsit to pass to singularity container

cat << EOF > $work_folder/01_output_dna_snps/env.list
work_folder=$work_folder
index1=$index1
fastq1=$fastq1
fastq2=$fastq2
output=$output
TMPDIR=$TMPDIR
EOF

#6. path to singularity image

singularity_image="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/01_output_dna_snps/singularity_01_DNA_snps.sif"

##Copy in and merge bam files - Only if Cam2 SNPs
#cp /groups/berger/lab/Raw/demultiplexed/129848* /groups/berger/lab/Raw/demultiplexed/129849* /groups/berger/lab/Raw/demultiplexed/129850* /groups/berger/lab/Raw/demultiplexed/134442* /groups/berger/lab/Raw/demultiplexed/134443* /groups/berger/lab/Raw/demultiplexed/134444* $work_folder
#samtools merge ${output}.merged.bam 129848_TGGGTTTCTAGATCGC_000000000-JBK88_1_20201007B_20201007.bam 129848_TGGGTTTCTAGATCGC_000000000-JCBY2_1_20201106B_20201106.bam 129848_TGGGTTTCTAGATCGC_HW3FYDRXX_1_20201120B_20201120.bam 129848_TGGGTTTCTAGATCGC_HW3FYDRXX_2_20201120B_20201120.bam 129848_TGGGTTTCTAGATCGC_H72FGBGXH_1_20201210B_20201210.bam 129849_TTGACCCTTAGATCGC_000000000-JBK88_1_20201007B_20201007.bam 129849_TTGACCCTTAGATCGC_000000000-JCBY2_1_20201106B_20201106.bam 129849_TTGACCCTTAGATCGC_HW3FYDRXX_1_20201120B_20201120.bam 129849_TTGACCCTTAGATCGC_HW3FYDRXX_2_20201120B_20201120.bam 129849_TTGACCCTTAGATCGC_H72FGBGXH_1_20201210B_20201210.bam 129850_CCACTCCTTAGATCGC_000000000-JBK88_1_20201007B_20201007.bam 129850_CCACTCCTTAGATCGC_000000000-JCBY2_1_20201106B_20201106.bam 129850_CCACTCCTTAGATCGC_HW3FYDRXX_1_20201120B_20201120.bam 129850_CCACTCCTTAGATCGC_HW3FYDRXX_2_20201120B_20201120.bam 129850_CCACTCCTTAGATCGC_H72FGBGXH_1_20201210B_20201210.bam 134442_GTCGTGATTAGATCGC_000000000-JCBY2_1_20201106B_20201106.bam 134442_GTCGTGATTAGATCGC_HW3FYDRXX_1_20201120B_20201120.bam 134442_GTCGTGATTAGATCGC_HW3FYDRXX_2_20201120B_20201120.bam 134442_GTCGTGATTAGATCGC_H72FGBGXH_1_20201210B_20201210.bam 134443_ACCACTGTTAGATCGC_000000000-JCBY2_1_20201106B_20201106.bam 134443_ACCACTGTTAGATCGC_HW3FYDRXX_1_20201120B_20201120.bam 134443_ACCACTGTTAGATCGC_HW3FYDRXX_2_20201120B_20201120.bam 134443_ACCACTGTTAGATCGC_H72FGBGXH_1_20201210B_20201210.bam 134444_TGGTCACATAGATCGC_000000000-JCBY2_1_20201106B_20201106.bam 134444_TGGTCACATAGATCGC_HW3FYDRXX_1_20201120B_20201120.bam 134444_TGGTCACATAGATCGC_HW3FYDRXX_2_20201120B_20201120.bam 134444_TGGTCACATAGATCGC_H72FGBGXH_1_20201210B_20201210.bam
#samtools sort -n -o ${output}.qsort -O bam ${output}.merged.bam

##Create fastq files - Only if Cam2 SNPs
#bedtools bamtofastq -i ${output}.qsort -fq ${fastq1} -fq2 ${fastq2}
#rm ${output}.qsort 

## Make sequence dictionary
singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'java -jar $PICARD_HOME/picard.jar CreateSequenceDictionary \
  R=${index1} \
  O=${work_folder}/genomes/tak_v5/MpTak1v5.1_and_plastids.dict > ${work_folder}/01_output_dna_snps/logs/stdout.log 2> ${work_folder}/01_output_dna_snps/logs/stderr.log'

## Convert fastq to bam
singularity exec --env-file $work_folder/01_output_dna_snps/env.list  $singularity_image /bin/bash -c \
'java -Xmx8G -jar $PICARD_HOME/picard.jar FastqToSam \
    F1=${fastq1} \
    F2=${fastq2} \
    OUTPUT=${output}.bam \
    READ_GROUP_NAME=readgroup \
    SAMPLE_NAME=${output} \
    LIBRARY_NAME=${output}-Lib \
    PLATFORM_UNIT=something \
    PLATFORM=illumina \
    SEQUENCING_CENTER=NGS \
    RUN_DATE=2014-08-20T00:00:00-0400 \
    TMP_DIR=${TMPDIR}  >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

singularity exec --env-file $work_folder/01_output_dna_snps/env.list  $singularity_image /bin/bash -c \
'samtools index ${output}.bam'

## Mark adaptor sequences
singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'java -Xmx8G -jar $PICARD_HOME/picard.jar MarkIlluminaAdapters \
    I=${output}.bam \
    O=${output}_markilluminaadapters.bam \
    M=${output}_markilluminaadapters_metrics.txt \
    TMP_DIR=${TMPDIR} >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

## Map to reference with BWA, MergeBamAlignments
singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'bwa index -a bwtsw ${index1} >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

set -o pipefail

singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'java -Xmx8G -jar $PICARD_HOME/picard.jar SamToFastq \
    I=${output}_markilluminaadapters.bam \
    FASTQ=/dev/stdout \
    CLIPPING_ATTRIBUTE=XT CLIPPING_ACTION=2 INTERLEAVE=true NON_PF=true \
    TMP_DIR=${TMPDIR} | \
    bwa mem -M -t 8 -p -K 1000000 ${index1} /dev/stdin | \
    java -Xmx16G -jar $PICARD_HOME/picard.jar MergeBamAlignment \
    ALIGNED_BAM=/dev/stdin \
    UNMAPPED_BAM=${output}.bam \
    OUTPUT=${output}_mapped.bam \
    R=${index1} CREATE_INDEX=true ADD_MATE_CIGAR=true \
    CLIP_ADAPTERS=false CLIP_OVERLAPPING_READS=true \
    INCLUDE_SECONDARY_ALIGNMENTS=true MAX_INSERTIONS_OR_DELETIONS=-1 \
    PRIMARY_ALIGNMENT_STRATEGY=MostDistant ATTRIBUTES_TO_RETAIN=XS \
    TMP_DIR=${TMPDIR} >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log '

## Mark duplicates with MarkDuplicates, SortSam
singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'java -Xmx15G -jar $PICARD_HOME/picard.jar MarkDuplicates \
    INPUT=${output}_mapped.bam \
    OUTPUT=${output}_mapped_markduplicates.bam \
    METRICS_FILE=${output}_mapped_markduplicates_metrics.txt \
    OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 \
    CREATE_INDEX=true \
    TMP_DIR=${TMPDIR} >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'java -jar $PICARD_HOME/picard.jar SortSam \
     INPUT=${output}_mapped_markduplicates.bam \
     OUTPUT=${output}_mapped_sorted.bam \
     SORT_ORDER=coordinate \
     TMP_DIR=${TMPDIR}
     CREATE_INDEX=true >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

## Use HaplotypeCaller from GATK to identify SNPs
singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'samtools index ${output}_mapped_sorted.bam >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'gatk HaplotypeCaller \
    -R ${index1} \
    -I ${output}_mapped_sorted.bam \
    --sample-ploidy 1 \
    --standard-min-confidence-threshold-for-calling 30 \
    -O ${output}.raw.snps.indels.vcf >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

## Hard filter variants
 singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
 'gatk VariantFiltration \
   -R ${index1} \
   -O ${output}.filtered.vcf \
   -V ${output}.raw.snps.indels.vcf \
   --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
   --filter-name "my_snp_filter" >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'gatk SelectVariants \
    -R ${index1} \
    -V ${output}.raw.snps.indels.vcf \
    --select-type-to-include INDEL \
    -O ${output}.raw_indels.vcf >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'

singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'gatk VariantFiltration \
    -R ${index1} \
    -V ${output}.raw_indels.vcf  \
    --filter-expression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0" \
    --filter-name "my_indel_filter" \
    -O ${output}.filtered_indels.vcf >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log' 

## Filter high quality SNPs
singularity exec --env-file $work_folder/01_output_dna_snps/env.list $singularity_image /bin/bash -c \
'gatk SelectVariants \
   -R ${index1} \
   -V ${output}.filtered.vcf \
   -O ${output}.filtered_snps.vcf \
   --select-type-to-include SNP \
   --selectExpressions "vc.isNotFiltered()" >> ${work_folder}/01_output_dna_snps/logs/stdout.log 2>> ${work_folder}/01_output_dna_snps/logs/stderr.log'
