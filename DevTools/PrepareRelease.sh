cd ..

git submodule foreach git checkout master
git pull --recurse-submodules
git submodule foreach git pull --recurse-submodules
git submodule foreach git fetch upstream --recurse-submodules
cd Extern/YALMIP
git checkout develop
git merge upstream/develop
git push
git checkout master
git merge develop
git push
cd ../..
git submodule foreach git merge upstream/master
git submodule foreach git push

git add .
git commit -m "update submodules"
git push

rm -f -r -d -- ../dynareOBCRelease/
mkdir ../dynareOBCRelease
cp -f -r . ../dynareOBCRelease/
cd ../dynareOBCRelease

rm -f *.mex*
rm -f Core/*.mex*

rm Examples/FernandezVillaverdeEtAl2012/*.m
rm Examples/FernandezVillaverdeEtAl2012/*.mat
rm Examples/SmetsWouters*/*.m
rm Examples/SmetsWouters*/*.mat

shopt -s globstar

rm -f -r -d -- **/.git*

rm -f -r -d -- **/*.asv
rm -f -r -d -- **/*.bak
rm -f -r -d -- **/*.log
rm -f -r -d -- **/*.db
rm -f -r -d -- **/*.ini
rm -f -r -d -- **/*.zip
rm -f -r -d -- **/*.eps
rm -f -r -d -- **/*.jnl
rm -f -r -d -- **/*.orig

rm -f -r -d -- **/dynareOBCTemp*
rm -f -r -d -- **/*deleteThis*
rm -f -r -d -- **/~*
rm -f -r -d -- **/outcmaes*.*
rm -f -r -d -- **/*_static.m
rm -f -r -d -- **/*_dynamic.m
rm -f -r -d -- **/*_steadystate2.m
rm -f -r -d -- **/*_set_auxiliary_variables.m
rm -f -r -d -- **/ValueStore.mat
rm -f -r -d -- **/ESTNLSSTempEstimationObjective.m
rm -f -r -d -- **/ESTNLSSTempEstimationObjectiveMex.mex*
rm -f -r -d -- **/ESTNLSSTempKalmanStep.m

rm -f -r -d -- DevTools/
rm -f -r -d -- Extern/tbxmanager/
rm -f -r -d -- Extern/requirements/
rm -f -r -d -- Extern/OptiToolbox216/
rm -f -r -d -- Extern/OptiToolbox221/

rm -f -r -d -- **/codegen/
rm -f -r -d -- **/Output/

rm -f -r -d -- Tests/ComparisonOfPerfectForesightSolutionsForLinearModels/OccBinVersionBound*/
rm -f -r -d -- Tests/ComparisonOfPerfectForesightSolutionsForLinearModels/OccBinVersionSteady*/
rm -f -r -d -- Tests/ComparisonOfPerfectForesightSolutionsForLinearModels/ExtendedPathVersion*/
rm -f -r -d -- Tests/ComparisonOfPerfectForesightSolutionsForLinearModels/*.mat

rm -f -r -d -- **/.DS_Store
rm -f -r -d -- **/.git
rm -f -r -d -- **/dynareOBCGlobalResume.mat
rm -f -r -d -- **/variablescmaes.mat
rm -f -r -d -- **/VariablesACD.mat
rm -f -r -d -- **/CurrentVersionURL.txt
rm -f -r -d -- **/LastDependencyUpdate.mat
rm -f -r -d -- **/FastStart.mat
rm -f -r -d -- **/pou.mat
rm -f -r -d -- **/time.mat
rm -f -r -d -- **/checksum

./DevTools/ReduceOPTI.sh

find . -empty -type d -delete

echo -n "https://github.com/tholden/dynareOBC/releases/download/vX.XX.TODO/dynareOBCRelease.zip" > CurrentVersionURL.txt
echo Now update CurrentVersionURL.txt
