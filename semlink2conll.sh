#!/bin/bash

program_name=$0

function usage()
{
    echo "Download and convert SemLink data to VN roles and PB roles."
    echo "Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42."
    echo ""
    echo "$program_name --ptb path/to/ptb [--roleset [vn|pb|both]] [--senses [vn|pb]]"
    echo -e "\t-h --help"
    echo -e "\t--ptb\tPath to treebank_3/parsed/mrg directory of Penn TreeBank -- LDC99T42"
    echo -e "\t--roleset\t(optional) type of roles to output ('pb', 'vn', or 'both'), 'vn' by default"
    echo -e "\t--senses\t(optional) type of senses to output ('pb' or 'vn'), 'vn' by default"
}

roleset=vn
senses=vn

while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
    -h|--help)
    usage
    exit
    ;;
    -ptb|--ptb)
    ptb=$2
    shift
    shift
    ;;
    -roleset|--roleset|--roles)
    roleset=$2
    shift
    shift
    ;;
    -senses|--senses)
    senses=$2
    shift
    shift
    ;;
    *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
esac
done


if [[ -z "$ptb" ]]; then
    usage
    exit 1
fi

output_path=`pwd`
ptb_dir=${ptb%/}
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

roles_opt='--vn'
senses_opt='--vncls'
if [[ ${senses} == 'pb' ]]; then
    senses_opt=''
fi
if [[ ${roleset} == 'pb' ]]; then
    roles_opt=''
fi
if [[ ${roleset} == 'both' ]]; then
    roles_opt='--pbvn'
fi
prefix="${senses}.${roleset}"

python pb_process.py --pb ${semlink}/vn-pb/vnpbprop.txt \
--semlink --filter-incomplete \
--sort-columns 0,1,2 \
--o ${semlink}/${prefix}-prop.txt \
${roles_opt} \
${senses_opt}

output_path=${semlink}/${prefix}-prop.txt

python pb2conll.py --pb ${output_path} --tb ${ptb_dir} --o ${semlink}/vnprops \
--filter ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*" --combined ${semlink}/${prefix}-train.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${output_path} --tb ${ptb_dir} --o ${semlink}/vnprops \
--filter .*WSJ/24/.* --combined ${semlink}/${prefix}-valid.txt --all --include-inputs --script ${script_path}
python pb2conll.py --pb ${output_path} --tb ${ptb_dir} --o ${semlink}/vnprops \
--filter .*WSJ/23/.* --combined ${semlink}/${prefix}-test.txt --all --include-inputs --script ${script_path}