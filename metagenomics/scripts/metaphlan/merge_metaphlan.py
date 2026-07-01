#!/usr/bin/env python
import pandas as pd
import os
import sys
import glob

# Define a list to store dataframes
dfs = []

# Loop through all files matching the specified pattern
for file in glob.glob(os.path.join(sys.argv[1], '*_metaphlan-gtdb.txt')):
    # Extract sample name
    sample_name = os.path.basename(file).split('_')[0]
    
    # Read the file using pandas
    df = pd.read_csv(file, sep='\t', skiprows=1)
    
    # Rename columns
    df = df.rename(columns={
        '#clade_name': 'clade_name',
        'relative_abundance': f'{sample_name}_relative_abundance',
        'coverage': f'{sample_name}_coverage',
        'estimated_number_of_reads_from_the_clade': f'{sample_name}_counts'
    })

    # Sometimes a clade_name appears twice in a file - presumably due to
    # SGB -> GTDB taxonomy conversion
    # Group by 'clade_name' and sum the values, then reset the index
    df = df.groupby('clade_name').sum().reset_index()

    # Append the dataframe to dfs list
    dfs.append(df)

# Merge dataframes on 'clade_name' and 'clade_taxid'
merged_df = dfs[0]
for df in dfs[1:]:
    merged_df = pd.merge(merged_df, df, on=['clade_name', 'clade_taxid'], how='outer')

# Sum down identical clade_name rows
merged_df = merged_df.groupby('clade_name').sum().reset_index()

# Reorder columns
cols = ['clade_name', 'clade_taxid'] + sorted(
    [col for col in merged_df.columns 
     if col not in ['clade_name', 'clade_taxid']])

merged_df = merged_df[cols]

# Output to stdout
print(merged_df.to_csv(sep='\t', index=False))
