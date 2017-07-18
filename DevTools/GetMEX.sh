#!/bin/bash
shopt -s globstar

cd ..

rm -f -r -d -- Extern/OPTI/Solvers/*.mexw*
rm -f -r -d -- Extern/OPTI/Utilities/*.mexw*

cp -r ../OptiMex/ ../OptiMexTmp/

mv ../OptiMexTmp/asl.* Extern/OPTI/Utilities/
mv ../OptiMexTmp/coinR.* Extern/OPTI/Utilities/
mv ../OptiMexTmp/coinW.* Extern/OPTI/Utilities/
mv ../OptiMexTmp/mklJac.* Extern/OPTI/Utilities/
mv ../OptiMexTmp/rmathlib.* Extern/OPTI/Utilities/

mv ../OptiMexTmp/* Extern/OPTI/Solvers/

rm -f -r -d ../OptiMexTmp

cp ../ScipMex/* Extern/OPTI/Solvers/

cd DevTools
