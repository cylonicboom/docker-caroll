#!/usr/bin/env python
import os

GEPD = os.getenv("GEPD_TARGET_HOST", "").strip()
assert GEPD, 'GEPD_TARGET_HOST is unset'

PD = os.getenv("PD_HOST", os.getenv('PD'))
assert PD, "PD_HOST or PD must be set"

ROMID=os.getenv("ROMID", "ntsc-final")

gepd_save_dir = f"{GEPD}/save"
gepd_plugin_dir = f"{GEPD}/plugin"

PDSHARE = os.getenv("PDSHARE", "").strip()
assert PDSHARE, "PDSHARE is unset"

PDPYTHON = os.getenv("PDPYTHON", "").strip()
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

DC_BUILD_TAG = os.getenv("DC_BUILD_TAG", "").strip()
assert DC_BUILD_TAG, 'DC_BUILD_TAG is unset'
