{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "49d3b3e1-841d-423a-9424-c5f7aebdc8f6",
   "metadata": {},
   "source": [
    "# From FASTQ to High-quality SNPs VCF"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "f3fd3f34-15e5-4052-b5a9-ecb48b86f32d",
   "metadata": {},
   "source": [
    "A highly-sacalable SLURM-powered pipeline to evaluate, filter and map Illumina short reads, perform a standard BCFtools Variant Calling and extract high-quality SNPs."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "8829e5bc-9656-48f9-a97d-e53f816ba414",
   "metadata": {},
   "source": [
    "## Usage:"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "fcdcbd44-96ad-435c-b7b6-3adfd3035014",
   "metadata": {},
   "source": [
    "```\n",
    "bash tlacuilo_v0.sh \\\n",
    "    thr=<INT> \\\n",
    "    mem=<INT>G \\\n",
    "    array=1-<INT>%<INT> \\\n",
    "    workdir=<STRING> \\\n",
    "    prefix=<STRING> \\\n",
    "    input=<STRING> \\\n",
    "    samples=<STRING> \\\n",
    "    ref=<STRING> \\\n",
    "    qual=<INT> \\\n",
    "    depth=<INT>\n",
    "```"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "6bba1761-d209-4813-a41b-42f3bb453fc6",
   "metadata": {},
   "source": [
    "## Description of the arguments: (All of them are required)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "cf8904e6-c239-4a05-9e33-10db2c07386b",
   "metadata": {},
   "source": [
    "- `thr` Number of threads to be used per job\n",
    "- `mem` Reserved memory per job \n",
    "- `array` Specifications for the array. Use SLURM structure: 1-number_of_jobs%chunk_size. Example: 1-100%10 (100 jobs in chunks of 10 samples)\n",
    "- `workdir` Working directory. The jobs will be placed here. All the paths have to be relative to this location. Do not include a slash. Example: my_folder\n",
    "- `prefix` Name for the output directory. This directory will be created or replaced (if it already exists). Do not include a slash. It will be located inside of `workdir`\n",
    "- `input` Path to the directory containing the read files. Do not include a slash. example: /my_sequences/\n",
    "- `samples` Path to a TSV table containing the sample information. The path must be relative to `workdir`. An example is shown next.\n",
    "- `ref` Path to the FASTA reference. The path must be relative to `workdir`\n",
    "- `qual` Minimum required phred quality to process an alignment\n",
    "- `depth` Minimum required depth to process an SNP. Only selected alignments (those filtered by `qual`) will be considered. "
   ]
  },
  {
   "cell_type": "markdown",
   "id": "aaf7708e-985a-4c91-97a7-acb74e412c68",
   "metadata": {},
   "source": [
    "## The following fields are required in the `samples` input TSV:"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "19d6e0f9-449c-46a3-98b0-77b56ac6a27f",
   "metadata": {},
   "source": [
    "|  |  |  |\n",
    "| --- | --- | --- |\n",
    "| sample_name | path to read 1 | path to read 2 |"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "be45c05d-56d1-4184-b8f4-54466f6c0b69",
   "metadata": {},
   "source": [
    "## `samples` TSV Example:\n",
    "<mark/>NOTE: Do not include a header!<mark/>"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "180c3289-99ee-44ad-9654-99aa1423fd3b",
   "metadata": {},
   "source": [
    "|  |  |  |\n",
    "| --- | --- | --- |\n",
    "| sample_1 | sample_1_directory/sample_1_R1.fq.gz | sample_1_directory/sample_1_R2.fq.gz |\n",
    "| sample_2 | sample_2_directory/sample_2_R1.fq.gz | sample_2_directory/sample_2_R2.fq.gz |\n",
    "| sample_3 | sample_3_directory/sample_3_R1.fq.gz | sample_3_directory/sample_3_R2.fq.gz |\n",
    "| sample_4 | sample_4_directory/sample_4_R1.fq.gz | sample_4_directory/sample_4_R2.fq.gz |"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "3541376b-7671-4ade-8721-3d587c6442f7",
   "metadata": {},
   "source": [
    "## Example:"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "08dfa3ef-9ec7-4ee9-a049-eabe1eb2cef9",
   "metadata": {},
   "source": [
    "```\n",
    "bash tlacuilo_v0.sh \\\n",
    "    thr=40 \\\n",
    "    mem=32G \\\n",
    "    array=1-1000%100 \\\n",
    "    workdir=scratch \\\n",
    "    prefix=my_folder \\\n",
    "    input=my_sequences \\\n",
    "    samples=samples_table.tsv \\\n",
    "    ref=genome.fa \\\n",
    "    qual=30 \\\n",
    "    depth=5\n",
    "```"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "136d3d0d-5f77-457e-bdca-bd7aea26aac5",
   "metadata": {},
   "source": [
    "## Expected stdout to be printed in the terminal:"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "38d3f39d-daaa-4d04-b2c6-e8af4c616737",
   "metadata": {},
   "source": [
    "```\n",
    "#################################################\n",
    "\n",
    "Number of threads to be used per job = 40\n",
    "Reserved memory per job = 32G\n",
    "Specifications for the array = 1-1000%100 (e.g. 1-number_of_jobs%chunk_size)\n",
    "Working directory = scratch\n",
    "Prefix for the output directory = my_folder\n",
    "Path to the directory containing the read files = my_sequences\n",
    "TSV table containing the sample information = sample_table.tsv (e.g. sample \\t read_1_path \\t read_2_path)\n",
    "Path to the FASTA reference = genome.fa\n",
    "Minimum phred quality required to process an alignment= 30\n",
    "Minimum depth required to process a site = 5\n",
    "\n",
    "#################################################\n",
    "\n",
    "\n",
    "\n",
    "#################################################\n",
    "\n",
    "The following directory architecture was created:\n",
    "\n",
    "----scratch/my_folder/\n",
    "      |\n",
    "      |--exegfiles/\n",
    "      |\n",
    "      |--fastq/\n",
    "      |    |--temp/\n",
    "      |    |--qual_raw/\n",
    "      |    |--fastp/\n",
    "      |    \\--qual_trim/\n",
    "      |    \n",
    "      |--bam/\n",
    "      |    |--raw/\n",
    "      |    \\--deduplicated/\n",
    "      |    \n",
    "      \\--vcf/\n",
    "\n",
    "#################################################\n",
    "\n",
    "\n",
    "Submitted batch job 00000000\n",
    "\n",
    "```"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3 (ipykernel)",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.11.8"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
