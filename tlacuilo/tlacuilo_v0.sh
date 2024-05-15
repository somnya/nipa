#!/bin/bash
# Name: Tlacuilo - From raw FASTQ to HQ SNPs VCF
# Author: Eddy Mendoza
# Date: 08/05/23

# === IN-LINE INPUT VARIABLES =============================================================================

for argument in "$@"
do
  key=$(echo $argument | cut -f 1 -d'=')
  value=$(echo $argument | cut -f 2 -d'=')
  case "$key" in
    "thr")          thr="$value" ;;
    "mem")          mem="$value" ;;
    "array")        array="$value" ;;
    "workdir")      workdir="$value" ;;
    "prefix")       prefix="$value" ;;
    "input")        input="$value" ;;
    "samples")      samples="$value" ;;
    "ref")          ref="$value" ;;
    "qual")         qual="$value" ;;
    "depth")        depth="$value" ;;
    *)
  esac
done

echo ""
echo ""
echo "#################################################"
echo ""
echo "Number of threads to be used per job = ${thr}"
echo "Reserved memory per job = ${mem}"
echo "Specifications for the array = ${array} (e.g. 1-number_of_jobs%chunk_size)"
echo "Working directory = ${workdir}"
echo "Prefix for the output directory = ${prefix}"
echo "Path to the directory containing the read files = ${input}"
echo "TSV table containing the sample information = ${samples} (e.g. sample \t read_1_path \t read_2_path)"
echo "Path to the FASTA reference = ${ref}"
echo "Minimum phred quality required to process an alignment= ${qual}"
echo "Minimum depth required to process a site = ${depth}"
echo ""
echo "#################################################"
echo ""
echo ""

# === DIRECTORY MAKER =================================================================================

rm -R ${workdir}/${prefix}/ # cleaning control in case of previous attemps
mkdir ${workdir}/${prefix}
mkdir ${workdir}/${prefix}/exegfiles
mkdir ${workdir}/${prefix}/fastq
mkdir ${workdir}/${prefix}/fastq/temp
mkdir ${workdir}/${prefix}/fastq/qual_raw
mkdir ${workdir}/${prefix}/fastq/fastp
mkdir ${workdir}/${prefix}/fastq/qual_trim
mkdir ${workdir}/${prefix}/bam
mkdir ${workdir}/${prefix}/bam/raw
mkdir ${workdir}/${prefix}/bam/deduplicated
mkdir ${workdir}/${prefix}/vcf

echo ""
echo ""
echo "#################################################"
echo ""
echo "The following directory architecture was created:"
echo ""
echo "----${workdir}/${prefix}/"
echo "      |"
echo "      |--exegfiles/"
echo "      |"
echo "      |--fastq/"
echo "      |    |--temp/"
echo "      |    |--qual_raw/"
echo "      |    |--fastp/"
echo "      |    \--qual_trim/"
echo "      |    "
echo "      |--bam/"
echo "      |    |--raw/"
echo "      |    \--deduplicated/"
echo "      |    "
echo "      \--vcf/"
echo ""
echo "#################################################"
echo ""
echo ""

# === HEREDOC MAIN SCRIPT =================================================================================

sbatch <<EOT
#!/bin/bash

#SBATCH -J snpC
#SBATCH -N 1
#SBATCH --partition=batch
#SBATCH --time=24:00:00
#SBATCH --ntasks-per-node=${thr}
#SBATCH --cpus-per-task=1
#SBATCH --mem=${mem}
#SBATCH --array=${array}
#SBATCH -o ${workdir}/${prefix}/exegfiles/snpC.%J.out
#SBATCH -e ${workdir}/${prefix}/exegfiles/snpC.%J.err

# === SET UP ENVIRONMENT =================================================================================

cd $workdir/
module purge # this is important to avoid conflicts with custom .bashrc configurations
ml fastqc/0.12.0 fastp/0.23.2 bwa/0.7.17 samtools/1.16.1

# === ARRAY INSTRUCTIONS ================================================================================

line=\$(sed -n "\$SLURM_ARRAY_TASK_ID"p '$samples' ) 
name=\$(echo \${line} | cut -f1 -d ' ' )
read_1=\$(echo \${line} | cut -f2 -d ' ' ) # locations of the reads are assumed to be in "input"
read_2=\$(echo \${line} | cut -f3 -d ' ' | sed 's/\r//' ) # somehow there is a phantom entry at the end of the line that we need to remove

# === WORK COMMANDS =====================================================================================

#################
# PREPROCESSING #
#################

echo "Working with \${name}"

# copy the read files temporary

cp $input/\$read_1 ${prefix}/fastq/temp/\${name}_R1.fq.gz
cp $input/\$read_2 ${prefix}/fastq/temp/\${name}_R2.fq.gz

# quality assessment

fastqc -t $thr --noextract \
    -o ${prefix}/fastq/qual_raw/ \
    ${prefix}/fastq/temp/\${name}_R1.fq.gz \
    ${prefix}/fastq/temp/\${name}_R2.fq.gz

# filtering and trimming

fastp --thread $thr \
      --in1 ${prefix}/fastq/temp/\${name}_R1.fq.gz \
      --in2 ${prefix}/fastq/temp/\${name}_R2.fq.gz \
      --out1 ${prefix}/fastq/fastp/\${name}_R1.fastp.fq.gz \
      --out2 ${prefix}/fastq/fastp/\${name}_R2.fastp.fq.gz \
      --json ${prefix}/fastq/fastp/\${name}.fastp.json \
      --html ${prefix}/fastq/fastp/\${name}.fastp.html \
      --average_qual 28 --cut_front --cut_tail --cut_window_size 1 \
      --length_required 100 \
      --detect_adapter_for_pe \
      --trim_front1 19 --trim_front2 19 --trim_poly_g

# remove temporary copies

rm ${prefix}/fastq/temp/\${name}_R1.fq.gz ${prefix}/fastq/temp/\${name}_R2.fq.gz

# quality assessment post filtering

fastqc -t $thr --noextract \
    -o ${prefix}/fastq/qual_trim/ \
    ${prefix}/fastq/fastp/\${name}_R1.fastp.fq.gz \
    ${prefix}/fastq/fastp/\${name}_R2.fastp.fq.gz

# alingment
bwa mem -t $thr $ref ${prefix}/fastq/fastp/\${name}_R1.fastp.fq.gz ${prefix}/fastq/fastp/\${name}_R2.fastp.fq.gz > ${prefix}/bam/tmp.\${name}.sam 

# convert to BAM and sort
samtools view -@ $thr -b ${prefix}/bam/tmp.\${name}.sam | samtools sort -@ $thr > ${prefix}/bam/raw/\${name}.bam

# evaluate mapping quality

samtools flagstat -@ $thr ${prefix}/bam/raw/\${name}.bam > ${prefix}/bam/raw/\${name}.flagstat.txt

###############
# SNP CALLING #
###############

# filter unmaped reads

samtools view -@ $thr -Sh -F 4 -q $qual -b ${prefix}/bam/raw/\${name}.bam > ${prefix}/bam/tmp.\${name}_mapped.bam

# sort

samtools sort -n -@ $thr ${prefix}/bam/tmp.\${name}_mapped.bam -o ${prefix}/bam/tmp.\${name}_sorted_mapped.bam

# fixmate

samtools fixmate -@ $thr -m ${prefix}/bam/tmp.\${name}_sorted_mapped.bam ${prefix}/bam/tmp.\${name}_fixm.bam

# sort fixmates

samtools sort -@ $thr ${prefix}/bam/tmp.\${name}_fixm.bam -o ${prefix}/bam/tmp.\${name}_sorted_fixm.bam

# index

samtools index -@ $thr ${prefix}/bam/tmp.\${name}_sorted_fixm.bam

# mark duplicates

samtools markdup -@ $thr ${prefix}/bam/tmp.\${name}_sorted_fixm.bam ${prefix}/bam/deduplicated/\${name}.bam

# index deduplicated

samtools index -@ $thr ${prefix}/bam/deduplicated/\${name}.bam

# clean intermediates

rm ${prefix}/bam/tmp.\${name}*

# mpileup
# keep only essential info (AD, DP and SP) to save storage

bcftools mpileup --threads $thr -f $ref -g 1 -a "AD,DP,SP,INFO/AD" ${prefix}/bam/deduplicated/\${name}.bam -o ${prefix}/bam/deduplicated/\${name}.mpileup

# variant calling, remove indels 
# include non-variant sites to be able to identify homozygous calls
# process sited with required depth
# INFO/DP is for unfiltered depth
# FORMAT/DP is for filtered depth (alingmnent phred >= threshold)

bcftools call --threads $thr -mOz -V indels ${prefix}/bam/deduplicated/\${name}.mpileup | bcftools view --threads $thr -i "FORMAT/DP >= $depth" -Oz > ${prefix}/vcf/\${name}.vcf.gz

# delete mpileup

rm ${prefix}/bam/deduplicated/\${name}.mpileup

# sort, compress and index SNP VCF
# usually, position-dependent operations (like sorting) can't be multithreaded

bcftools sort -Oz ${prefix}/vcf/\${name}.vcf.gz > ${prefix}/vcf/\${name}_snps.vcf.gz

bcftools index --threads $thr ${prefix}/vcf/\${name}_snps.vcf.gz

# remove unsorted SNP VCF

rm ${prefix}/vcf/\${name}.vcf.gz

# === END ===========================================================================================

echo "Finished working with \${name}"

EOT


