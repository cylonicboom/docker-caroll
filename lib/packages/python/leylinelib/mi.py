#!/usr/bin/env python3
from .core import *

mi_data = json.load(open(Path(__file__).parent / "mi.json"))

def get_mi_data():
  return mi_data
