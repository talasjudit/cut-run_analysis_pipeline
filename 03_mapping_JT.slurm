#!/bin/bash -e

#SBATCH -p jic-medium # partition (queue)
#SBATCH --mail-type=end,fail
#SBATCH --mail-user=Judit.Talas@jic.ac.uk
#SBATCH --array=0-1
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8gb
#SBATCH --job-name=mapping
#SBATCH --output=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/03_output_mapping/logs/Tak1mapping_Cam2_PE_%a.txt

# === end SBATCH directives ===

# === begin ENVIRONMENT SETUP ===

#1. list of sample names on separate lines (eg copied from excel)
libraries=(WT_embryo_merged mut_embryo_merged)

# sample_list=/groups/berger/user/sean.montgomery/Documents/Scripts/input_files/rnaseq.Cam2.SE.txt #6 Cam2 SE
# sample_list=/groups/berger/user/sean.montgomery/Documents/Scripts/input_files/rnaseq.Tak2.SE.txt #3 Tak2 SE

#2. Single or paired end sequences
datatype="PE"
# datatype="SE"

#3. Output basename - Change depending on if working with Cam2 or Tak2 SNPs relative to Tak1
#output=Takv6.Cam2snp #size=220358409
#chromsize=220358409

output=Takv6.Tak2snp #size=220358409
chromsize=220358409

#4. set directory containing sample folders
work_folder="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data"
# work_folder=/scratch-cbe/users/sean.montgomery/rna-seq/${output}/SE

#6. Fasta file of genome

#7. STAR genome directory
star_dir=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/02_output_snpsplit_prep/${output}/star-index
#8. RSEM genome directory
rsem_dir=/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/02_output_snpsplit_prep/${output}/rsem-index
#9. singularity image
singularity_image="/jic/scratch/groups/Phil-Carella/talas/Marchantia/elife_data/03_output_mapping/singularity_03_mapping.sif"

##Read in .bam file names
#F=`sed -n "${SLURM_ARRAY_TASK_ID} p" $sample_list | awk '{print $1}'`


mkdir -p $work_folder/03_output_mapping/${libraries[$SLURM_ARRAY_TASK_ID]}
cd $work_folder/03_output_mapping/${libraries[$SLURM_ARRAY_TASK_ID]}
export TMPDIR=$work_folder/03_output_mapping/${libraries[$SLURM_ARRAY_TASK_ID]}/tmp

##export env.list
cat << EOF > env.list
work_folder=$work_folder
output=$output
TMPDIR=$TMPDIR
chromsize=$chromsize
star_dir=$star_dir
rsem_dir=$rsem_dir
datatype=$datatype
EOF

# # make sure the directory exists

##Check if input is bam and sort and split into fastq
#if [[ ${F} == *bam ]]; then
#	cp /groups/berger/lab/Raw/demultiplexed/${F} $work_folder/${libraries[$SLURM_ARRAY_TASK_ID]}
#	cp /groups/berger/lab/Sean/bam/${F} $work_folder/${libraries[$SLURM_ARRAY_TASK_ID]}
#	cp /groups/berger/lab/Sean/For_Elin/${F} $work_folder/${libraries[$SLURM_ARRAY_TASK_ID]}
#       cp /resources/ngs/berger/*/${F} $work_folder/${libraries[$SLURM_ARRAY_TASK_ID]}/
#	samtools sort -n -o ${libraries[$SLURM_ARRAY_TASK_ID]}.qsort -O bam ${F}
#	if [ $datatype == "PE" ]; then
#		bedtools bamtofastq -i ${libraries[$SLURM_ARRAY_TASK_ID]}.qsort -fq ${libraries[$SLURM_ARRAY_TASK_ID]}.end1.fq -fq2 ${libraries[$SLURM_ARRAY_TASK_ID]}.end2.fq
#	elif [ $datatype == "SE" ]; then
#		bedtools bamtofastq -i ${libraries[$SLURM_ARRAY_TASK_ID]}.qsort -fq ${libraries[$SLURM_ARRAY_TASK_ID]}_1.fastq
#	else
#		echo "Datatype??"
#	fi
#	echo "BAM converted to SAM for sample ... "
#	echo ${libraries[$SLURM_ARRAY_TASK_ID]}
#	rm ${libraries[$SLURM_ARRAY_TASK_ID]}.qsort
#else
#	if [[ $datatype == "PE" ]]; then
#		if [[ "$F" == *-* ]]; then
#			##This turned out to be unnecessary, therefore does not work...
#			mv ../${FILE1}/*.fastq.gz .
#			mv ../${FILE2}/*.fastq.gz .
#			zcat *.fastq.gz | paste - - - - | awk '$2~ /1:N/ {print $1,$2"\n"$3"\n"$4"\n"$5}' > my_jgi_read1.fastq
#		elif [[ "$F" == *RR* ]]; then
#			gunzip ${F}_1.fastq.gz
#			gunzip ${F}_2.fastq.gz
#			mv ${F}_1.fastq ${libraries[$SLURM_ARRAY_TASK_ID]}.end1.fq
#			mv ${F}_2.fastq ${libraries[$SLURM_ARRAY_TASK_ID]}.end2.fq
#		else
#			echo "You're working on thin ice, bud!"
#		fi
#	elif [ $datatype == "SE" ]; then
#		gunzip ${F}.fastq.gz
#		mv ${F}.fastq ${libraries[$SLURM_ARRAY_TASK_ID]}_1.fastq
#	fi
#fi

##Make directory for trimmed data
mkdir -p trimmed

##Map reads for PE data
if [ $datatype == "PE" ]; then

		singularity exec --env-file env.list $singularity_image /bin/bash -c \
		"source activate trim_galore_env && \
		trim_galore --dont_gzip \
		--stringency 4 \
		-o trimmed/ \
		--paired $work_folder/rnaseq/${libraries[$SLURM_ARRAY_TASK_ID]}_end1.fastq $work_folder/rnaseq/${libraries[$SLURM_ARRAY_TASK_ID]}_end2.fastq"

		if [ -d "$TMPDIR" ]; then
            rm -r $TMPDIR
        fi

		singularity exec --env-file env.list $singularity_image /bin/bash -c \
		"STAR --genomeDir $star_dir \
			--readFilesIn trimmed/${libraries[$SLURM_ARRAY_TASK_ID]}_end1_val_1.fq trimmed/${libraries[$SLURM_ARRAY_TASK_ID]}_end2_val_2.fq \
			--outFileNamePrefix ${libraries[$SLURM_ARRAY_TASK_ID]} \
			--outTmpDir $TMPDIR \
			--runThreadN 8 \
			--outSAMtype BAM Unsorted \
			--alignEndsType EndToEnd --alignIntronMax 1 --alignIntronMin 2 --scoreDelOpen -10000 --scoreInsOpen -10000 \
			--outSAMattributes NH HI AS NM MD && \
		samtools view -f2 -h ${libraries[$SLURM_ARRAY_TASK_ID]}Aligned.out.bam > ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out.paired.bam "

		mkdir -p $TMPDIR

		singularity exec --env-file env.list $singularity_image /bin/bash -c \
		"rsem-calculate-expression \
			--alignments ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out.paired.bam \
			$rsem_dir/rsem-index_${output} \
			${libraries[$SLURM_ARRAY_TASK_ID]}.${output} \
			--paired-end \
			--num-threads 8 \
			--temporary-folder $TMPDIR \
			--append-names \
			--estimate-rspd \
			--output-genome-bam \
			--seed 12345 \
			--calc-ci \
			--ci-memory 40000 \
			--sort-bam-by-coordinate && \
		#run the rsem plot function
		rsem-plot-model ${libraries[$SLURM_ARRAY_TASK_ID]}.${output} ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.pdf"

		# # generate alignment summary tables
		# ### for aligned.bam (i,e to get raw mapping information)

		echo ".............................................................. "
		echo "---> Summarising alignment statistics for sample ... " ${libraries[$SLURM_ARRAY_TASK_ID]}

		singularity exec --env-file env.list $singularity_image /bin/bash -c \
		"samtools stats ${libraries[$SLURM_ARRAY_TASK_ID]}Aligned.out.bam > ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out_stats.txt && \ 
		samtools stats ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out.paired.bam > ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out.paired_stats.txt"


		for stat in "raw total sequences:" "reads mapped:" "reads mapped and paired:" "reads properly paired:" "reads duplicated:" "average length:" "maximum length:" "average quality:" "insert size average:" "insert size standard deviation:" "inward oriented pairs:" "outward oriented pairs:" "pairs with other orientation:" "pairs on different chromosomes:" ; do
		        grep "^SN" ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out_stats.txt| grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${libraries[$SLURM_ARRAY_TASK_ID]}.aligned_summary.txt
		        grep "^SN" ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out.paired_stats.txt | grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${libraries[$SLURM_ARRAY_TASK_ID]}.paired_summary.txt
		done

		rm ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out_stats.txt
		rm ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out.paired_stats.txt

		##Filter out multimappers

		singularity exec --env-file env.list $singularity_image /bin/bash -c \
		"samtools view -h \"${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.bam\" | awk \"(\\\$5 == \\\"100\\\" && \\\$17 == \\\"ZW:f:1\\\") || (\\\$1 ~ /^@/)\" | samtools view -bS > \"${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam\" && \
		samtools index \"${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam\""

		
		singularity exec --env-file env.list $singularity_image /bin/bash -c \
		"source activate deeptools_env && \
		bamCoverage -b ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam -o ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bw --normalizeTo1x $chromsize --binSize=10"
fi

##Map reads for SE data
#if [ $datatype == "SE" ]; then
#        trim_galore --dont_gzip --stringency 4 -o trimmed/ ${libraries[$SLURM_ARRAY_TASK_ID]}_1.fastq 
#        if [ -d "$TMPDIR" ]; then
#            rm -r $TMPDIR
#        fi
#		STAR --genomeDir $star_dir \
#			--readFilesIn trimmed/${libraries[$SLURM_ARRAY_TASK_ID]}_1_trimmed.fq \
#			--outFileNamePrefix ${libraries[$SLURM_ARRAY_TASK_ID]} \
#			--outTmpDir $TMPDIR \
#			--runThreadN 8 \
#			--outSAMtype BAM Unsorted \
#			--alignEndsType EndToEnd --alignIntronMax 1 --alignIntronMin 2 --scoreDelOpen -10000 --scoreInsOpen -10000 \
#			--outSAMattributes NH HI AS NM MD 
#		mkdir -p $TMPDIR
#		rsem-calculate-expression \
#			--alignments ${libraries[$SLURM_ARRAY_TASK_ID]}Aligned.out.bam \
#			$rsem_dir \
#			${libraries[$SLURM_ARRAY_TASK_ID]}.${output} \
#			--num-threads 8 \
#			--temporary-folder $TMPDIR \
#			--append-names \
#			--estimate-rspd \
#			--output-genome-bam \
#			--seed 12345 \
#			--calc-ci \
#			--ci-memory 40000 \
#			--sort-bam-by-coordinate
#		#run the rsem plot function
#		rsem-plot-model ${libraries[$SLURM_ARRAY_TASK_ID]}.${output} ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.pdf
#		# # generate alignment summary tables
#		# ### for aligned.bam (i,e to get raw mapping information)
#		echo ".............................................................. "
#		echo "---> Summarising alignment statistics for sample ... " ${libraries[$SLURM_ARRAY_TASK_ID]}
#		samtools stats ${libraries[$SLURM_ARRAY_TASK_ID]}Aligned.out.bam > ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out_stats.txt
#		for stat in "raw total sequences:" "reads mapped:" "reads mapped and paired:" "reads properly paired:" "reads duplicated:" "average length:" "maximum length:" "average quality:" "insert size average:" "insert size standard deviation:" "inward oriented pairs:" "outward oriented pairs:" "pairs with other orientation:" "pairs on different chromosomes:" ; do
#		        grep "^SN" ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out_stats.txt| grep "$stat" | awk -F $'\t' '{print $2,"\t",$3}' >> ${libraries[$SLURM_ARRAY_TASK_ID]}.aligned_summary.txt
#		done
#		rm ${libraries[$SLURM_ARRAY_TASK_ID]}.Aligned.out_stats.txt
#		##Filter out multimappers
#		samtools view -h ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.bam | awk '(($5 == "100") && ($17 == "ZW:f:1")) || ($1 ~ /^@/)' | samtools view -bS > ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam
#		samtools index ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam
#		bamCoverage -b ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam -o ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bw --normalizeTo1x $chromsize --binSize=10
#fi

##Remove trimmed .fq files
rm trimmed/*.fq

##Copy out files
#cp ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bam* /groups/berger/user/sean.montgomery/Documents/rna-seq/${output}/bam/
#cp ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genome.sorted.filtered.bw /groups/berger/user/sean.montgomery/Documents/rna-seq/${output}/bw/
#cp ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.genes.results /groups/berger/user/sean.montgomery/Documents/rna-seq/${output}/genes.results/
#cp ${libraries[$SLURM_ARRAY_TASK_ID]}.${output}.pdf /groups/berger/user/sean.montgomery/Documents/rna-seq/${output}/mapping_stats/pdf/
#cp ${libraries[$SLURM_ARRAY_TASK_ID]}.aligned_summary.txt /groups/berger/user/sean.montgomery/Documents/rna-seq/${output}/mapping_stats/txt/