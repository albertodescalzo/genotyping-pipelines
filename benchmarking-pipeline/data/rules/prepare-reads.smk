configfile: "config.json"

input_reference=config['data']['reference']
outname=config['parameters']['outname_reads']


##############################################################
#################   prepared aligned data     ##################
##############################################################


### data for mapping based approaches ####

## index fasta
rule bwa_index:
	input:
		input_reference
	output:
		input_reference + ".ann"
	log:
		"{results}/reference-indexing.log".format(results=outname)
	conda:
		'../env/genotyping.yml'
	resources:
		mem_total_mb=5000
	shell:
		"(/usr/bin/time -v bwa index {input}) &> {log}"

## create fasta.fai file
rule samtools_faidx:
	input:
		input_reference
	output:
		input_reference + '.fai'
	conda:
		'../env/genotyping.yml'
	shell:
		"samtools faidx {input}"

rule bwa_mem:
	input:
		reads=lambda wildcards: config['data'][wildcards.sample]['reads'],
		fasta=input_reference,
		index=input_reference + '.ann',
		fai=input_reference + '.fai'
		#reads=bwa_mem_input,
	output:
		'{results}/{sample}/aligned/{sample}.bam'
	log:
		'{results}/{sample}/aligned/{sample}.log'
	threads: 24
	resources:
		mem_total_mb=60000,
		runtime_hrs=25,
		runtime_min=1
	conda:
		'../env/genotyping.yml'
	shell:
		'(/usr/bin/time -v bwa mem -t {threads} -M {input.fasta} -R "@RG\\tID:{wildcards.sample}\\tLB:lib1\\tPL:illumina\\tPU:unit1\\tSM:{wildcards.sample}" {input.reads} | samtools view -bS | samtools sort -o {output} - ) &> {log}'

## index BAM file
rule samtools_index:
	input:
		"{filename}.bam"
	output:
		"{filename}.bam.bai"
	log:
		"{filename}-index.log"
	conda:
		'../env/genotyping.yml'
	shell:
		"(/usr/bin/time -v samtools index {input}) &> {log}"

## split BAM by chromosome
rule split_bam_by_chromosome:
	input:
		bam='{results}/{sample}/aligned/{sample}.bam',
		bai='{results}/{sample}/aligned/{sample}.bam.bai'
	output:
		bam='{results}/{sample}/aligned/{sample}.chr{chrom, X|Y|[0-9]+}.bam'
	conda:
		'../env/genotyping.yml'
	shell:
		"""
        samtools view -h {input.bam} chr{wildcards.chrom} | samtools view -Sb -> {output.bam}
        """
