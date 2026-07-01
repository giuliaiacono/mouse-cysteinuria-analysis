#!//bin/bash

#export SAMPLE_NAME=Abx-1
#export R1=fastp/Abx-1_S1_L001/Abx-1_S1_L001_1.fastp.fastq.gz
#export R2=fastp/Abx-1_S1_L001/Abx-1_S1_L001_2.fastp.fastq.gz


for R1 in fastqs/*_1.*.gz; do
    export R1=${R1}
    export R2=$(echo ${R1} | sed 's/_1\./_2./g')
    export SAMPLE_NAME=$(basename ${R1} | cut -f1 -d _ )
    echo ${SAMPLE_NAME} ${R1} ${R2}
    sbatch sbatch_metaphlan.sh
done
