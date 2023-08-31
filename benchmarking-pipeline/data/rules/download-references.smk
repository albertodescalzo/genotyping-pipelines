bwa=config['programs']['bwa']

# get reference sequence (hg38)
rule download_reference_hg38:
	output:
		fasta="downloaded/fasta/GRCh38_full_analysis_set_plus_decoy_hla.fa"
	shell:
		"wget -O {output} http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/technical/reference/GRCh38_reference_genome/GRCh38_full_analysis_set_plus_decoy_hla.fa"

# index hg38 fasta
rule index:
	input:
		"{filename}.fa"
	output:
		"{filename}.fa.fai"
	shell:
		"samtools faidx {input}"

## index fasta
rule bwa_index:
	input:
		"downloaded/{filename}.fa"
	output:
		"downloaded/{filename}.fa" + ".ann"
	log:
		"downloaded/{filename}-indexing.log"
	resources:
		mem_total_mb=5000
	shell:
		"(/usr/bin/time -v {bwa} index {input}) &> {log}"


rule download_BayesTyper_GRCh38_bundle:
    output:
        compressed_bundle="downloaded/bayestyper/bayestyper_GRCh38_bundle.tar.gz", 
        uncompressed_bundle=directory("downloaded/bayestyper")
    shell:
        """
        wget -O {output.compressed_bundle} http://people.binf.ku.dk/~lassemaretty/bayesTyper/bayestyper_GRCh38_bundle.tar.gz 
        tar -xvf {output.compressed_bundle} -C {output.uncompressed_bundle} 
        """
