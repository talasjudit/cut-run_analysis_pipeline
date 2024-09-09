#!/bin/bash

# === begin SBATCH directives ===
#SBATCH -p jic-long
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8gb
#SBATCH --array=0-9
#SBATCH --job-name=cutnrun
#SBATCH --output=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/05_output_cutnrun/logs/cutrun.Cam2.PE.%a.txt

# === end SBATCH directives ===

# === begin ENVIRONMENT SETUP ===


#1. list of sample names
libraries=(\
mu_embryo_H3K27me3_rep1 \
mu_embryo_H3K27me3_rep2 \
WT_embryo_H3_rep1 \
WT_embryo_H3_rep2 \
WT_embryo_H3K9me1_rep1 \
WT_embryo_H3K9me1_rep2 \
WT_embryo_H3K27me3_rep1 \
WT_embryo_H3K27me3_rep2 \
WT_embryo_H3K36me3_rep1 \
WT_embryo_H3K36me3_rep2)


#2. Output basename - Change depending on if working with Cam2 or Tak2 SNPs relative to Tak1
output=Takv6.Cam2snp #size=220358409
chromsize=220358409
#3. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"
#4. bwt2 index for genome of interest
index1="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/Takv6.Cam2snp/Takv6.Cam2snp.nmasked"
#5. bwt2 index for spike-in genome
index2="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/hg19/hg19"
#6. Data type "SE" or "PE"
datatype="PE"
#7. Current libraries value
library_val=${libraries[$SLURM_ARRAY_TASK_ID]}

#8. singularity image
singularity_image="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/05_output_cutnrun/singularity_05_cutnrun.sif"

# file with chromosome sizes

chrom_sizes="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/Takv6.Cam2snp/Takv6.Cam2snp.nmasked.fasta.chromsize"

#NEBNext adaptor sequences
a1=AGATCGGAAGAGCACACGTCTGAACTCCAGTCAC
a2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTAGATCTCGGTGGTCGCCGTATCATT

# #set tmp file for picard tools
export ptTMPDIR=${work_folder}/05_output_cutnrun/tmp/picard_tmp_${library_val}
# # make sure the directory exists
mkdir -p $ptTMPDIR

# #set tmp file for deeptools
export TMPDIR=${work_folder}/05_output_cutnrun/tmp/tmp_${library_val}
# # make sure the directory exists
mkdir -p $TMPDIR

# ... and then change to  working directory:
mkdir -p ${work_folder}/05_output_cutnrun/${library_val}
cd ${work_folder}/05_output_cutnrun/${library_val}

##export env.list
cat << EOF > env.list
work_folder=$work_folder
output=$output
chromsize=$chromsize
datatype=$datatype
index1=$index1
index2=$index2
a1=$a1
a2=$a2
ptTMPDIR=$ptTMPDIR
TMPDIR=$TMPDIR
chrom_sizes=$chrom_sizes
library_val=$library_val
EOF

# === end ENVIRONMENT SETUP ===

#Pre-process files



# BAM file must be sorted/grouped by read name to keep records in the two output FASTQ files in the same order.
# To sort the BAM file by query name use ---> samtools sort -n -o aln.qsort -O bam aln.bam


echo ".............................................................. "
echo "---> Cutting adapters for sample ... " ${library_val}


if [ $datatype == "PE" ]; then
    singularity exec --env-file env.list $singularity_image /bin/bash -c \
        'source activate cutadapt_env && \
            cutadapt \
            -a $a1 \
            -A $a2 \
            --minimum-length 1 \
            -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim1.fq \
            -p ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim2.fq \
             ${work_folder}/cutandrun_data/${library_val}/${library_val}.end1.fq \
             ${work_folder}/cutandrun_data/${library_val}/${library_val}.end2.fq \
            > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}_cutadapt.txt'
fi


if [ $datatype == "SE" ]; then
    singularity exec --env-file env.list $singularity_image /bin/bash -c \
        'source activate cutadapt_env && \
        cutadapt \
        -a $a1 \
        --minimum-length 1 \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim.fq \
        ${work_folder}/cutandrun_data/${library_val}/${library_val}.fq \
        > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}_cutadapt.txt'
fi


# # End pre-processing files

# align with bowtie2 fragments
echo ".............................................................. "
echo "---> Aligning sample ... " ${library_val}


# paired end
if [ $datatype == "PE" ]; then
    singularity exec --env-file env.list $singularity_image /bin/bash -c \
	    'bowtie2 --end-to-end --very-sensitive --no-mixed --no-discordant -q --phred33 -I 10 -X 700 \
            -x $index1 \
            -1 ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim1.fq \
            -2 ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim2.fq \
            -S ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sam'
        ## spike-in genome
    singularity exec --env-file env.list $singularity_image /bin/bash -c \
	    'bowtie2 --end-to-end --very-sensitive --no-mixed --no-discordant -q --phred33 -I 10 -X 700 \
            -x $index2 \
            -1 ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim1.fq \
            -2 ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim2.fq \
            -S ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.sam'
fi

# SE
if [ $datatype == "SE" ]; then
    singularity exec --env-file env.list $singularity_image /bin/bash -c \
        'bowtie2 --end-to-end --very-sensitive --no-mixed --no-discordant -q --phred33 -I 10 -X 700 \
            -x $index1 \
            -U ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim.fq \
            -S ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sam'
        ## spike-in genome
    singularity exec --env-file env.list $singularity_image /bin/bash -c \
	    'bowtie2 --end-to-end --very-sensitive --no-overlap --no-dovetail --no-mixed --no-discordant -q --phred33 -I 10 -X 700 \
            -x $index2 \
            -U ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.trim.fq \
            -S ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.sam'
fi

# convert sam to bam
echo ".............................................................. "
echo "---> Converting SAM to BAM for sample ... " ${library_val}

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools view -bS \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned.bam \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sam'


# spike-in
singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools view -bS \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned.bam \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.sam'


#Sorting and indexing aligned BAM file
echo ".............................................................. "
echo "---> Sorting by co-ordinates and indexing sample ... " ${library_val}.aligned.bam 

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools sort \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_sorted.bam \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned.bam && \
    samtools index \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_sorted.bam'


# spike-in
singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools sort \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_sorted.bam \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned.bam && \
    samtools index \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_sorted.bam'

#use samtools to filter away reads with MAPQ < 10
echo ".............................................................. "
echo "---> Filtering for mapQ > 10m sorting and indexing sample ... " ${library_val}.aligned_sorted.bam

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools view \
        -bq 10 ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_sorted.bam \
        > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered.bam'

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools sort \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted.bam \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered.bam && \
    samtools index ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted.bam'

## spike-in

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools view \
        -bq 10 ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_sorted.bam \
        > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered.bam'

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools sort \
        -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted.bam \
        ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered.bam && \
    samtools index ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted.bam'


#removing duplicates and indexing resulting BAM file
echo ".............................................................. "
echo "---> Removing duplicates and indexing to generate ... " ${library_val}.sorted_uniq.bam

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'java -Djava.io.tmpdir=$ptTMPDIR -jar $PICARD_HOME/picard.jar \
        MarkDuplicates \
        I=${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted.bam \
        O=${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_uniq.bam \
        M=${work_folder}/05_output_cutnrun/${library_val}/${library_val}.dup_metrics.txt \
        AS=true REMOVE_DUPLICATES=true TMP_DIR=$ptTMPDIR'

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools index ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_uniq.bam'

# spike-in
singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'java -Djava.io.tmpdir=$ptTMPDIR -jar $PICARD_HOME/picard.jar \
        MarkDuplicates \
        I=${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted.bam\
        O=${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_uniq.bam \
        M=${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.dup_metrics.txt \
        AS=true REMOVE_DUPLICATES=true TMP_DIR=$ptTMPDIR'

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools index ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_uniq.bam'


# #normalise and convert BAM file to BIGWIG to represent coverage
echo ".............................................................. "
echo "---> Generating BW files for final BAM files with and without duplicates ... "

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'source activate deeptools_env && \
        bamCoverage \
            -b ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted.bam \
            -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.coverage_dups.bw --normalizeTo1x ${chromsize} --binSize=10 && \
        bamCoverage \
            -b ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_uniq.bam \
            -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.coverage_uniq.bw --normalizeTo1x ${chromsize} --binSize=10'

# spike-in
singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'source activate deeptools_env && \
        bamCoverage \
            -b ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted.bam \
            -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.coverage_dups.bw --normalizeTo1x ${chromsize} --binSize=10 && \
        bamCoverage \
            -b ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_uniq.bam \
            -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.coverage_uniq.bw --normalizeTo1x ${chromsize} --binSize=10'

#convert BAM file to bedpe for further analysis

if [ $datatype == "PE" ]; then
    echo ".............................................................. "
    echo "---> Generating BEDPE files for downstream analyses ... "

    singularity exec --env-file env.list $singularity_image /bin/bash -c \
        'source activate deeptools_env && \
        samtools sort \
            -n ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_uniq.bam |\
        bamToBed -bedpe -i stdin |\
            sort -k1,1V -k2,2n -T $TMPDIR > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sorted_uniq.bedpe'
fi

#filter fragments <150bp

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    "samtools view \
        -h \${work_folder}/05_output_cutnrun/\${library_val}/\${library_val}.aligned_filtered_sorted_uniq.bam |\
    awk -v OFS='\t' '(\$9 > 150 || \$9 < -150 || \$1 ~ /^@/) {print \$0}' |\
    samtools view \
        -bS - > \${work_folder}/05_output_cutnrun/\${library_val}/\${library_val}.sizednuc150.bam && \
    samtools index \${work_folder}/05_output_cutnrun/\${library_val}/\${library_val}.sizednuc150.bam"

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'source activate deeptools_env && \
        bamCoverage \
            -b ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bam \
            -o ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bw --normalizeTo1x ${chromsize} --binSize=10'

# # generate alignment summary tables
# ### for aligned.bam (i,e to get raw mapping information)
echo ".............................................................. "
echo "---> Summarising alignment statistics for sample ... " ${library_val}

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools stats ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_sorted.bam > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_stats.txt && \
    samtools stats ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted.bam > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_stats.txt && \
    samtools stats ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bam > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150_stats.txt'


for stat in "raw total sequences:" "reads mapped:" "reads mapped and paired:" "reads properly paired:" "reads duplicated:" "average length:" "maximum length:" "average quality:" "insert size average:" "insert size standard deviation:" "inward oriented pairs:" "outward oriented pairs:" "pairs with other orientation:" "pairs on different chromosomes:" ; do
    grep "^SN" ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_stats.txt| grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_summary.txt
    grep "^SN" ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_stats.txt | grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_summary.txt
    grep "^SN" ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150_stats.txt | grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150_summary.txt
done

rm ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_stats.txt
rm ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.aligned_filtered_sorted_stats.txt
rm ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150_stats.txt


# spike-in
singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'samtools stats ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_sorted.bam > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_stats.txt && \
    samtools stats ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted.bam > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_stats.txt'

for stat in "raw total sequences:" "reads mapped:" "reads mapped and paired:" "reads properly paired:" "reads duplicated:" "average length:" "maximum length:" "average quality:" "insert size average:" "insert size standard deviation:" "inward oriented pairs:" "outward oriented pairs:" "pairs with other orientation:" "pairs on different chromosomes:" ; do
    grep "^SN" ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_stats.txt| grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_summary.txt
    grep "^SN" ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_stats.txt | grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_summary.txt
done

rm ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_stats.txt
rm ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_stats.txt



#convert BAM file to bedpe for further analysis

if [ $datatype == "PE" ]; then
    echo ".............................................................. "
    echo "---> Generating BEDPE files for downstream analyses ... "

    singularity exec --env-file env.list $singularity_image /bin/bash -c \
        'samtools sort \
            -n ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bam |\
        bamToBed -bedpe -i stdin |\
            sort -k1,1 -k2,2n -T $TMPDIR > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bedpe'

    awk -v OFS='\t' '{print $1,$2,$6,1}' ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bedpe > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bedpe.bed
fi


#Scale output according to spike-in

singularity exec --env-file env.list $singularity_image /bin/bash -c \
    'source activate deeptools_env && \
    spike_frags=$(samtools view ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_uniq.bam | wc -l) && \
    scale_factor=$(echo " scale=5;100000 / $spike_frags " | bc) && \
    echo " Scale factor: " $scale_factor && \
    samtools view \
        -b ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bam |\
    bedtools genomecov -bg -scale $scale_factor -ibam - > ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.norm.bed'


##Copy out files
cp ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bam* ${work_folder}/05_output_cutnrun/expression/bam/
cp ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.bw ${work_folder}/05_output_cutnrun/expression/bw/
cp ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.sizednuc150.norm.bed ${work_folder}/05_output_cutnrun/expression/bed/
cp ${work_folder}/05_output_cutnrun/${library_val}/${library_val}*.txt ${work_folder}/05_output_cutnrun/expression/mapping_stats/
cp ${work_folder}/05_output_cutnrun/${library_val}/${library_val}.spike.aligned_filtered_sorted_uniq.bam ${work_folder}/05_output_cutnrun/expression/spike_bam/

rm -rf $TMPDIR
rm -rf $ptTMPDIR
 