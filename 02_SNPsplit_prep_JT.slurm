#!/bin/bash -e

#SBATCH -p jic-medium # partition (queue)
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --array=0
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=16gb
#SBATCH --job-name=SNPsplit_prep
#SBATCH --output=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/02_output_snpsplit_prep/logs/snpsplit.prep.log.txt


# === end SBATCH directives ===
 
# === begin ENVIRONMENT SETUP ===
 
#1. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"
#2. Fasta file of genome
index1="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/tak_v6/MpTak_v6.1.genome.autosomes.fasta"

#3. Output basename - Change depending on if working with Cam2 or Tak2 SNPs relative to Tak1
# output=Takv6.Cam2snp
output=Takv6.Tak2snp
#output=Takv5.Tak2snp

#4. Annotation file of Protein Coding Genes (.gff)
annotation_file="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/genomes/annotations/MpTak_v6.1r1_chr1-8_only.gff"


cd $work_folder
export TMPDIR=$work_folder/tmp
# # make sure the directory exists
mkdir -p $TMPDIR

# 5. Make environment variables list to pass to singularity container

cat << EOF > env.list
work_folder=$work_folder
index1=$index1
output=$output
TMPDIR=$TMPDIR
annotation_file=$annotation_file
EOF

# 6. path to singularity image

singularity_image="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/02_output_snpsplit_prep/singularity_02_snpsplit_prep.sif"

## Create N-masked SNPs in new reference genome

mkdir -p $work_folder/02_output_snpsplit_prep

singularity exec --env-file env.list $singularity_image /bin/bash -c \
'java -jar $GATK_HOME/GenomeAnalysisTK.jar \
   -T FastaAlternateReferenceMaker \
   -R ${index1} \
   -o ${work_folder}/02_output_snpsplit_prep/${output}/${output}.fasta \
   -V ${work_folder}/01_output_dna_snps/${output}/${output}.filtered_snps.vcf \
   --snpmask ${work_folder}/01_output_dna_snps/${output}/${output}.filtered_snps.vcf \
   --snpmaskPriority'

sed 's/.*chr/>chr/g' $work_folder/02_output_snpsplit_prep/${output}/${output}.fasta | sed 's/.*unplaced/>unplaced/g' | sed 's/:1//g' > $work_folder/02_output_snpsplit_prep/${output}/tmp.fasta
mv $work_folder/02_output_snpsplit_prep/${output}/tmp.fasta $work_folder/02_output_snpsplit_prep/${output}/${output}.fasta

##Make samtools index
singularity exec --env-file env.list $singularity_image /bin/bash -c \
'samtools faidx ${work_folder}/02_output_snpsplit_prep/${output}/${output}.fasta'

##Make bowtie2 index
singularity exec --env-file env.list $singularity_image /bin/bash -c \
'bowtie2-build ${work_folder}/02_output_snpsplit_prep/${output}/${output}.fasta ${work_folder}/02_output_snpsplit_prep/${output}/${output}'

##Make .dict
singularity exec --env-file env.list $singularity_image /bin/bash -c \
'java -jar $PICARD_HOME/picard.jar CreateSequenceDictionary \
	R=${work_folder}/02_output_snpsplit_prep/${output}/${output}.fasta \
	O=${work_folder}/02_output_snpsplit_prep/${output}/${output}.dict'

##Make rsem index
mkdir -p $work_folder/02_output_snpsplit_prep/${output}/rsem-index

singularity exec --env-file env.list $singularity_image /bin/bash -c \
'rsem-prepare-reference --num-threads 8 --gff3 ${annotation_file} --star \
  ${work_folder}/02_output_snpsplit_prep/${output}/${output}.fasta $work_folder/02_output_snpsplit_prep/${output}/rsem-index/rsem-index_${output}'

##Make STAR index
mkdir $work_folder/02_output_snpsplit_prep/${output}/star-index

singularity exec --env-file env.list $singularity_image /bin/bash -c \
'STAR --runMode genomeGenerate \
	--genomeDir ${work_folder}/02_output_snpsplit_prep/${output}/star-index \
	--genomeFastaFiles ${work_folder}/02_output_snpsplit_prep/${output}/rsem-index/rsem-index_${output}.idx.fa'

## Format vcf into tab-delimited SNPs_<strain_name>/chr<chromosome>.txt.gz file
## Must do solo because SNPsplit_genome_preparation executable only for mouse genomes
## SNP-ID	Chromosome	Position	Strand	Ref/SNP
grep -v '#' $work_folder/01_output_dna_snps/${output}/${output}.filtered_snps.vcf | awk -v OFS='\t' '{print NR,$1,$2,1,$4"/"$5}' > $work_folder/02_output_snpsplit_prep/${output}/${output}.SNP.file.txt