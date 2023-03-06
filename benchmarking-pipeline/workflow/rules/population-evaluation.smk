import gzip
configfile: "config/config.yaml"

cohort_samples = []
for line in open(config['reads'], 'r'):
	if line.startswith('#'):
		continue
	fields = line.strip().split() 
	cohort_samples.append(fields[1])

panel_samples = {}
for callset in config['callsets'].keys():
	for line in gzip.open(config['callsets'][callset]['multi'], 'rt'):
		if line.startswith("#CHROM"):
			panel_samples[callset] = line.strip().split()[9:]
			break


rule collect_samples:
	input:
		config['reads']
	output:
		all="results/population-typing/{callset}/sample-index.tsv",
		related="results/population-typing/{callset}/sample-index-related.tsv",
		unrelated="results/population-typing/{callset}/sample-index-unrelated.tsv"
	run:
		with open(output.all, 'w') as all_samples, open(output.related, 'w') as related_samples, open(output.unrelated, 'w') as unrelated_samples, open(input[0], 'r') as infile:
			for line in infile:
				if line.startswith("#"):
					continue
				fields = line.strip().split()
				sample = fields[1]
				all_samples.write(sample + '\n')
				if (fields[2] == '0') and (fields[3] == '0'):
					# unrelated sample
					unrelated_samples.write(sample + '\n')
				else:
					# related sample
					related_samples.write(sample + '\n')



####################################################################
# extract necessary subsets of samples (e.g. all unrelated samples
####################################################################

rule extract_samples:
	input:
		vcf="results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/all-samples_bi_all.vcf.gz",
		samples="results/population-typing/{callset}/sample-index-unrelated.tsv"
	output:
		"results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/unrelated-samples_bi_all.vcf.gz"
	resources:
		mem_total_mb = 50000,
		runtime_hrs = 10
	conda:
		"../envs/genotyping.yml"
	shell:
		"bcftools view --samples-file {input.samples} --force-samples {input.vcf} | bgzip -c > {output}"



################################################################
# HWE testing and analysis
################################################################

# compute filtered callsets
rule filtered_callsets:
	input:
		vcf="results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/{population}_bi_all.vcf.gz",
		filters="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/plot_bi_all_filters.tsv"
	output:
		"results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/filtered/{population}_bi_all_{filter}.vcf.gz"
	resources:
		mem_total_mb=20000,
		runtime_hrs=10,
		runtime_min=59
	wildcard_constraints:
		filter="unfiltered|lenient|strict",
		population="all-samples|unrelated-samples"
	shell:
		"zcat {input.vcf} | python3 workflow/scripts/select_ids.py {input.filters} {wildcards.filter} | bgzip -c > {output}"


rule test_hwe:
	input:
		vcf="results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/filtered/unrelated-samples_bi_all_{filter}.vcf.gz",
		bed= lambda wildcards: config['callsets'][wildcards.callset]['repeat_regions'] if wildcards.region == "repeat" else "results/population-typing/{callset}/bed/non-repetitive-regions.bed"
	output:
		hwe="results/population-typing/{callset}/{version}/{coverage}/evaluation/hwe/unrelated-samples_{filter, unfiltered|lenient|strict}_{varianttype}-{region}.hwe",
		vcf="results/population-typing/{callset}/{version}/{coverage}/evaluation/hwe/unrelated-samples_{filter, unfiltered|lenient|strict}_{varianttype}-{region}.vcf"
	params:
		prefix = "results/population-typing/{callset}/{version}/{coverage}/evaluation/hwe/unrelated-samples_{filter, unfiltered|lenient|strict}_{varianttype}-{region}",
		bedtools = lambda wildcards: "-u" if wildcards.region == "repeat" else "-f 1.0 -u" 
	conda:
		'../envs/vcftools.yml'
	wildcard_constraints:
		filter="unfiltered|lenient|strict",
		region="repeat|nonrep",
		varianttype="|".join(['snp', 'small-deletion', 'small-insertion', 'small-complex', 'midsize-deletion', 'midsize-insertion', 'large-complex', 'large-deletion', 'large-insertion', 'large-complex'])
	resources:
		mem_total_mb=30000,
		runtime_hrs=2,
		runtime_min=59
	shell:
		"""
		zcat {input.vcf} | python3 workflow/scripts/extract-varianttype.py {wildcards.varianttype} | bedtools intersect -header -a - -b {input.bed} {params.bedtools} > {output.vcf}	
		vcftools --vcf {output.vcf} --hardy --max-missing 0.9 --out {params.prefix}
		"""

# get all regions outside of repeat regions
rule get_non_repeat_regions:
	input:
		fai = lambda wildcards: config['callsets'][wildcards.callset]['reference'] + '.fai',
		repeats = lambda wildcards: config['callsets'][wildcards.callset]['repeat_regions']
	output:
		subset_bed = temp("results/population-typing/{callset}/bed/bed-tmp.bed"),
		fai = temp("results/population-typing/{callset}/bed/fai-tmp.bed"),
		bed = temp("results/population-typing/{callset}/bed/non-repetitive-regions.bed")
	conda:
		"../envs/genotyping.yml"
	shell:
		"bash workflow/scripts/non-repetitive-regions.sh {input.repeats} {output.subset_bed} {input.fai} {output.fai} {output.bed}"


def hwe_statistics_files(wildcards):
	files = []
	hwe_variants = [v for v in config['callsets'][wildcards.callset]['variants']]
	for var in hwe_variants:
		for reg in ["repeat", "nonrep"]:
			files.append("results/population-typing/{callset}/{version}/{coverage}/evaluation/hwe/unrelated-samples_{filter}_{varianttype}-{region}.hwe".format(callset=wildcards.callset, version=wildcards.version, coverage=wildcards.coverage, filter=wildcards.filter, varianttype=var, region=reg))
	return files


def hwe_statistics_labels(wildcards):
	labels = []
	hwe_variants = [v for v in config['callsets'][wildcards.callset]['variants']]
	for var in hwe_variants:
		for reg in ["repeat", "nonrep"]:
			labels.append(var + '-' + reg)
	return labels
	

rule compute_hwe_statistics:
	input:
		hwe_statistics_files
	output:
		tsv="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/{filter}/unrelated-samples_{filter}_hwe.tsv"
	log:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/{filter}/unrelated-samples_{filter}.log"
	params:
		outname="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/{filter}/unrelated-samples_{filter}",
		labels=hwe_statistics_labels
	conda:
		'../envs/genotyping.yml'
	resources:
		mem_total_mb=20000,
		runtime_hrs=2
	shell:
		"python3 workflow/scripts/hwe.py {input} --labels {params.labels} --outname {params.outname} &> {log}"


###################################################
# compute mendelian consistency
###################################################

# count variants mendelian consistent in 0,1,2,...,nr_trios trios
rule check_consistent_trios:
	input:
		vcf = "results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/all-samples_bi_all.vcf.gz",
		ped = config['reads'],
		samples = "results/population-typing/{callset}/sample-index.tsv"
	output:
		variant_stats="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/mendelian-statistics_bi_all.tsv",
		trio_stats="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/trio-statistics_bi_all.tsv"
	log:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/mendelian-statistics_bi_all.log"
	conda:
		"../envs/genotyping.yml"
	resources:
		mem_total_mb=300000,
		runtime_hrs=96,
		runtime_min=59
	shell:
		"python3 workflow/scripts/mendelian-consistency.py statistics -vcf {input.vcf} -ped {input.ped} -samples {input.samples} -table {output.variant_stats} -column-prefix pangenie > {output.trio_stats}"


###################################################
# compute allele frequency/genotype statistics
###################################################

rule compute_statistics:
	input:
		vcf = "results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/unrelated-samples_bi_all.vcf.gz",
		vcf_all = "results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/all-samples_bi_all.vcf.gz",
		panel = lambda wildcards: config['callsets'][wildcards.callset]['bi']
	output:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/genotyping-statistics_bi_all.tsv"
	conda:
		'../envs/genotyping.yml'
	resources:
		mem_total_mb=200000,
		runtime_hrs=96,
		runtime_min=59
	shell:
		"python3 workflow/scripts/collect-vcf-stats.py {input.panel} {input.vcf} {input.vcf_all} > {output}"



#########################################
# self-genotyping evaluation
#########################################


# genotyping concordance for each ID (over all samples)
rule genotype_concordance_variants:
	input:
		computed="results/population-typing/{callset}/{version}/{coverage}/merged-vcfs/whole-genome/all-samples_bi_all.vcf.gz",
		true = lambda wildcards: config['callsets'][wildcards.callset]['bi']
	output:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/self_bi_all_variant-stats.tsv"
	params:
		file_prefix="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/self_bi_all",
		column_prefix="pangenie_self-genotyping",
		# restrict to panel samples for which reads are available
		samples = lambda wildcards: ','.join( list( set(panel_samples[wildcards.callset]) & set(cohort_samples) ) )
	conda:
		"../envs/genotyping.yml"
	resources:
		mem_total_mb=500000,
		runtime_hrs=40,
		runtime_min=59
	log:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/self_bi_all_variant-stats.log"
	shell:
		"python3 workflow/scripts/genotype-concordance-variant.py {input.true} {input.computed} {params.file_prefix} {params.samples} {params.column_prefix} &> {log}"


#################################################
# make a table containing var ID and bubble ID
#################################################

rule variant_id_to_bubble:
	input:
		lambda wildcards: config['callsets'][wildcards.callset]['multi']
	output:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/bubble-statistics_bi_all.tsv"
	shell:
		"zcat {input} | python3 workflow/scripts/id_to_bubble.py > {output}"


#################################################
# annotate variants by BED file
#################################################

rule annotate_variants:
	input:
		vcf = lambda wildcards: config['callsets'][wildcards.callset]['bi'],
		bed = lambda wildcards: config['callsets'][wildcards.callset]['repeat_regions']
	output:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/annotations_bi_all.tsv"
	conda:
		"../envs/genotyping.yml"
	resources:
		mem_total_mb=70000,
		runtime_hrs=1,
		runtime_min=59
	shell:
		"bedtools annotate -i {input.vcf} -files {input.bed} | python3 workflow/scripts/annotate_repeats.py -names repeats -format tsv > {output}"


#################################################
# plot the results
#################################################


rule merge_table:
	input:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/genotyping-statistics_bi_all.tsv",
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/mendelian-statistics_bi_all.tsv",
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/self_bi_all_variant-stats.tsv",
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/bubble-statistics_bi_all.tsv",
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/annotations_bi_all.tsv"
	output:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/summary_bi_all.tsv"
	conda:
		"../envs/plotting.yml"
	resources:
		mem_total_mb=50000,
		runtime_hrs=5,
		runtime_min=1
	shell:
		"python3 workflow/scripts/merge-tables.py {input} {output}"


rule plot_statistics:
	input:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/all/summary_bi_all.tsv"
	output:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/plot_bi_all_filters.tsv"
	params:
		outprefix="results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/plot_bi_all"
	log:
		"results/population-typing/{callset}/{version}/{coverage}/evaluation/statistics/plot_bi_all.log"
	conda:
		'../envs/plotting.yml'
	resources:
		mem_total_mb=200000,
		runtime_hrs=8,
		runtime_min=59
	shell:
		"python3 workflow/scripts/analysis.py {input} {params.outprefix} &> {log}"

