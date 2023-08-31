configfile: 'config.json'

include: "rules/download-references.smk"
include: "rules/download-reads-NA24385.smk"
include: "rules/download-bed.smk"
include: "rules/download-graphs-and-callsets.smk"
include: "rules/input-preprocessing.smk"

sample = config["dataset"]["leave_out_sample"]

rule all:
    input:
        "downloaded/bed/hg38/ucsc-simple-repeats.merged.bed",

        # references
        'downloaded/fasta/GRCh38_full_analysis_set_plus_decoy_hla.fa',
        'downloaded/fasta/GRCh38_full_analysis_set_plus_decoy_hla.fa.fai',
        "downloaded/fasta/GRCh38_full_analysis_set_plus_decoy_hla.fa.ann",
        
        # Input Pangenome Graph (PanGenie Github)
        'downloaded/vcf/HGSVC-GRCh38/Pangenome_graph_freeze3_64haplotypes.vcf.gz',
        
        # Callset (PanGenie Github)
        'downloaded/vcf/HGSVC-GRCh38/Callset_freeze3_64haplotypes.vcf.gz',
         
        # reads
        expand("downloaded/reads/{sample}/{sample}_raw.fastq.gz", sample=sample),

        ## Download GRCh38 bundle for BayesTyper
        "downloaded/bayestyper/bayestyper_GRCh38_bundle.tar.gz",

        ## Reduced data sets
        "downloaded/vcf/HGSVC-GRCh38/Callset_reduced.vcf.gz",
        "downloaded/vcf/HGSVC-GRCh38/Pangenome_reduced.vcf.gz"
        