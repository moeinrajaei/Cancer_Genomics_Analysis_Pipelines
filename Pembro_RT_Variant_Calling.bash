#!/bin/sh
#SBATCH --job-name=Mutect2_Tumor_with_matched_normal # Job name
#SBATCH --mail-type=ALL # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=moein.rajaei@yale.edu # Where to send mail
#SBATCH --cpus-per-task=8 # Number of CPU cores per task
#SBATCH --ntasks=1 # Run a single task
#SBATCH --mem-per-cpu=8G # Memory limit
#SBATCH --time=21:05:00 # Time limit hrs:min:sec
#SBATCH --output=Pembro_RT_Mutect2_Tumor_with_matched_normal.out # Standard output and error log


module load GATK/4.4.0.0-GCCcore-10.2.0-Java-17

### Tumor with matched normal
gatk Mutect2 \
    -R Homo_sapiens_assembly38.fasta \
    -I 7275-2C4_167_026_S19_L002.BQSR.bam \
    -I 7275-2BL_179_014_S18_L002.BQSR.bam \
    -normal 7275-2BL_179_014_S18_L002 \
    --germline-resource af-only-gnomad.hg38.vcf.gz \
    --intervals xgen-exome-hyb-panel-v2-targets-hg38.bed \
    --panel-of-normals gatk4_mutect2_4136_pon.vcf.gz \
    --f1r2-tar-gz 7275-2C4_167_026_S19_L002.2C4_2BL.f1r2.tar.gz \
    --tmp-dir tmp \
    -O 7275-2C4_167_026_S19_L002.2C4_2BL.vcf.gz
	
gatk Mutect2 \
    -R Homo_sapiens_assembly38.fasta \
    -I 7275-3C4_143_050_S55_L001.BQSR.bam \
    -I 7275-3BL_155_038_S54_L001.BQSR.bam \
    -normal 7275-3BL_155_038_S54_L001 \
    --germline-resource af-only-gnomad.hg38.vcf.gz \
    --intervals xgen-exome-hyb-panel-v2-targets-hg38.bed \
    --panel-of-normals gatk4_mutect2_4136_pon.vcf.gz \
    --f1r2-tar-gz 7275-3C4_143_050_S55_L001.3C4_3BL.f1r2.tar.gz \
    --tmp-dir tmp \
    -O 7275-3C4_143_050_S55_L001.3C4_3BL.vcf.gz
		
### Learn Orientation Bias Artifacts: Tools involved: LearnReadOrientationModel
for i in *.f1r2.tar.gz; do
    gatk LearnReadOrientationModel \
    -I "$i" \
    -O "${i/%.f1r2.tar.gz/.read-orientation-model.tar.gz}"
done

##Calculate Contamination: Tools involved: GetPileupSummaries, CalculateContamination
#GetPileupSummaries
for i in *.BQSR.bam; do
    gatk GetPileupSummaries \
    -I "$i" \
    -V small_exac_common_3.hg38.vcf.gz \
    -L small_exac_common_3.hg38.vcf.gz \
    -O "${i/%.BQSR.bam/.getpileupsummaries.table}" 
done

#CalculateContamination
for i in *.getpileupsummaries.table; do
    gatk CalculateContamination \
    -I "$i" \
    -tumor-segmentation "${i/%.getpileupsummaries.table/.segments.table}"  \
    -O "${i/%.getpileupsummaries.table/.calculatecontamination.table}"
done

### Filter Variants: Tools involved: FilterMutectCalls
gatk FilterMutectCalls \
    -V 7275-2C4_167_026_S19_L002.2C4_3BL.vcf.gz \
    -R Homo_sapiens_assembly38.fasta \
    --tumor-segmentation 7275-2C4_167_026_S19_L002.segments.table \
    --contamination-table 7275-2C4_167_026_S19_L002.calculatecontamination.table \
    --ob-priors 7275-2C4_167_026_S19_L002.2C4_3BL.read-orientation-model.tar.gz \
    -O 7275-2C4_167_026_S19_L002.2C4_3BL.filtered.vcf.gz

gatk FilterMutectCalls \
    -V 7275-3C4_143_050_S55_L001.3C4_3BL.vcf.gz \
    -R Homo_sapiens_assembly38.fasta \
    --tumor-segmentation 7275-3C4_143_050_S55_L001.segments.table \
    --contamination-table 7275-3C4_143_050_S55_L001.calculatecontamination.table \
    --ob-priors 7275-3C4_143_050_S55_L001.3C4_3BL.read-orientation-model.tar.gz \
    -O 7275-3C4_143_050_S55_L001.3C4_3BL.filtered.vcf.gz

for i in *.filtered.vcf.gz; do
    gatk SelectVariants \
    -V "$i" \
    -R Homo_sapiens_assembly38.fasta \
    -O "${i/%.filtered.vcf.gz/.final.vcf.gz}" \
    --exclude-non-variants true \
    --exclude-filtered true \
    --tmp-dir tmp
done

### Annotation usinf annovar:
module load annovar/2019Oct24-GCCcore-10.2.0-Perl-5.32.0

table_annovar.pl humandb/7275-3C4_143_050_S55_L001.3C4_3BL.final.vcf humandb/ -buildver hg38 -out 3C4 -remove -protocol refGene -operation g -nastring . -vcfinput -polish
table_annovar.pl humandb/7275-2C4_167_026_S19_L002.2C4_2BL.final.vcf humandb/ -buildver hg38 -out output/2C4 -remove -protocol refGene -operation g -nastring . -vcfinput -polish


#END

