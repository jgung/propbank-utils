#!/bin/bash

PROGRAM_NAME=$0

function usage()
{
    echo "Download and convert Brown corpus data to VN roles and PB roles."
    echo "Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42 and PropBanked Brown corpus pointers"
    echo ""
    echo "$PROGRAM_NAME path/to/ptb path/to/brown.props"
    echo -e "\t-h --help"
    echo -e "\tpath/to/ptb\tPath to treebank_3/parsed/mrg directory of Penn TreeBank -- LDC99T42"
    echo -e "\tpath/to/brown.props\tPath to PropBanked Brown corpus pointers"
}

if [ -z "$1" ] || [ -z "$2"] ; then
    usage
    exit 1
fi

OUTPUT_PATH=`pwd`
PTB_DIR=${1%/}
BROWN=$2
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

python pb_process.py --pb $BROWN --semlink-mappings $SEMLINK/vn-pb/type_map.xml --filter-incomplete --vn --vncls \
--sort-columns 0,1,2 --o $BROWN.vn.props
python pb2conll.py --pb $BROWN.vn.props --tb $PTB_DIR --combined $BROWN.vn.txt --all --include-inputs

python pb_process.py --pb $BROWN --semlink-mappings $SEMLINK/vn-pb/type_map.xml --filter-incomplete \
--sort-columns 0,1,2 --o $BROWN.pb.props
python pb2conll.py --pb $BROWN.pb.props --tb $PTB_DIR --combined $BROWN.pb.txt --all --include-inputs

python pb_process.py --pb $BROWN --semlink-mappings $SEMLINK/vn-pb/type_map.xml --filter-incomplete --vncls \
--sort-columns 0,1,2 --o $BROWN.pbvn.props
python pb2conll.py --pb $BROWN.pbvn.props --tb $PTB_DIR --combined $BROWN.pbvn.txt --all --include-inputs
