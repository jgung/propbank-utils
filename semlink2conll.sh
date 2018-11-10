#!/bin/bash

PROGRAM_NAME=$0

function usage()
{
    echo "Download and convert SemLink data to VN roles and PB roles."
    echo "Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42."
    echo ""
    echo "$PROGRAM_NAME path/to/ptb"
    echo -e "\t-h --help"
    echo -e "\tpath/to/ptb\tPath to treebank_3/parsed/mrg directory of Penn TreeBank -- LDC99T42"
}

if [ -z "$1" ]; then
    usage
    exit 1
fi

OUTPUT_PATH=`pwd`
PTB_DIR=${1%/}
SEMLINK=semlink1.1

# Download data
checkdownload() {
    if [ ! -f "$OUTPUT_PATH/$1" ]; then
        wget -O "$OUTPUT_PATH/$1" $2
    else
        echo "File $1 already exists, skipping download"
    fi
    tar xf "$OUTPUT_PATH/$1" -C "$OUTPUT_PATH"
}

checkdownload srlconll-1.1.tgz http://www.lsi.upc.edu/~srlconll/srlconll-1.1.tgz
checkdownload $SEMLINK.tar.gz https://verbs.colorado.edu/semlink/versions/$SEMLINK.tar.gz

SCRIPT_PATH="scripts/link_tbpb_vn.pl"

python pb_process.py --pb $SEMLINK/vn-pb/vnpbprop.txt --semlink --filter-incomplete --vn --sort-columns 0,1,2 --o $SEMLINK/vnprop.txt

python pb2conll.py --pb $SEMLINK/vnprop.txt --tb $PTB_DIR --o $SEMLINK/vnprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined $SEMLINK/vn-train.txt --all --include-inputs --script $SCRIPT_PATH
python pb2conll.py --pb $SEMLINK/vnprop.txt --tb $PTB_DIR --o $SEMLINK/vnprops \
--filter .*WSJ/24/.* --combined $SEMLINK/vn-valid.txt --all --include-inputs --script $SCRIPT_PATH
python pb2conll.py --pb $SEMLINK/vnprop.txt --tb $PTB_DIR --o $SEMLINK/vnprops \
--filter .*WSJ/23/.* --combined $SEMLINK/vn-test.txt --all --include-inputs --script $SCRIPT_PATH

python pb_process.py --pb $SEMLINK/vn-pb/vnpbprop.txt --semlink --filter-incomplete --sort-columns 0,1,2 --o $SEMLINK/pbprop.txt

python pb2conll.py --pb $SEMLINK/pbprop.txt --tb $PTB_DIR --o $SEMLINK/pbprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined $SEMLINK/pb-train.txt --all --include-inputs --script $SCRIPT_PATH
python pb2conll.py --pb $SEMLINK/pbprop.txt --tb $PTB_DIR --o $SEMLINK/pbprops \
--filter .*WSJ/24/.* --combined $SEMLINK/pb-valid.txt --all --include-inputs --script $SCRIPT_PATH
python pb2conll.py --pb $SEMLINK/pbprop.txt --tb $PTB_DIR --o $SEMLINK/pbprops \
--filter .*WSJ/23/.* --combined $SEMLINK/pb-test.txt --all --include-inputs --script $SCRIPT_PATH
