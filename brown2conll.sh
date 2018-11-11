#!/bin/bash

program_name=$0

function usage()
{
    echo "Download and convert Brown corpus data to VN roles and PB roles."
    echo "Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42 and PropBanked Brown corpus pointers"
    echo ""
    echo "$program_name path/to/ptb path/to/brown.props"
    echo -e "\t-h --help"
    echo -e "\tpath/to/ptb\tPath to treebank_3/parsed/mrg directory of Penn TreeBank -- LDC99T42"
    echo -e "\tpath/to/brown.props\tPath to PropBanked Brown corpus pointers"
}

if [[ -z "$1" ]] || [[ -z "$2" ]] ; then
    usage
    exit 1
fi

output_path=`pwd`
ptb_dir=${1%/}
brown=$2
semlink=semlink1.1

# Download data
checkdownload() {
    if [[ ! -f "$output_path/$1" ]]; then
        wget -O "$output_path/$1" $2
    else
        echo "File $1 already exists, skipping download"
    fi
    tar xf "$output_path/$1" -C "$output_path"
}

checkdownload srlconll-1.1.tgz http://www.lsi.upc.edu/~srlconll/srlconll-1.1.tgz
checkdownload ${semlink}.tar.gz https://verbs.colorado.edu/semlink/versions/${semlink}.tar.gz

python pb_process.py --pb ${brown} --semlink-mappings ${semlink}/vn-pb/type_map.xml --filter-incomplete --vn --vncls \
--sort-columns 0,1,2 --o ${brown}.vn.props
python pb2conll.py --pb ${brown}.vn.props --tb ${ptb_dir} --combined ${brown}.vn.txt --all --include-inputs

python pb_process.py --pb ${brown} --semlink-mappings ${semlink}/vn-pb/type_map.xml --filter-incomplete \
--sort-columns 0,1,2 --o ${brown}.pb.props
python pb2conll.py --pb ${brown}.pb.props --tb ${ptb_dir} --combined ${brown}.pb.txt --all --include-inputs

python pb_process.py --pb ${brown} --semlink-mappings ${semlink}/vn-pb/type_map.xml --filter-incomplete --vncls \
--sort-columns 0,1,2 --o ${brown}.pbvn.props
python pb2conll.py --pb ${brown}.pbvn.props --tb ${ptb_dir} --combined ${brown}.pbvn.txt --all --include-inputs
