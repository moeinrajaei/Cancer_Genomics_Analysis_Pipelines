
#!/bin/sh
#SBATCH --job-name=Pembrolizumab_pre_processing # Job name
#SBATCH --mail-type=ALL # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=moein.rajaei@yale.edu # Where to send mail
#SBATCH --cpus-per-task=16 # Number of CPU cores per task
#SBATCH --ntasks=1 # Run a single task
#SBATCH --mem=32gb # Memory limit
#SBATCH --partition=week
#SBATCH --time=4-00:01:00 # Time limit hrs:min:sec
#SBATCH --output=Pembrolizumab_pre_processing%j.out # Standard output and error log


### step 1: Raw quality check using fastqcmodule load FastQC/0.11.9-Java-11
module load FastQC/0.11.9-Java-11
mkdir raw_quality
fastqc -o raw_quality -f fastq -t 8 *.fastq.gz

### Step 2: Adapter trimming using fastp: 
module load fastp/0.23.2-GCCcore-10.2.0

for R1 in *R1*; do
R2=${R1//R1_001.fastq.gz/R2_001.fastq.gz}
    fastp --detect_adapter_for_pe \
    -i "$R1" \
    -I "$R2" \
    -o "${R1/%.fastq.gz/.trimmed.fastq.gz}" \
    -O "${R2/%.fastq.gz/.trimmed.fastq.gz}" \
    --html "${R1/%_R1_001.fastq.gz/.html}" \
    --json "${R1/%_R1_001.fastq.gz/.json}"
done

### Step 3: Allignment using BWA & SAMTOOLS:
module load BWA
module load SAMtools
module load BamTools
#bwa index Homo_sapiens_assembly38.fasta

for R1 in *R1_001.trimmed.fastq.gz; do
R2=${R1//R1_001.trimmed.fastq.gz/R2_001.trimmed.fastq.gz}
bwa mem -t 8 -T 0 Homo_sapiens_assembly38.fasta "$R1" "$R2" > "${R1/%_R1_001.trimmed.fastq.gz/.sam}"
done

for i in *.sam; do
    samtools view -hb -o "${i/%.sam/.bam}" "$i"
done

rm *.sam
 
###STEP 4: sorting the bam file using PICARD:
module load picard/2.25.6-Java-11

for i in *.bam; do
    java -jar $EBROOTPICARD/picard.jar SortSam \
    CREATE_INDEX=true \
    INPUT="$i" \
    OUTPUT= "${i/%.bam/.output.bam}" \
    SORT_ORDER=coordinate \
    VALIDATION_STRINGENCY=STRICT
done 

rm *L001.bam
rm *L002.bam
rm *L004.bam

### STEP 5: Adding read_group using PICARD:
for i in *.output.bam; do
    x=`basename $i .output.bam`
    java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
      I="$i" \
      O="${i/%.output.bam/.RG.bam}" \
      RGID="$i" \
      RGLB="$x" \
      RGPL=illumina \
      RGPU="$i" \
      RGSM="$x"
done

rm *.output.bam
rm *.output.bai

### STEP 6: MARK DUPLICATES using PICARD:
for i in *.RG.bam; do
    java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
    CREATE_INDEX=true \
    INPUT="$i" \
    VALIDATION_STRINGENCY=STRICT \
    O="${i/%.RG.bam/.MarkDuplicates.bam}" \
    M="${i/%.RG.bam/.marked_dup_metrics.txt}" 
done

rm *.RG.bam

### STEP 7: Base Quality Score Recalibration (BQSR) using BaseRecalibrator & ApplyBQSR:
#BaseRecalibrator:
module load GATK/4.4.0.0-GCCcore-10.2.0-Java-17

for i in *.MarkDuplicates.bam; do
    gatk BaseRecalibrator \
    -I "$i" \
    -R Homo_sapiens_assembly38.fasta \
    --known-sites 1000G_phase1.snps.high_confidence.hg38.vcf.gz \
    --known-sites Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
    -O "${i/%.MarkDuplicates.bam/.recal.table}"
done

#ApplyBQSR:

for i in *.MarkDuplicates.bam; do
x=${i//.MarkDuplicates.bam/.recal.table}
    gatk ApplyBQSR \
    -R Homo_sapiens_assembly38.fasta \
    -I "$i" \
    --bqsr-recal-file "$x" \
    -O "${i/%.MarkDuplicates.bam/.BQSR.bam}"
done


#END
