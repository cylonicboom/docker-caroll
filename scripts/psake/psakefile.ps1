#!/usr/bin env pwsh
#
#



properties {
    $HOST1964 = $env:HOST1964
    $PDDEST = $env:PDDEST
    $MOUSEINJECTORDEST = $env:MOUSEINJECTORDEST
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
    make -j
  popd
  # TODO: make
} -postAction {
  # copy
  pushd $env:PD
    # TODO: take checksum of perfect-dark after build
    $script:PDPostCheckSum = Get-FileHash "${script:OUT_ROM}.z64" -Erroraction Stop
    Write-Information "Would copy perfect dark to archive location now..."
    Write-Information "PDPostCheckSum: $($script:PDPostCheckSum.hash)"
    Write-Information "PDPreCheckSum: $($script:PDPreCheckSum.hash)"


    if ( ( test-path "${script:OUT_ROM}.z64" )  -and ( $PDPostCheckSum.Hash -ne $PDPreCheckSum.Hash) ) {
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


task check-sendvars -action {
    assert ( $script:HOST1964 -ne $null ) "HOST1964 is required"
    assert ( $script:PDDEST -ne $null ) "PDDEST is required"
    assert ( $script:MOUSEINJECTORDEST -ne $null ) "MOUSEINJECTORDEST is required"
}
task send-perfectdarkto1964 -preaction {
} -action {
    pushd $env:PD
      if ((test-path $script:PDARCHIVE)){
          Write-Information "sending to $script:HOST1964"
          scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $script:PDARCHIVE "${script:HOST1964}:${script:PDDEST}\\$(basename $script:PDARCHIVE)"
      }
    popd

} -postaction {

} -depends "make-perfectdark", "root", "check-sendvars"

task send-mouseinjectorto1964 -preaction {
    Write-Information "sending to $script:HOST1964"

} -action {
    pushd $env:MOUSEINJECTOR
      scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no Mouse_Injector.dll "${script:HOST1964}:${script:MOUSEINJECTORDEST}"
    popd
} -postaction {

} -depends "make-perfectdark", "root", "check-sendvars"

task 1964 -depends "send-perfectdarkto1964", "send-mouseinjectorto1964"
