#!/bin/bash

PROGRAM_NAME=$0

function usage()
{
    echo "Download and convert SemLink data to VN roles. Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42."
    echo ""
    echo "$PROGRAM_NAME path/to/ptb"
    echo -e "\t-h --help"
    echo -e "\tpath/to/ptb\tPath to treebank_3/parsed/mrg directory of Penn TreeBank (LDC99T42)"
}

if [ -z "$1" ]; then
    usage
    exit 1
fi

OUTPUT_PATH=`pwd`
PTB_DIR=${1%/}

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
checkdownload semlink1.1.tar.gz https://verbs.colorado.edu/semlink/versions/semlink1.1.tar.gz

SCRIPT_PATH="scripts/link_tbpb_vn.pl"

python pb_process.py --pb semlink1.1/vn-pb/vnprop.txt --semlink --sort-columns 4,0,1,2 --o semlink1.1/vnprop.txt
echo "Saving training data to semlink1.1/vn-train.txt"
python pb2conll.py --pb semlink1.1/vnprop.txt --tb $PTB_DIR --o semlink1.1/vnprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined semlink1.1/vn-train.txt --all --include-inputs --script $SCRIPT_PATH
echo "Saving validation data to semlink1.1/vn-valid.txt"
python pb2conll.py --pb semlink1.1/vnprop.txt --tb $PTB_DIR --o semlink1.1/vnprops \
--filter .*WSJ/24/.* --combined semlink1.1/vn-valid.txt --all --include-inputs --script $SCRIPT_PATH
echo "Saving test data to semlink1.1/vn-test.txt"
python pb2conll.py --pb semlink1.1/vnprop.txt --tb $PTB_DIR --o semlink1.1/vnprops \
--filter .*WSJ/23/.* --combined semlink1.1/vn-test.txt --all --include-inputs --script $SCRIPT_PATH
