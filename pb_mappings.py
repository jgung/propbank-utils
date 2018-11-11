import json
from collections import defaultdict

from pb_process import VnMapping, read_mappings_xml, read_role_mappings_json

ROLESET_KEY = 'rs'
VNCLS_KEY = 'vncls'
ROLES_KEY = 'roles'


def semlink_xml_to_json(xmlpath, outpath):
    mappings = read_mappings_xml(xmlpath)
    vn_mappings_to_json(mappings, outpath)


def vn_mappings_to_json(mappings, outpath):
    mappings_json = {}
    for lemma, vnmappings in mappings.items():
        lemma_mappings = []
        for vnmapping in vnmappings:
            lemma_mapping = {}
            roles = {**vnmapping.rolemap}
            lemma = vnmapping.lemma
            lemma_mapping[ROLESET_KEY] = vnmapping.roleset
            lemma_mapping[VNCLS_KEY] = vnmapping.vncls
            lemma_mapping[ROLES_KEY] = roles
            lemma_mappings.append(lemma_mapping)
        mappings_json[lemma] = lemma_mappings
    with open(outpath, 'w') as jsonmappings:
        json.dump(mappings_json, jsonmappings, sort_keys=True, indent=2)


def read_vn_mappings_from_json(jsonpath):
    with open(jsonpath) as mappings:
        mappings = json.loads(mappings.read())
    rs_mappings = defaultdict(list)
    for lemma, vnmappings in mappings.items():
        for vnmapping in vnmappings:
            rs = vnmapping[ROLESET_KEY]
            vncls = vnmapping[VNCLS_KEY]
            roles = vnmapping[ROLES_KEY]
            rs_mappings[rs].append(VnMapping(lemma, rs, vncls, roles))
    return rs_mappings


def map_arg(target_arg, vnmappings, vncls_mappings):
    for rs, mappings in vnmappings.items():
        for mapping in mappings:
            vncls = mapping.rolemap.get(target_arg)
            if vncls:
                mapped = vncls_mappings.get(vncls)
                if mapped:
                    mapping.rolemap[target_arg] = mapped


def map_arg_json(json_mapping, target_arg, arg_mappings_json, output_json):
    """
    Generate SemLink mappings with grouped VN classes for a specific core PropBank argument (e.g. '2')
    :param json_mapping: original SemLink mappings JSON
    :param target_arg: target core PB argument (e.g. '2')
    :param arg_mappings_json: path to JSON mapping VerbNet roles onto new grouped roles
    :param output_json: path to save resulting SemLink mappings w/ mapped arguments
    :return:
    """
    vnmappings = read_vn_mappings_from_json(json_mapping)
    vncls_mappings = read_role_mappings_json(arg_mappings_json)
    map_arg(target_arg, vnmappings, vncls_mappings)
    vn_mappings_to_json(vnmappings, output_json)
    return vnmappings


if __name__ == '__main__':
    semlink_xml_to_json('data/type_map.xml', 'data/type_map.json')
    map_arg_json('data/type_map.json', '1', 'mappings/ylp2007-a1.json', 'mappings/semlink-ylp2007-a1.json')
    map_arg_json('data/type_map.json', '2', 'mappings/ylp2007-a2.json', 'mappings/semlink-ylp2007-a2.json')
