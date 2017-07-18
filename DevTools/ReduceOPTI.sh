#!/bin/bash
shopt -s globstar

cd DevTools
source ./GetMEX.sh
cd ..

rm -f -r -d -- Extern/OPTI/Test\ Problems/
rm -f -r -d -- Extern/OPTI/Solvers/Source/
rm -f -r -d -- Extern/OPTI/Utilities/Source/

rm -f -r -d -- Extern/OPTI/**/*.c
rm -f -r -d -- Extern/OPTI/**/*.cpp
rm -f -r -d -- Extern/OPTI/**/*.h
rm -f -r -d -- Extern/OPTI/**/*.hpp

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/ipopt
rm -f -r -d -- Extern/OPTI/Solvers/ipopt.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_ipopt.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/levmar
rm -f -r -d -- Extern/OPTI/Solvers/levmar.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_levmar.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/bonmin
rm -f -r -d -- Extern/OPTI/Solvers/bonmin.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_bonmin.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/pswarm
rm -f -r -d -- Extern/OPTI/Solvers/pswarm.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_pswarm.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/mumps
rm -f -r -d -- Extern/OPTI/Solvers/mumps.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_mumps.m
rm -f -r -d -- Extern/OPTI/Solvers/zmumpsmex.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_zmumps.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/ooqp
rm -f -r -d -- Extern/OPTI/Solvers/ooqp.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_ooqp.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/csdp
rm -f -r -d -- Extern/OPTI/Solvers/csdp.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_csdp.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/dsdp
rm -f -r -d -- Extern/OPTI/Solvers/dsdp.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_dsdp.m

rm -f -r -d -- Extern/OPTI/Solvers/Documentation\ \+\ Licenses/nomad
rm -f -r -d -- Extern/OPTI/Solvers/nomad.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_nomad.m

rm -f -r -d -- Extern/OPTI/Solvers/mkltrnls.*
rm -f -r -d -- Extern/OPTI/Solvers/opti_mkltrnls.m

rm -f -r -d Extern/OPTI_SCIP
mkdir Extern/OPTI_SCIP
cd Extern/OPTI
find . -name "*scip*" -print | tar -c -f - -T - | ( cd ../OPTI_SCIP; tar -xf -)
rm -f -r -d -- **/*scip*
cd ../..

