pushd ../../../../
python3 ./script/test/apppaltest.py -y -nonreboot worklocal/tvmrelay_deploy/arm_build/main.elf > ./applog 2>&1
popd