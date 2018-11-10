import argparse
import re
from collections import Counter, defaultdict
from xml.dom import minidom

import sys

SENTENCE_FIELD = 1
TOKEN_FIELD = 2
SENSE_FIELD = 4
ROLE_START = 6

PB_CORE_ARGS = "-ARG[^M]|\d-\s| -by"  # filter out props with core PB args, missing args, or typos
SEMLINK_PB_TO_VN = "^((?:\S+\s+){4})(\S+?)\.[^;]+;VN=(\S+)"
SEMLINK_PB_TO_VN_REPL = r"\1\2.\3"

ROLE = "^\S+:\d+-(\S+)$"
CLEAN_ROLE = "^(ARGM-[a-zA-Z0-9]+|[a-zA-Z0-9]+).*$"


def write_counts(outpath, counts):
    total = sum(counts.values())
    sorted_counts = sorted([(k, v) for k, v in counts.items()], key=lambda x: x[1], reverse=True)
    with open(outpath, mode='wt') as out:
        out.write(str(total) + '\n')
        for k, v in sorted_counts:
            out.write('{}\t{}\n'.format(k, v))


class PropStats(object):
    def __init__(self, props):
        super(PropStats, self).__init__()
        self.props = [prop.split() for prop in props]
        self.lemmas = Counter()
        self.predicates = Counter()
        self.roles = Counter()
        self.senses = Counter()
        self._count()

    def _count(self):
        for prop in self.props:
            predicate = prop[SENSE_FIELD]
            separator_index = predicate.index(".")
            lemma, sense = predicate[:separator_index], predicate[separator_index + 1:]
            self.lemmas[lemma] += 1
            self.predicates[predicate] += 1
            self.senses[sense] += 1
            for role in prop[ROLE_START:]:
                role = re.sub(ROLE, r"\1", role)
                self.roles[role] += 1

    def write_all(self, outpath):
        write_counts(outpath + '.lemmas.txt', self.lemmas)
        write_counts(outpath + '.preds.txt', self.predicates)
        write_counts(outpath + '.roles.txt', self.roles)
        write_counts(outpath + '.senses.txt', self.senses)


class VnMapping(object):
    def __init__(self, lemma, roleset, vncls, rolemap):
        super(VnMapping, self).__init__()
        self.lemma = lemma
        self.roleset = roleset
        self.vncls = vncls
        self.rolemap = rolemap


def read_mappings_xml(mappings_xml):
    """
    Generate a mapping dictionary from rolesets to lists of VnMapping objects.
    :param mappings_xml: pb-vn mappings XML file
    :return: mapping dict
    """
    lemma_map = {}
    roleset_map = defaultdict(list)
    for predicate in minidom.parse(mappings_xml).getElementsByTagName("predicate"):
        lemma = predicate.attributes['lemma'].value
        if lemma in lemma_map:
            raise ValueError('Repeat lemma found in mappings file {}: {}'.format(mappings_xml, lemma))
        roles = defaultdict(list)
        lemma_map[lemma] = roles

        for argmap in predicate.getElementsByTagName("argmap"):
            roleset = argmap.attributes['pb-roleset'].value
            vncls = argmap.attributes['vn-class'].value
            rolemap = {}
            mapping = VnMapping(lemma, roleset, vncls, rolemap)

            roles[roleset].append(mapping)
            roleset_map[roleset].append(mapping)

            for role in argmap.getElementsByTagName("role"):
                pbarg = role.attributes['pb-arg'].value
                vntheta = role.attributes['vn-theta'].value
                if pbarg in rolemap:
                    raise ValueError('Non deterministic mapping for {} arg {}'.format(lemma, pbarg))
                rolemap[pbarg] = vntheta
    return roleset_map


def clean_roles(roles):
    result = []
    for role in roles:
        if not role.strip():
            result.append(role)
            continue
        role_search = re.search(ROLE, role, re.IGNORECASE)
        if not role_search:
            print('Unexpected role format: %s' % role)
            result.append(role)
            return None
        role_part = role_search.group(1)
        cleaned = re.sub(CLEAN_ROLE, r"\1", role_part)
        if cleaned == "announcement":  # erroneous mapping in Semlink 1.0/1.1
            return "Topic"
        if cleaned.startswith("ARGM-"):
            if cleaned == "ARGM-TM":
                cleaned = "ARGM-TMP"
            if len(cleaned) != 8:
                print('Unexpected ARGM-* role: %s' % cleaned)
                return None
        result.append(role.replace(role_part, cleaned))
    return result


def filter_props(props, filter_pattern):
    pattern = re.compile(filter_pattern)
    result = []
    for prop in props:
        if bool(pattern.search(prop)):
            continue
        result.append(prop)
    return result


def map_props(props, search_pattern, search_repl_pattern):
    result = []
    for prop in props:
        result.append(re.sub(search_pattern, search_repl_pattern, prop))
    return result


def transform_props(propspath, outpath=None, filter_pattern=None, search_pattern=None, search_repl_pattern=None,
                    sort_cols=None):
    if not outpath:
        outpath = propspath + '.out'

    original = []
    with open(propspath) as props:
        for prop in props:
            if prop:
                fields = re.split(r'(\s+)', prop)  # preserve whitespace
                roles = clean_roles(fields[ROLE_START * 2:])
                if not roles:  # formatting error
                    continue
                original.append(fields[:ROLE_START * 2] + roles)
    if sort_cols:
        original = sorted(original,
                          key=lambda x: tuple(int(x[col * 2]) if col == SENTENCE_FIELD or col == TOKEN_FIELD else x[col * 2]
                                              for col in sort_cols))
    result = [''.join(prop) for prop in original]
    if filter_pattern:
        result = filter_props(result, filter_pattern=filter_pattern)
    if search_pattern and search_repl_pattern:
        result = map_props(result, search_pattern=search_pattern, search_repl_pattern=search_repl_pattern)
    print('Processed %d props, removed %d (%d remaining)' % (len(original), len(original) - len(result), len(result)))

    prop_stats = PropStats(result)
    prop_stats.write_all(outpath)

    with open(outpath, mode='wt') as out:
        out.writelines(result)
    return result


def options():
    parser = argparse.ArgumentParser(description="Utility for sorting, filtering, and transforming PropBank pointers.")
    parser.add_argument('--pb', type=str, required=True, help='PropBank pointers file')
    parser.add_argument('--o', type=str, help='(optional) output path')
    parser.add_argument('--filter', type=str, help='(optional) pointer regex filter, e.g. "-ARG[^M]" removes any pointers '
                                                   'containing core PB arguments')
    parser.add_argument('--search', type=str, help='(optional) pointer regex search for mapping')
    parser.add_argument('--replace', type=str, help='(optional) pointer replacement regex for mapping')
    parser.add_argument('--sort-columns', default="0,1,2", dest='sort_cols', type=str,
                        help='(optional) comma-separated column indices in props to sort by (e.g. "4,0,1" to sort first by '
                             'sense, then by path and sentence)')
    parser.add_argument('--semlink', action='store_true',
                        help='use default settings for processing SemLink data (remove pointers '
                             'with PropBank core arguments, change senses to VN)')
    parser.set_defaults(semlink=False)

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    return parser.parse_args()


def main():
    _opts = options()
    filter_pattern = _opts.filter
    search_pattern = _opts.search
    replace_pattern = _opts.replace
    if _opts.semlink:
        if not filter_pattern:
            filter_pattern = PB_CORE_ARGS
        if not search_pattern:
            search_pattern = SEMLINK_PB_TO_VN
        if not replace_pattern:
            replace_pattern = SEMLINK_PB_TO_VN_REPL
    sort_cols = [int(col) for col in _opts.sort_cols.split(',')]
    transform_props(_opts.pb, outpath=_opts.o, filter_pattern=filter_pattern, search_pattern=search_pattern,
                    search_repl_pattern=replace_pattern, sort_cols=sort_cols)


if __name__ == '__main__':
    main()
