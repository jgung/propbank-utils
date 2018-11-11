#!/bin/bash

program_name=$0

function usage()
{
    echo "Download and convert SemLink data to VN roles and PB roles."
    echo "Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42."
    echo ""
    echo "$program_name path/to/ptb"
    echo -e "\t-h --help"
    echo -e "\tpath/to/ptb\tPath to treebank_3/parsed/mrg directory of Penn TreeBank -- LDC99T42"
}

if [[ -z "$1" ]]; then
    usage
    exit 1
fi

output_path=`pwd`
ptb_dir=${1%/}
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

script_path="scripts/link_tbpb_vn.pl"

echo "Creating train/valid/test split with VN roles and VN senses"
python pb_process.py --pb ${semlink}/vn-pb/vnpbprop.txt --semlink --filter-incomplete --vn --vncls --sort-columns 0,1,2 --o ${semlink}/vnprop.txt

python pb2conll.py --pb ${semlink}/vnprop.txt --tb ${ptb_dir} --o ${semlink}/vnprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined ${semlink}/vn-train.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${semlink}/vnprop.txt --tb ${ptb_dir} --o ${semlink}/vnprops \
--filter .*WSJ/24/.* --combined ${semlink}/vn-valid.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${semlink}/vnprop.txt --tb ${ptb_dir} --o ${semlink}/vnprops \
--filter .*WSJ/23/.* --combined ${semlink}/vn-test.txt --all --include-inputs --script ${script_path}

echo "Creating train/valid/test split with PB roles"
python pb_process.py --pb ${semlink}/vn-pb/vnpbprop.txt --semlink --filter-incomplete --sort-columns 0,1,2 --o ${semlink}/pbprop.txt

python pb2conll.py --pb ${semlink}/pbprop.txt --tb ${ptb_dir} --o ${semlink}/pbprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined ${semlink}/pb-train.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${semlink}/pbprop.txt --tb ${ptb_dir} --o ${semlink}/pbprops \
--filter .*WSJ/24/.* --combined ${semlink}/pb-valid.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${semlink}/pbprop.txt --tb ${ptb_dir} --o ${semlink}/pbprops \
--filter .*WSJ/23/.* --combined ${semlink}/pb-test.txt --all --include-inputs --script ${script_path}

echo "Creating train/valid/test split with PB roles and VN senses"
python pb_process.py --pb ${semlink}/vn-pb/vnpbprop.txt --semlink --filter-incomplete --vncls --sort-columns 0,1,2 --o ${semlink}/pbvnprop.txt

python pb2conll.py --pb ${semlink}/pbvnprop.txt --tb ${ptb_dir} --o ${semlink}/pbprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined ${semlink}/pbvn-train.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${semlink}/pbvnprop.txt --tb ${ptb_dir} --o ${semlink}/pbprops \
--filter .*WSJ/24/.* --combined ${semlink}/pbvn-valid.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${semlink}/pbvnprop.txt --tb ${ptb_dir} --o ${semlink}/pbprops \
--filter .*WSJ/23/.* --combined ${semlink}/pbvn-test.txt --all --include-inputs --script ${script_path}