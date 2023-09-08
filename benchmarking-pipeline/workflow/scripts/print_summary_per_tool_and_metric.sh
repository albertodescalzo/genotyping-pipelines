#!/bin/bash

# Define the folder containing the TSV files
#folders=("/vol/whopper/genotyping-pipelines/benchmarking-pipeline/results/leave-one-out/HGSVC/bayestyper/plots/full/" "/vol/whopper/genotyping-pipelines/benchmarking-pipeline/results/leave-one-out/HGSVC/pangenie.v3/plots/full/" "/vol/whopper/genotyping-pipelines/benchmarking-pipeline/results/leave-one-out/HGSVC/graphtyper/plots/full/")
folders=("/vol/whopper/genotyping-pipelines/benchmarking-pipeline/results/leave-one-out/HGSVC/pangenie.v3/plots/full/")

for folder in "${folders[@]}"; do
    # Loop through each TSV file in the folder
    for file in "$folder"/*.tsv; do
        # Check if the file exists
        if [ -e "$file" ]; then
            # Extract the filename without the path
            filename=$(basename "$file")
            
            # Get the second line of the TSV file
            second_line=$(sed -n '2p' "$file")
            
            # Output the filename and the second line
            echo "$filename"
            echo "$second_line"
            echo
        fi
    done
done