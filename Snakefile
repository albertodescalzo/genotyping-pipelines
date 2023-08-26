### Copy all folders from benchmarking-pipeline-jana except for results and downloaded within data

rule copy_data_wout_downloaded:
    input:
        "/vol/bigmac/genotyping-pipelines-jana/benchmarking-pipeline/data"
    output:
        directory("/vol/bigmac/genotyping-pipelines/benchmarking-pipeline/data")
    shell:
        "rsync -av --exclude='downloaded/' --exclude='.snakemake/' {input}/ {output}"

rule copy_benchamrking_wout_results_and_data:
    input:
        "/vol/bigmac/genotyping-pipelines-jana/benchmarking-pipeline"
    output:
        directory("/vol/bigmac/genotyping-pipelines/benchmarking-pipeline")
    shell:
        "rsync -av --exclude='results/' --exclude='data/' {input}/ {output}"