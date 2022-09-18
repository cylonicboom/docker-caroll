#!/usr/bin env pwsh
#
#


properties {
    $HOST1964 = $env:HOST1964
    $PDDEST = $env:PDDEST
    $MOUSEINJECTORDEST = $env:MOUSEINJECTORDEST
    $ED64HOST = $env:ED64HOST
}

task default -depends root

task root {
    Write-Information "Environment variables:"
    get-childitem env:\ | format-table
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

    $script:pd_make_success = $false
}

task clean-perfectdark -depends "root" -action {
    pushd $env:PD
      make clean
    popd
}
task make-perfectdark -depends "root" -preAction {
    Write-Information "preaction"
    pushd $env:PD
      $script:PDPreCheckSum = Get-FileHash "${script:OUT_ROM}.z64" -Erroraction Continue
      $script:PDARCHIVE = "${out_rom}.$(basename $(cat .git/HEAD | awk '{print $2}')).$(date -u +'%m-%d-%y.%H-%M-%S').z64"
    popd
} -action {
  pushd $env:PD
    # rebuild mkrom every time
    pushd tools/mkrom
      make clean
      make
    popd

    # make perfect-dark and set success
    make -j && Set-Variable -scope script -name pd_make_success -value $true
  popd
} -postAction {
  # copy
  pushd $env:PD
    # TODO: take checksum of perfect-dark after build
    $script:PDPostCheckSum = Get-FileHash "${script:OUT_ROM}.z64" -Erroraction Stop
    $script:PDImageChanged = "$($script:PDPostCheckSum.hash)".Trim() -ne "$($script:PDPreCheckSum.hash)".Trim()
    Write-Information "PDPostCheckSum: $($script:PDPostCheckSum.hash)"
    Write-Information "PDPreCheckSum: $($script:PDPreCheckSum.hash)"
    write-host "pd image changed: $PDImageChanged"
    if (-not $PDPreCheckSum.hash -or ( $pd_make_success -and $PDImageChanged )) {
        cp -v "${OUT_ROM}.z64" $script:PDARCHIVE
    }
  popd
}

task make-mouseinjector -preaction {
    Write-Information "make-mouseinjector: begin"
} -action{
    pushd $env:MOUSEINJECTOR
      make -j
    popd

} -postaction {

} -depends "make-perfectdark", "root"
task clean-mouseinjector -action {
    pushd $env:MOUSEINJECTOR
      make clean
    popd
} -depends "root"

task clean -depends "clean-mouseinjector", "clean-perfectdark"
task build -depends "make-perfectdark", "make-mouseinjector"

