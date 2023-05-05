# Scripts and examples for GSearch paper
Scripts for analysizing results from the GSearch software: https://github.com/jean-pierreBoth/gsearch

## ANI and AAI calculation
ANI and AAI was calcualted using the ani.rb/aai.rb scripts from the Kostas's lab and orthoani, which can be found in the scripts directory. Two dependencies must be installed to run the scripts:
1. Ruby (>v2.7)
2. [Blast+](https://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/) (>v2.14.0)
3. Java (for orthoani)

We provide a bash script to run search of query genomes against database genomes based on aai.rb/ani.rb script
```bash
### this is a very expensive step and often takes more than several weeks even on a decent computer cluster for running one genome against all GTDB v207 (65,703 genomes). Thus we also provide the top 20 truth from the output of this step (truth_test.txt) in the example directory for testing purposes.

### get GTDB v207 genomes
wget https://data.ace.uq.edu.au/public/gtdb/data/releases/release207/207.0/genomic_files_reps/gtdb_genomes_reps_r207.tar.gz

tar xzvf ./gtdb_genomes_reps_r207.tar.gz


```

## Run GSearch to get gsearch.answers.txt for query genomes against pre-built database
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
### clone this repo
git clone https://github.com/jianshu93/gsearch_analysis.git


### output will be in the current directory
./gsearch -b ./gsearch_analysis/example/test_data/query_dir_nt -r GTDB/nucl/k16_s12000_n128_ef1600_canonical -n 50
```
## Transform results from GSearch output distance to ANI
According to equation:
$$ANI=1+\frac{1}{k}log\frac{2*J}{1+J}$$

where J is Jaccard-like index (e.g. Jp from ProbMinHash or J from SetSketch) and k is k-mer size used in gsearch (default 16 for nt and 7 for amino acid). The fourth column of gsearch.answers.txt can be transformed into ANI by using this following script:

```bash
### reformat
grep -E "*query_id*" ./example/gsearch.answers.txt > new.txt

### the $5 column is distance (1 - Jaccard index), transformation is the aove mentioned equation. Output is query name, subject name and ANI
awk 'BEGIN{FS=OFS="\t"}{print $3,$7,log((1-$5)*2/(1-$5+1))/16+1}' new.txt > ani.txt

```

## Calculate recall based on gsearch.answers.txt and truth found by ani.rb or aai.rb



## References

1. Jianshu Zhao, Jean Pierre Both, Luis M. Rodriguez-R and Konstantinos T. Konstantinidis, 2022. GSearch: Ultra-Fast and Scalable Microbial Genome Search by combining Kmer Hashing with Hierarchical Navigable Small World Graphs. *bioRxiv* 2022:2022.2010.2021.513218. [biorxiv](https://www.biorxiv.org/content/10.1101/2022.10.21.513218v2).