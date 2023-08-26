### This downloads both pangenome graphs as well as the known set of variants derived called from the assemblies, i.e. callsets
scripts = config['scripts']
sample = config['dataset']['leave_out_sample'][0]

subset_to_samples = {
    'only' + sample: [sample],
    'no' + sample: ["^" + sample]
}

rule download_HGSVC_GRCh38_freeze3_64haplotypes_pangenome_graph:
    output:
        vcf="downloaded/vcf/HGSVC-GRCh38/Pangenome_graph_freeze3_64haplotypes.vcf.gz",
        tbi="downloaded/vcf/HGSVC-GRCh38/Pangenome_graph_freeze3_64haplotypes.vcf.gz.tbi",
    shell:
        """
        wget -O {output.vcf} https://zenodo.org/record/7763717/files/pav-panel-freeze3.vcf.gz?download=1
        tabix -f -p vcf {output.vcf} > {output.tbi}
        """

rule download_HGSVC_GRCh38_freeze3_64haplotypes_callset:
    output:
        callset="downloaded/vcf/HGSVC-GRCh38/Callset_freeze3_64haplotypes.vcf.gz",
        callset_tbi="downloaded/vcf/HGSVC-GRCh38/Callset_freeze3_64haplotypes.vcf.gz.tbi"
    shell:
        """
        wget -O {output.callset} https://zenodo.org/record/7763717/files/pav-calls-freeze3.vcf.gz?download=1
        tabix -f -p vcf {output.callset} > {output.callset_tbi}
        """

rule download_HPRC_GRCh38_88haplotypes_pangenome_graph:
    output:
        vcf="downloaded/vcf/HPRC-GRCh38/Pangenome_graph_88haplotypes.vcf.gz", 
        tbi="downloaded/vcf/HPRC-GRCh38/Pangenome_graph_88haplotypes.vcf.gz.tbi",
    shell:
        """
        wget -O {output.vcf} https://zenodo.org/record/6797328/files/cactus_filtered_ids.vcf.gz?download=1 
        tabix -f -p vcf {output.vcf} > {output.tbi}
        """

rule download_HPRC_GRCh38_88haplotypes_callset:
    output:
        callset="downloaded/vcf/HPRC-GRCh38/Callset_88haplotypes.vcf.gz", 
        callset_tbi="downloaded/vcf/HPRC-GRCh38/Callset_88haplotypes.vcf.gz.tbi"
    shell:
        """
        wget -O {output.callset} https://zenodo.org/record/6797328/files/cactus_filtered_ids_biallelic.vcf.gz?download=1
        tabix -f -p vcf {output.callset} > {output.callset_tbi}
        """

