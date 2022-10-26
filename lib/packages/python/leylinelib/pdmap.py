#!/usr/bin/env python3

from .core import *

def new_map_link():
  return {
      "type" : "", # function or variable
      "a_name": "", # namechange support not implemented yet
      "b_name": "", # namechange support not implemented yet
      "a_address": "",
      "b_address": "",
    }


def new_a2b_data(a_data):
    addresses = []
    for k,v in a_data['functions'].items():
        i = new_map_link()
        i['type'] = 'function'
        i['a_name'] = v
        i['b_name'] = ''
        i['a_address'] = k
        i['b_address'] = ''
        addresses.append(i)

    for k,v in a_data['variables'].items():
        i = new_map_link()
        i['type'] = 'variable'
        i['a_name'] = v
        i['b_name'] = ''
        i['a_address'] = k
        i['b_address'] = ''
        addresses.append(i)

    return addresses

def new_b2a_data(b_data):
    addresses = []
    for k,v in b_data['functions'].items():
        i = new_map_link()
        i['type'] = 'function'
        i['a_name'] = v
        i['b_name'] = ''
        i['a_address'] = k
        i['b_address'] = ''
        addresses.append(i)

    for k,v in b_data['variables'].items():
        i = new_map_link()
        i['type'] = 'variable'
        i['a_name'] = v
        i['b_name'] = ''
        i['a_address'] = k
        i['b_address'] = ''
        addresses.append(i)

    return addresses


def get_by_src_name(o, name):
  for oo in o:
    if oo['a_name'] == name:
      return oo

def get_a_symbol_name(address:str):
  pass

def get_a_symbol_address(name:str, a):
  try:
    return get_by_src_name(a, name)['a_address']
  except: return None

def get_b_symbol_name(address:str):
  pass

def get_b_symbol_address(name:str, b):
  try:
    # print(f'get b, looking for {name}')
    return get_by_src_name(b, name)['a_address']
  except: return None

# first we create a flat layout
def get_pd_matching_map():
    r = None
    with open(Path(__file__).parents[0] / "pd.json", "r") as B:
        r = json.loads(''.join(B.readlines()))
    return r

def new_pdmap(a_data=None, b_data=None):
    if not a_data:
        a_data = get_pd_matching_map()
    assert b_data, "must provide valid b_data"
    a2b_data = new_a2b_data(a_data)
    b2a_data = new_b2a_data(b_data)
    a2b_data = json.loads(json.dumps(a2b_data))
    for a in a2b_data:
        # TODO: handle name translation
        # print(a['a_name'])
        a["b_name"] = a['a_name']
        if a['a_name'].lower().startswith("g_"):
            logging.debug (a['a_name'])
        a["b_address"] = get_b_symbol_address(a['b_name'], b2a_data)
        a['offset'] = ''
        try:
            a_address = a['a_address']
            a_address_int = int(a_address, 16)
            b_address = a['b_address']
            b_address_int = int(b_address, 16)

            if a_address_int > b_address_int:
                a['offset'] = "-" + hex(a_address_int - b_address_int)
            elif b_address_int > a_address_int:
                a['offset'] = hex(b_address_int - a_address_int)
            else:
                a['offset'] = "0x0"
            a['offset'] = hex(a['offset'])
        except:
            pass


    db = {
        "a" : a_data,
        "b" : b_data,
        "a2b" : a2b_data,
        # "b2a" : b2a_data
    }
    return db
