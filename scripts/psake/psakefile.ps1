#!/usr/bin env pwsh
#


<#
The purpose of this file is to automate/define a "happy path"
for building Perfect Dark decomp, the Mouse Injector,
and/or making a new 1964GEPD bundle.


This script requires psake/powershell to run.
Target os: Ubuntu LTS OCI-compatible container
#>
properties {
    $HOST1964 = $env:HOST1964
    $PDDEST = $env:PDDEST
    $MOUSEINJECTORDEST = $env:MOUSEINJECTORDEST
    $ED64HOST = $env:ED64HOST
}

task default -depends root

<#
Setting default script varibles. This is done before any other target.
#>
task root {
    $script:HOST1964 = $HOST1964
    $script:PDDEST = $PDDEST
    $script:MOUSEINJECTORDEST = $MOUSEINJECTORDEST

    # storage variables for pd rom filehash
    $script:PDPreCheckSum = $null
    $script:PDPostCheckSum = $null

    # path:  output location for pd rom after make
    $script:OUT_ROM="build/${env:ROMID}/pd"
    # path: copy of rom file w/ branch and timestamp in filename
    $script:PDARCHIVE=$null
    Write-Information "My target hostname is $script:HOST1964"
    $script:ED64HOST = $ED64HOST

}

<#
Perfect Dark build steps

Environment variables are passed through make to force override.
#>
task clean-perfectdark -depends "root" -action {
    $env:task_clean_perfectdark = "fail"
    pushd $env:PD
      make allclean
      rm -rf build/$env:ROMID
      make extract
    popd
    $env:task_clean_perfectdark = "pass"
}
task make-perfectdark -depends "root" -preAction {
    $env:task_make_perfectdark = "fail"
    Write-Information "make-perfectdark: preaction"
    pushd $env:PD
      $script:PDPreCheckSum = ""
      try {
        $script:PDPreCheckSum = Get-FileHash "${script:OUT_ROM}.z64"
      } catch {}

      if (test-path build/$env:ROMID){
        pushd build/$env:ROMID
          rm pd.z64
          if ( Test-Path pd.z64 )
          {
              write-error "pd.z64 exists before build!"
          }
        popd
      }
    popd
} -action {
  Write-Information "make-perfectdark: action"
  pushd $env:PD
    # rebuild mkrom every time
    pushd tools/mkrom
      make clean
      make
    popd

    # TODO: fix this so it can be set in upper layer and forgotten about in the lower
    $make_envs = "$(gci env:/ | ?{$_.key -notlike "*path*"} | ?{$_.key -notlike "CC"}  | %{"$($_.key)=$($_.value)"})" -replace [Environment]::NewLine," "
    Write-Information "PD make envs: $make_envs"
    $make_cmd = "make -j $($make_envs)"
    Write-Information "PD make command: $($make_cmd)"
    # make perfect-dark
    Invoke-Expression $make_cmd -erroraction stop || write-error "make-perfectdark failed"
  popd
} -postaction {

    ls $env:PD/build/$env:ROMID/pd.z64 || write-error "pd.z64 does not exist after build!"
    $env:task_make_perfectdark = "pass"
}

task archive-perfectdark -depends "make-xdeltapatch" -preaction {
    $env:task_archive_perfectdark = "fail"
    pushd $env:PD
      $env:DC_BUILD_TAG = "$(date -u +'%Y-%m-%d.%H-%M-%S')-$($out_rom -replace 'build/','' -replace '/','.').$(basename $(cat .git/HEAD | awk '{print $2}'))"
      # TODO: fix usage of PDARCHIVE
      $script:PDARCHIVE = "$($env:GEPD_ARCHIVE)/$($env:DC_BUILD_TAG)/pd.z64"
      mkdir -p $(dirname $script:PDARCHIVE )
    popd
} -action {
  # copy
  pushd $env:PD
    $script:PDPostCheckSum = Get-FileHash "${script:OUT_ROM}.z64" -Erroraction Stop
    $script:PDImageChanged = "$($script:PDPostCheckSum.hash)".Trim() -ne "$($script:PDPreCheckSum.hash)".Trim()
    Write-Information "PDPostCheckSum: $($script:PDPostCheckSum.hash)"
    Write-Information "PDPreCheckSum: $($script:PDPreCheckSum.hash)"
    write-Information "pd image changed: $PDImageChanged"

    pushd build/$env:ROMID
      Write-Information "Creating pd.json"
      rm pd.json
      (pd-parsemap pd.map | jq | tee pd.json > /dev/null) && ls pd.json || write-error "Failed to recreate pd.json"
      cp -v pd.json $env:GEPD_ARCHIVE/$env:DC_BUILD_TAG || write-error "Failed to archive pd.json"
      mv -v pd.z64 $env:GEPD_ARCHIVE/$env:DC_BUILD_TAG/pd.z64 || write-error "Failed to move rom"
      mv -v pd.xdelta $env:GEPD_ARCHIVE/$env:DC_BUILD_TAG/pd.xdelta || write-error "Failed to move xdelta"
      ln -s $env:GEPD_ARCHIVE_HOST/$env:DC_BUILD_TAG/pd.z64 pd.z64 || write-error "Failed to setup symlink"

      pushd $env:GEPD_ARCHIVE/$env:DC_BUILD_TAG
        /app/python/new-pdmap pd.json > leyline.json
      popd

      # write-Information "archiving pd rom"
    popd
  popd
  $env:task_archive_perfectdark = "pass"
}

task make-xdeltapatch -depends "make-perfectdark"  -action {
  $env:task_make_xdeltapatch = "fail"
    pushd $env:PD
      xdelta delta -9 pd.$env:ROMID.z64 build/$env:ROMID/pd.z64 build/$env:ROMID/pd.xdelta
      test-path build/$env:ROMID/pd.xdelta || Write-error "Failed to create xdelta"
    popd
  $env:task_make_xdeltapatch = "pass"
}

<#
Mouse Injector build steps
#>
task make-mouseinjector -preaction {
    $env:task_make_mouseinjector = "fail"
    Write-Information "make-mouseinjector: begin"
} -action{
    pushd $env:MOUSEINJECTOR
      make -j || write-error "make-mouseinjector failed!"
    popd
    $env:task_make_mouseinjector = "pass"
} -postaction {
} -depends  "root"
task clean-mouseinjector -action {
    $env:task_clean_mouseinjector = "fail"
    pushd $env:MOUSEINJECTOR
      make clean
      mkdir -p obj
    popd
    $env:task_clean_mouseinjector = "pass"
} -depends "root"

task make-dynamicmouseinjector -preaction {
    $env:task_make_mouseinjector = "fail"
    Write-Information "make-mouseinjector: begin"
    pushd $env:MOUSEINJECTOR/games
      rm perfectdark.generated.h -f
      /app/python/mk-pdheader > perfectdark.generated.h
    popd
} -action{
    pushd $env:MOUSEINJECTOR
      make -j || write-error "make-mouseinjector failed!"
    popd
    $env:task_make_mouseinjector = "pass"
} -postaction {
} -depends  "root"

<#
Make a new GEPD bundle.
Depends on: make-mouseinjector
#>
task make-gepdbundle -depends "mouseinjector", "root" -action {
    $env:task_make_gepdbundle = "fail"
    if ( [string]::IsNullOrEmpty("$($env:GEPD_TARGET)".trim()) ) {
        write-error "GEPD_TARGET must be set"
    }
    rm -rf $env:GEPD_TARGET/*
    pushd /app/python
      ./mk-gepd || write-error "mk-gepd failed"
    popd
    $env:task_make_gepdbundle = "pass"
}

task clean -depends "clean-mouseinjector", "clean-perfectdark"
task mouseinjector -depends "clean-mouseinjector", "make-mouseinjector"
task pd -depends "clean-perfectdark", "make-perfectdark", "make-xdeltapatch"
task pda -depends "pd", "archive-perfectdark"
task bundle -depends "pda", "make-gepdbundle"
