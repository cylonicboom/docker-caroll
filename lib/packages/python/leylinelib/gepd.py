#!/usr/bin/env python3

from .core import *

def winpath(p):
    return "Z:\\" + str(p).strip("/").replace("/", "\\")

CFG='''
ROMPath
VideoPlugin GLN64_2020.dll
InputPlugin Mouse_Injector.dll
AudioPlugin AziAudio0.56WIP2.dll
ROMDirectory
''' +\
f"LastROMDirectory {winpath(Path(PD) / 'build'/ ROMID)}\n" +\
f"SaveDirectory {winpath(gepd_save_dir)}\n" +\
f"StateSaveDirectory {winpath(gepd_save_dir)}\n" +\
f"PluginDirectory {winpath(gepd_plugin_dir)}" +\
'''
AutoFullScreen 0
UsingRspPlugin 0
HighFreqTimer 1
BorderlessFullscreen 0
AutoHideCursorWhenActive 1
UseSimplifiedPluginNames 1
OverclockFactor 9
GEFiringRateHack 1
GEDisableHeadRoll 0
PDSpeedHack 1
PDSpeedHackBoost 0
PauseWhenInactive 1
PauseAtMenu 0
ExpertUserMode 0
RomDirectoryListMenu 1
GameListMenu 1
DisplayDetailStatus 0
DisplayProfilerStatus 0
StateSelectorMenu 0
DisplayCriticalMessageWindow 0
DisplayRomList 1
DisplayStatusBar 1
SortRomList 0
RomNameToDisplay 2
UseDefaultSaveDiectory 1
UseDefaultStateSaveDiectory 1
UseDefaultPluginDiectory 1
UseLastRomDiectory 1
ClientWindowWidth 864
ClientWindowHeight 586
1964WindowTOP 251
1964WindowLeft 421
1964WindowIsMaximized 0
RecentRomDirectory0 Empty Rom Folder Slot
RecentRomDirectory1 Empty Rom Folder Slot
RecentRomDirectory2 Empty Rom Folder Slot
RecentRomDirectory3 Empty Rom Folder Slot
RecentRomDirectory4 Empty Rom Folder Slot
RecentRomDirectory5 Empty Rom Folder Slot
RecentRomDirectory6 Empty Rom Folder Slot
RecentRomDirectory7 Empty Rom Folder Slot
RecentGame0 Empty Game Slot
RecentGame1 Empty Game Slot
RecentGame2 Empty Game Slot
RecentGame3 Empty Game Slot
RecentGame4 Empty Game Slot
RecentGame5 Empty Game Slot
RecentGame6 Empty Game Slot
RecentGame7 Empty Game Slot
RomListColumn0Width 244
RomListColumn0Enabled 1
RomListColumn1Width 57
RomListColumn1Enabled 1
RomListColumn2Width 52
RomListColumn2Enabled 1
RomListColumn3Width 488
RomListColumn3Enabled 1
RomListColumn4Width 30
RomListColumn4Enabled 0
RomListColumn5Width 30
RomListColumn5Enabled 0
RomListColumn6Width 30
RomListColumn6Enabled 0
RomListColumn7Width 30
RomListColumn7Enabled 0
'''

def get_gepdcfg():
    return CFG

def check_call(*args, **kwargs):
  logging.debug(f"check_call: {args} {kwargs}")
  return subprocess.check_call(*args, **kwargs)

def new_GepdBundleBom():
  return {
    "tag": os.getenv('DC_BUILD_TAG', 'latest'),
  }

def get_mouseinjector_suffix():
  if os.getenv('SPEEDRUN_BUILD'): return "_Speedrun"
  if os.getenv('PD_DECOMP'): return "_pddecomp"
  return ""


# side effect: places in /app/gepd_archive
# TODO: offload to another installation script
# side effect clobbers and unzips to /app/gepd_target
def make_gepdbundle():
  with tempfile.TemporaryDirectory() as t:
    t = Path(t)

    # unzip GEPD_ZIP into t
    check_call(["unzip", GEPD_ZIP], cwd=t)

    # copy our content - 1964 static
    # for our rsync command we force it back to a string to append an '/'
    check_call(["rsync", "-aizvP", f"{Path(PDSHARE) / '1964'}/", t / "1964"])

    # copy our content - generated cfg
    cfg_file = t / "1964/1964.cfg"
    with open(cfg_file, "w") as f:
      check_call([ f"{PDPYTHON}/new-cfg" ], stdout=f)
    check_call([ "cat" , cfg_file ])

    #  copy our content - Mouse Injector
    mi_src = Path(MOUSEINJECTOR) / f"Mouse_Injector{get_mouseinjector_suffix()}.dll"
    mi_dest = t / f"1964/plugin/Mouse_Injector{get_mouseinjector_suffix()}.dll"
    check_call(["cp", "-rvf", mi_src, mi_dest], cwd=t)
    check_call(["ls", "-lah",  mi_dest], cwd=t)

    # drop bom.json inside 1964 layout
    with open(t / "bom.json", "w") as f:
      print(json.dumps(new_GepdBundleBom(), indent=2), file=f)

    with open(Path(GEPD_ARCHIVE) / DC_BUILD_TAG / "bom.json", "w") as f:
      print(json.dumps(new_GepdBundleBom(), indent=2), file=f)

    check_call( [ "tar", "-cjvf", Path(GEPD_ARCHIVE) / DC_BUILD_TAG / f"gepd.tar.bz2", "-C", t, "." ] )
    check_call( [ "tar", "-xvjf", Path(GEPD_ARCHIVE) / DC_BUILD_TAG / f"gepd.tar.bz2" ], cwd = Path(GEPD_TARGET))
    check_call(["find"], cwd=t)
