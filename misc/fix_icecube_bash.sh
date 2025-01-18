
# fixes assumptions about sh always being bash 
# fixed problems on (x)ubuntu 18.04
# run in /opt/lscc/iCEcube2.2020.12/synpbase/bin/ once

find . -type f -exec sed -i 's/\/sh/\/bash/g' {} \;
