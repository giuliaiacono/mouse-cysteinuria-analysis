#!/bin/bash
#SBATCH --job-name=metaphlan
#SBATCH --account=df22
#SBATCH --partition=genomics
#SBATCH --qos=genomics
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=40G
#SBATCH --time=4:00:00


set -o xtrace
# These should be defined in the environment calling this script
#export SAMPLE_NAME=Abx-1
#export R1=fastp/Abx-1_S1_L001/Abx-1_S1_L001_1.fastp.fastq.gz
#export R2=fastp/Abx-1_S1_L001/Abx-1_S1_L001_2.fastp.fastq.gz

#export SLURM_CPUS_PER_TASK=12

module load singularity

export DATABASE=$(realpath databases/metaphlan_db)

mkdir -p results
export OUTPATH=$(realpath results)
mkdir -p tmp
export TMPDIR=$(realpath tmp)

echo "Starting at:" $(date)

time metaphlan \
  $(realpath ${R1}),$(realpath ${R2}) \
  -t rel_ab_w_read_stats \
  --unclassified_estimation \
  --bowtie2db ${DATABASE} \
  --bowtie2out ${TMPDIR}/${SAMPLE_NAME}.bowtie2.bz2 \
  --nproc ${SLURM_CPUS_PER_TASK} \
  --input_type fastq \
  --sample_id ${SAMPLE_NAME} \
  --biom ${OUTPATH}/${SAMPLE_NAME}_metaphlan.biom \
  -o ${OUTPATH}/${SAMPLE_NAME}_metaphlan.txt

# --unclassified_estimation \
