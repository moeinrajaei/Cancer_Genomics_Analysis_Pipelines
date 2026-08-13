# WES Somatic Variant Calling Pipeline

This repository contains the bioinformatics pipeline used for **preprocessing, alignment, somatic variant calling, and annotation of whole-exome sequencing (WES) data** for the project:

**“A Phase II Study of Pembrolizumab for Patients with Head and Neck Squamous Cell Carcinoma with Residual Disease Following Definitive Chemoradiation.”**

## Pipeline Overview

The workflow includes:

* Raw sequencing quality assessment
* Adapter trimming and quality filtering
* Alignment to the human reference genome (**GRCh38/hg38**)
* BAM preprocessing
* Base quality score recalibration
* Somatic SNV and indel calling
* Variant filtering
* Functional annotation

## Analysis Workflow

```text
Raw FASTQ files
      │
      ▼
Quality Control
   (FastQC)
      │
      ▼
Adapter & Quality Trimming
     (fastp)
      │
      ▼
Read Alignment
   (BWA-MEM)
      │
      ▼
BAM Processing
(SAMtools / Picard)
      │
      ▼
Base Quality Score Recalibration
       (GATK)
      │
      ▼
Somatic Variant Calling
  (GATK Mutect2)
      │
      ▼
Variant Filtering
      │
      ▼
Functional Annotation
     (ANNOVAR)
```

## Pipeline Steps

### 1. Quality Control

Raw FASTQ files were evaluated for sequencing quality using **FastQC**.

**Software:** FastQC v0.11.9

### 2. Adapter Trimming

Sequencing adapters and low-quality bases were removed using **fastp** with automatic paired-end adapter detection.

**Software:** fastp v0.23.2

### 3. Read Alignment

Trimmed reads were aligned to the **GRCh38 (hg38)** human reference genome using **BWA-MEM**.

SAM files were subsequently converted to BAM format using **SAMtools**.

**Software:** BWA, SAMtools

### 4. BAM Processing

Aligned BAM files were:

* Coordinate sorted
* Indexed
* Assigned read groups
* Duplicate marked

**Software:** Picard v2.25.6

### 5. Base Quality Score Recalibration

Base quality scores were recalibrated using **GATK BaseRecalibrator** with established SNP and indel resources.

Known sites included:

* 1000 Genomes Phase 1 SNPs
* Mills and 1000 Genomes Gold Standard Indels

**Software:** GATK v4.4.0.0

### 6. Somatic Variant Calling

Somatic SNVs and indels were called using **GATK Mutect2** in matched tumor-normal mode.

The workflow incorporated:

* gnomAD germline resource
* GATK Panel of Normals (PoN)
* Read-orientation artifact modeling
* Contamination estimation

Variants were processed and filtered using:

* `LearnReadOrientationModel`
* `GetPileupSummaries`
* `CalculateContamination`
* `FilterMutectCalls`
* `SelectVariants`

**Software:** GATK v4.4.0.0

### 7. Variant Annotation

High-confidence somatic variants were functionally annotated using **ANNOVAR** with the RefGene annotation database.

**Software:** ANNOVAR (2019Oct24)

## Software Requirements

| Software | Version                   |
| -------- | ------------------------- |
| FastQC   | 0.11.9                    |
| fastp    | 0.23.2                    |
| BWA      | Latest compatible version |
| SAMtools | Latest compatible version |
| Picard   | 2.25.6                    |
| GATK     | 4.4.0.0                   |
| ANNOVAR  | 2019Oct24                 |

## Reference Genome

**GRCh38 / hg38**

## Required Reference Resources

The pipeline requires the following reference files and genomic resources:

* Human reference genome (**GRCh38**)
* gnomAD germline resource
* GATK Panel of Normals
* 1000 Genomes Phase 1 SNPs
* Mills and 1000 Genomes Gold Standard Indels
* ExAC common variants
* RefGene annotation database

## Output

The workflow generates:

* Quality-controlled sequencing reads
* Trimmed FASTQ files
* Aligned and processed BAM files
* Recalibrated BAM files
* Raw somatic variant calls
* Filtered high-confidence somatic SNVs and indels
* Functionally annotated variants

## Author

**Moein Rajaei, Ph.D.**

Computational Biologist | Cancer Genomics Data Scientist
