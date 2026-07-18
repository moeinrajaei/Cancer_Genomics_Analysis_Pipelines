This repository contains the bioinformatics pipeline used for preprocessing, alignment, somatic variant calling, and annotation of whole-exome sequencing (WES) data for this project: "A Phase II study of Pembrolizumab for patients with head and neck squamous cell carcinoma with residual disease following definitive chemoradiation". 
The pipeline includes:
Raw sequencing quality assessment
Adapter trimming and quality filtering
Alignment to the human reference genome (hg38)
BAM preprocessing
Somatic SNV and indel calling
Variant filtering
Functional annotation
Pipeline

1. Quality Control
Raw FASTQ files were evaluated using FastQC.
Software: FastQC v0.11.9

2. Adapter Trimming
Adapters and low-quality bases were removed using fastp with automatic paired-end adapter detection.
Software: fastp v0.23.2

3. Read Alignment
Trimmed reads were aligned to the GRCh38 (hg38) reference genome using BWA-MEM.
SAM files were converted to BAM format using SAMtools.
Software: BWA, SAMtools

4. BAM Processing
BAM files were coordinate sorted, indexed, assigned read groups, duplicate marked using Picard.
Software: Picard v2.25.6

5. Base Quality Score Recalibration
Base quality scores were recalibrated using GATK BaseRecalibrator with known SNP and indel databases.
Known sites:
1000 Genomes Phase 1 SNPs
Mills and 1000 Genomes Gold Standard Indels
Software: GATK v4.4.0.0

6. Somatic Variant Calling
Somatic variants were called using GATK Mutect2 in matched tumor–normal mode.
The analysis incorporated: gnomAD germline resource, GATK Panel of Normals (PoN), Read orientation modeling, Contamination estimation
Variants were filtered using:
LearnReadOrientationModel
GetPileupSummaries
CalculateContamination
FilterMutectCalls
SelectVariants

7. Variant Annotation
High-confidence variants were annotated using ANNOVAR with the RefGene database.
Software: ANNOVAR (2019Oct24)

Software Requirements:
FastQC	0.11.9
fastp	0.23.2
BWA	latest
SAMtools	latest
Picard	2.25.6
GATK	4.4.0.0
ANNOVAR	2019Oct24

Reference Genome:
GRCh38 / hg38

Required reference resources include:
Human reference genome (GRCh38)
gnomAD germline resource
GATK Panel of Normals
1000 Genomes Phase 1 SNPs
Mills and 1000G Gold Standard Indels
ExAC common variants
RefGene annotation database
