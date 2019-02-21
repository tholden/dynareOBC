close all 
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[5]
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[6]
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[1] IRFsForceNotAtBoundIndices=[4]
dynareOBC SW03IRFp.mod ShockScale=22.5 DisplayBoundsSolutionProgress MultiThreadBoundsProblem TimeToEscapeBounds=32 SkipFirstSolutions=1 IRFsForceAtBoundIndices=[1] IRFsForceNotAtBoundIndices=[3:4]
