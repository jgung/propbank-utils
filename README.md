# PropBank Utilities

This project contains a collection of miscellaneous utilities meant to ease the process of working with PropBank data.

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