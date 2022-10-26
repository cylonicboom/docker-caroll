#!/usr/bin/env python3

import os
import json
import sys
import subprocess
import tempfile
import logging
from datetime import datetime
import json
from pathlib import Path

# logging goes to stdout
# our stdout is intended to be a useful
# artifact
logging.basicConfig(
    level=logging.DEBUG,
    handlers=[logging.StreamHandler(sys.stderr)]
)
from pathlib import Path


# if _HOST is unset, let's assume we're running dockerless
GEPD = os.getenv("GEPD_TARGET_HOST", os.getenv("GEPD_TARGET")).strip()
assert GEPD, 'GEPD_TARGET_HOST is unset'

# if _HOST is unset, let's assume we're running dockerless
PD = os.getenv("PD_HOST", os.getenv('PD'))
assert PD, "PD_HOST or PD must be set"

# everywhere just kind of assumes ntcs-final
ROMID=os.getenv("ROMID", "ntsc-final")

# GEPD save / plugin locations
gepd_save_dir = f"{GEPD}/save"
gepd_plugin_dir = f"{GEPD}/plugin"

PDSHARE = os.getenv("PDSHARE", str(Path(__file__).parents[4] / "share" )).strip()
assert PDSHARE, "PDSHARE is unset"

PDPYTHON = os.getenv("PDPYTHON", str(Path(__file__).parents[4] / "bin")).strip()
assert PDPYTHON, "PDPYTHON is unset"

GEPD_ZIP = os.getenv('GEPD_ZIP', "").strip()
assert GEPD_ZIP, 'GEPD_ZIP is unset'

# assumption: /app/gepd_archive is bind-mounted to host dir where gepd bundles can be placed
GEPD_ARCHIVE = os.getenv('GEPD_ARCHIVE', "").strip()
assert GEPD_ARCHIVE, 'GEPD_ARCHIVE is unset'

# assumption:/app/gepd_target is bind-mounted to host dir of target 1964 installation to be updated
GEPD_TARGET = os.getenv('GEPD_TARGET', "").strip()
assert GEPD_TARGET, 'GEPD_TARGET is unset'

MOUSEINJECTOR = os.getenv("MOUSEINJECTOR", "").strip()
assert MOUSEINJECTOR, 'MOUSEINJECTOR is unset'

DC_BUILD_TAG = os.getenv("DC_BUILD_TAG", datetime.utcnow().isoformat()).strip()
assert DC_BUILD_TAG, 'DC_BUILD_TAG is unset'

DECOMP_BUILD = None
if os.getenv("DECOMP_BUILD"):
    DECOMP_BUILD = os.getenv("DECOMP_BUILD")

CURRENT_BUILD_ARCHIVE = CURRENT_BUILD_ARKHIVE = Path(GEPD_ARCHIVE) / DC_BUILD_TAG
