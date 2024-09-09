#!/bin/bash -e

#SBATCH -p jic-medium # partition (queue)
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --array=0-1
#SBATCH --nodes=1
#SBATCH --ntasks=6
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8gb
#SBATCH --job-name=SNPsplit_run
#SBATCH --output=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/04_output_snpsplit_run/logs/snpsplit.rnaseq.%a.txt

# === end SBATCH directives ===


# === begin ENVIRONMENT SETUP ===

#1. list of sample names

libraries=(WT_embryo_merged mut_embryo_merged)

#2. Single or paired end sequences
datatype="PE"
# datatype="SE"
#3. Output basename - Change depending on if working with Cam2 or Tak2 SNPs relative to Tak1
output=Takv6.Cam2snp #size=220358409
chromsize=220358409
# output=Takv6.Tak2snp #size=220358409
# chromsize=220358409

#4. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"

#5. SNP file
snps="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/02_output_snpsplit_prep/${output}/${output}.SNP.file.txt"

#6. singularity image
singularity_image="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/04_output_snpsplit_run/singularity_04_snpsplit_run.sif"

mkdir -p $work_folder/04_output_snpsplit_run/${libraries[$SLURM_ARRAY_TASK_ID]}
cd $work_folder/04_output_snpsplit_run/${libraries[$SLURM_ARRAY_TASK_ID]}
export TMPDIR=$work_folder/04_output_snpsplit_run/${libraries[$SLURM_ARRAY_TASK_ID]}/tmp

##export env.list
cat << EOF > env.list
work_folder=$work_folder
output=$output
TMPDIR=$TMPDIR
chromsize=$chromsize
datatype=$datatype
snps=$snps
EOF


# Run SNPsplit

##For CUT&RUN data
#if [ $datatype == "PE" ]; then
#	cd ${NAME}
#	/groups/berger/user/sean.montgomery/Documents/SNPsplit-0.3.4/SNPsplit \
#		--snp_file $snps \
#		${NAME}.sizednuc150.bam \
#		--no_sort \
#		--paired 
#fi



## For PE RNA-seq data
if [ $datatype == "PE" ]; then
	singularity exec --env-file env.list $singularity_image /bin/bash -c \
		'SNPsplit \
			--samtools_path "$SAMTOOLS_HOME"/samtools \
			--SNP_file "$snps" \
			"$work_folder"/03_output_mapping/'${libraries[$SLURM_ARRAY_TASK_ID]}'/'${libraries[$SLURM_ARRAY_TASK_ID]}'.${output}.genome.sorted.bam \
			--paired'

	if [ -d "$TMPDIR" ]; then
		rm -r $TMPDIR
	fi
fi

# ##For SE RNA-seq data
# if [ $datatype == "SE" ]; then
# 	runDir2=$work_folder/$NAME
# 	cd $runDir2
# 	/groups/berger/user/sean.montgomery/Documents/SNPsplit-0.3.4/SNPsplit \
# 		--snp_file $snps \
# 		${NAME}.${output}.genome.sorted.filtered.bam
# fi