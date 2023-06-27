# Scripts and examples for GSearch paper
Scripts for analysizing results from the GSearch software: https://github.com/jean-pierreBoth/gsearch

Note: you can directly go to step 3 and 4 and skip step 1 and 2 for testing the recall of GSearch using several testing genomes. Step 1 and step 2 is to produce ground truth for your query genomes based on blastn-ANI/blastp-AAI. Step 1 and 2 is very expensive and take days to run on modern clusters.

## 1. ANI and AAI calculation
ANI and AAI was calcualted using the ani.rb/aai.rb scripts from the Kostas's lab, which can be found in the scripts directory. Several dependencies must be installed to run the scripts:
1. Ruby (>v2.7)
2. [Blast+](https://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/) (>v2.14.0, ANI computation is faster using new parallelism model in blastn and blastp)
3. perl
4. GNU parallel, for fasta file processing
5. python

We provide a bash script to run search of query genomes against database genomes based on aai.rb/ani.rb script
```bash
### this is a very expensive step and often takes more than several weeks even on a decent computer cluster for running one genome against all GTDB v207 (65,703 genomes). Thus we also provide the top 20 truth from the output of this step (truth_test.txt) in the example directory for testing purposes.

### first of all, prepare everything needed
git clone https://github.com/jianshu93/gsearch_analysis.git
chmod a+x ./gsearch_analysis/scripts/*
### copy to you user path, use system path as an example
cp ./gsearch_analysis/scripts/* /usr/local/bin/


### get GTDB v207 nt genomes and search/compare use ani.rb
wget https://data.ace.uq.edu.au/public/gtdb/data/releases/release207/207.0/genomic_files_reps/gtdb_genomes_reps_r207.tar.gz
tar xzvf ./gtdb_genomes_reps_r207.tar.gz

### or download all NCBI/RefSeq proakryotic genomes viar the download software

### unzip all genomes, database genomes and query genomes
find ./gtdb_genomes_reps_r207 -name "*.fna.gz" | parallel -j 10 "gunzip {}"
gunzip ./example/test_data/query_dir_nt/*.gz

find ./gtdb_genomes_reps_r207 -name "*.fna" > gtdb_name.txt
./scripts/ANI.multiple.comparison.many.pl -i gtdb_name.txt -n ./example/test_data/query_dir_nt/test01.fasta -m ani -o test01_ANI_search.txt
tail -n +2 test01_ANI_search.txt | sort -k 2 -g -r > test01_ANI_truth.txt


### get GTDB v207 aa genomes and search use aai.rb
wget https://data.ace.uq.edu.au/public/gtdb/data/releases/release207/207.0/genomic_files_reps/gtdb_proteins_aa_reps_r207.tar.gz
tar xzvf gtdb_proteins_aa_reps_r207.tar.gz
find ./gtdb_genomes_aa_reps_r207 -name "*.faa.gz" > gtdb_name_aa.txt
./scripts/ANI.multiple.comparison.many.pl -i gtdb_name_aa.txt -n ./example/test_data/query_dir_aa/test01.faa.gz -m aai -o test01_AAI_search.txt
tail -n +2 test01_AAI_search.txt | sort -k 2 -g -r > test01_AAI_truth.txt
```

## 2. Run GSearch to get gsearch.answers.txt for query genomes against pre-built database
```bash
### get the binary for linux (make sure you have recent Linux installed with GCC, e.g., Ubuntu 18.0.4 or above)
wget https://github.com/jean-pierreBoth/gsearch/releases/download/0.1.1/gsearch-linux-x86-64.zip --no-check-certificate
unzip gsearch-linux-x86-64.zip
chmod a+x ./gsearch

### get database and prepare
wget http://enve-omics.ce.gatech.edu/data/public_gsearch/GTDBv207_v2023.tar.gz
tar xzvf ./GTDBv207_v2023.tar.gz
cd GTDB/nucl/
tar xzvf ./k16_s12000_n128_ef1600.prob.tar.gz
cd ../../

### get gsearch.answers.txt output, it can also be found in example directory
### output will be in the current directory
./gsearch -b ./gsearch_analysis/example/test_data/query_dir_nt -r GTDB/nucl/k16_s12000_n128_ef1600_canonical -n 50
```
## 3. Transform results from GSearch output distance to ANI
According to equation:
$$ANI=1+\frac{1}{k}log\frac{2*J}{1+J}$$

where J is Jaccard-like index (e.g. Jp from ProbMinHash or J from SetSketch) and k is k-mer size used in gsearch (default 16 for nt and 7 for amino acid). The 5th column of gsearch.answers.txt can be transformed into ANI by using this following script:

```bash
### reformat
cd ./gsearch_analysis
grep -E "*query_id*" ./example/gsearch.answers.txt > ./example/new.txt

### the $5 column is distance (1 - Jaccard index), transformation is the above mentioned equation. Output is query name, subject name and ANI
awk 'BEGIN{FS=OFS="\t"}{print $3,$7,log((1-$5)*2/(1-$5+1))/16+1}' ./example/new.txt > ./example/ani.txt

```

## 4. Calculate recall based on gsearch.answers.txt and true ANI hits found by ani.rb or aai.rb
```bash
### prepare files for each query
### test genome 01 top 10 by gsearch
grep -E "*test01.fasta.gz*" ./example/gsearch.answers.txt | grep -E "*query_id*" | awk 'BEGIN{FS=OFS="\t"}{print $7}' | awk 'BEGIN{FS="/"}{print $3}' | head -n 10 > test01.answers.top10.txt
### test genome 02 top 10 by gsearch
grep -E "*test02.fasta.gz*" ./example/gsearch.answers.txt | grep -E "*query_id*" | awk 'BEGIN{FS=OFS="\t"}{print $7}' | awk 'BEGIN{FS="/"}{print $3}' | head -n 10 > test02.answers.top10.txt

### count intersection between neighbors found by GSearch and ground truth for the same query genome, where file_1 and file_2 are best top K target names by GSearch and ground truth respectively.
awk 'NR==FNR{a[$1]=1; next} {if($1 in a)print $0}' ./example/test01.truth.txt ./example/test01.answers.top10.txt | wc -l | awk '{print $1/10}'

```


## References

1. Jianshu Zhao, Jean Pierre Both, Luis M. Rodriguez-R and Konstantinos T. Konstantinidis, 2022. GSearch: Ultra-Fast and Scalable Microbial Genome Search by combining Kmer Hashing with Hierarchical Navigable Small World Graphs. *bioRxiv* 2022:2022.2010.2021.513218. [biorxiv](https://www.biorxiv.org/content/10.1101/2022.10.21.513218v2).