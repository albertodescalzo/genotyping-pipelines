
rule reduce_vcf_callset:
    input:
        "downloaded/vcf/HGSVC-GRCh38/Callset_freeze3_64haplotypes.vcf.gz"
    output: 
        "downloaded/vcf/HGSVC-GRCh38/Callset_reduced.vcf.gz"
    shell:
        "bcftools view -r chr21 {input} | bgzip > {output}"

rule reduce_vcf_graph:
    input:
        "downloaded/vcf/HGSVC-GRCh38/Pangenome_graph_freeze3_64haplotypes.vcf.gz"
    output: 
        "downloaded/vcf/HGSVC-GRCh38/Pangenome_reduced.vcf.gz"
    shell:
        "bcftools view -r chr21 {input} | bgzip > {output}"

        