class UTStatsSA extends Actor;

var UTStatsLite LocalLog;

function PreBeginPlay()
{
    Super.PreBeginPlay();
}

// =============================================================================
// PostBeginPlay ~ Setup UTStatsLite
// =============================================================================

function PostBeginPlay()
{
    local Mutator M;

    // Spawn the statlog class and log standard info
	LocalLog = spawn(Class'UTStatsLite');
	LocalLog.bWorld = False;
	LocalLog.StartLog();
	LocalLog.LogStandardInfo();
	LocalLog.LogServerInfo();
    LocalLog.LogMapParameters();
    for (M = Level.Game.BaseMutator; M != None; M = M.NextMutator)
        LocalLog.AddMutator(M);
    LocalLog.LogMutatorList();
    Level.Game.LogGameParameters(LocalLog);
	Level.Game.LocalLog = LocalLog;
	Level.Game.LocalLogFileName = LocalLog.GetLogFileName();

}

// =============================================================================
// FindMutator function
// =============================================================================

function Mutator FindMutator (string MutName)
{
   local Mutator M;

   M = Level.Game.BaseMutator;

   while (M != None)
   {
       if (InStr(M.class,MutName) != -1)
           return M;
       else
           M = M.NextMutator;
   }

   return M;
}

// =============================================================================
// Defaultproperties
// =============================================================================

defaultproperties
{
	bHidden=True
}
