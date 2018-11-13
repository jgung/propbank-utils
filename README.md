# PropBank Utilities

This project contains a collection of miscellaneous utilities meant to ease the process of working with PropBank data.

No guarantees are made about the correctness/stability of said utilities (you definitely won't find any unit tests),
most having grown organically out of my own research needs.

## Convert PropBank to CoNLL 2005 (pb2conll.py)
PropBank annotations are often distributed as standoff `.prop` annotations which point to nodes in separately distributed
parse trees. Given that you have access to the TreeBank parse trees and `.prop` standoff annotations, `pb2conll.py` converts
the PropBank annotations into the significantly more manageable CoNLL 2005 format.

To use this script, you'll first need to install the Perl modules necessary to run 'link_tbpb.pl', provided by the official
[CoNLL 2005 Shared Task homepage](http://www.lsi.upc.edu/~srlconll/soft.html#srlconll).
Note, a slightly modified version of this script has been included to facilitate processing sense tags other than PB rolesets.
The process is described in the README file packaged with [srlconll-1.1.tgz](http://www.lsi.upc.edu/~srlconll/srlconll-1.1.tgz).

```
usage: pb2conll.py [-h] --pb PB --tb TB [--script SCRIPT] [--include-inputs]
                   [--o O] [--combined COMBINED] [--filter FILTER] [--all]

Convert PropBank pointer files to the official CoNLL-2005 format.

optional arguments:
  -h, --help           show this help message and exit
  --pb PB              PropBank pointers file
  --tb TB              TreeBank root directory, e.g. treebank_3/parsed/mrg
  --script SCRIPT      link_tbpb.pl official script
  --include-inputs     include input tokens in output (opposite of -noi in
                       original script)
  --o O                (optional) CoNLL output base directory
  --combined COMBINED  (optional) combined output path
  --filter FILTER      (optional) path regex filter, e.g.
                       ".*WSJ/(0[2-9]|1[0-9]|2[01])/.*"
  --all                include all role labels instead of filtering out
                       unexpected ones
```

## Convert SemLink to CoNLL
SemLink is distributed as standoff annotations with an unconventional format for VN and PB annotations. `pb_process.py` provides
utilities for converting SemLink data to a more standard format, mapping standard propositions to VN roles/classes using
SemLink mappings, etc.

To convert [SemLink 1.1](https://verbs.colorado.edu/semlink/) to CoNLL format with the standard train/test/validation split,
use the script `semlink2conll.sh`, which downloads SemLink and calls `pb_process.py` and `pb2conll.py`.

To use this script, you must have already installed Perl modules provided in
[srlconll-1.1.tgz](http://www.lsi.upc.edu/~srlconll/srlconll-1.1.tgz).

```
Download and convert SemLink data to VN roles and PB roles. Requires PTB dataset from https://catalog.ldc.upenn.edu/ldc99t42.

./semlink2conll.sh --ptb path/to/ptb [--roleset [vn|pb|both]] [--senses [vn|pb]] [--brown path/to/brown.props]
        -h --help
        --ptb   Path to treebank_3/parsed/mrg directory of Penn TreeBank -- LDC99T42
        --roleset       (optional) type of roles to output ('pb', 'vn', or 'both'), 'vn' by default
        --senses        (optional) type of senses to output ('pb' or 'vn'), 'vn' by default
        --brown         (optional) path to Brown corpus propositions

```

#### Example usage
Create train/test/validation split w/ PropBank roles and VN senses, skipping any propositions that aren't fully mapped to VerbNet.
```
./semlink2conll.sh --ptb treebank_3/parsed/mrg --roleset pb --senses vn
```

Create train/test/validation split w/ VN roles and VN senses, skipping any propositions that aren't fully mapped to VerbNet.
Perform the same processing on Brown corpus standoff PropBank annotations provided at data/prop.txt.
```
./semlink2conll.sh --ptb treebank_3/parsed/mrg --roleset vn --senses vn --brown data/prop.txt
```