class UTStatsLite extends StatLogFile;

var bool bAceInstalled;
var bool bFirstBlood;
var bool bGameStarted;

var string zzComboCode[4];
var string zzBuffer;
var string zzVersion;
var string zzMutatorList;

var float zzEndTime;
var float zzWarmupTime;

var int CurrentID;
var UTSAceHandler AceHandler;

struct PlayerStruct
{
   var Pawn zzPawn;
   var int zzID,zzSpree,zzCombo,zzKills,zzDeaths,zzSuicides,zzTeamKills;
   var float zzLastKill, zzEndTime, zzJoinTime;
   var bool bHasFlag;
   var string zzPlayerName,zzLogin,zzIP,zzHWID,zzMAC1,zzMAC2;
};

var PlayerStruct PlayerInfo[33];

function Timer()
{
  local int i;

  super.Timer();  

  for (i=0;i<ArrayCount(PlayerInfo);++i)
  {
    if (PlayerInfo[i].zzPawn == none)
      continue;

    if (PlayerInfo[i].zzPawn.IsA('Spectator'))
      continue;
    
    if (PlayerPawn(PlayerInfo[i].zzPawn) == none)
      continue;
    
    if (PlayerInfo[i].zzHWID == "")
    {
      log("[UTStatsLite]: Player"@PlayerInfo[i].zzID$" missing HWID/MACs");
      LogACEInfo(PlayerInfo[i]);
    }
    else
      continue;
  }
}

// =============================================================================
// Pregame functions
// =============================================================================

function LogStandardInfo()
{
    local UTStatsHTTPClient UTSHTTP;
    local int i;
    local string zzServerActors;
    local mutator zzMutator;

    // Setup the buffer
    zzBuffer = "";

    // Setup the PlayerInfo structs
    for (i=0;i<32;++i)
        PlayerInfo[i].zzID = -1;

    // Setup the zzCombo array
    zzComboCode[0] = "spree_dbl";
    zzComboCode[1] = "spree_mult";
    zzComboCode[2] = "spree_ult";
    zzComboCode[3] = "spree_mon";

    // Check the serveractors list
    zzServerActors = Level.ConsoleCommand("get Engine.GameEngine ServerActors");

    if (InStr(CAPS(zzServerActors),"ACE") != -1)
        bAceInstalled = true;

    Log("### -----------------------------------");
    Log("### --   UTStatsLite is running    --");
    Log("### -----------------------------------");
    Log("###");
    Log("### - Version      : "$zzVersion);
    Log("### - ACE Installed :"@bAceInstalled);
    Log("###");
    Log("### -----------------------------------");

    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Log_Standard"$Chr(9)$"UTStatsLite");
    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Log_Version"$Chr(9)$zzVersion);
    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Game_Name"$Chr(9)$GameName);
    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Game_Version"$Chr(9)$Level.EngineVersion);
    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Absolute_Time"$Chr(9)$GetAbsoluteTime());
    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Server_IP"$Chr(9)$Level.Game.GetNetworkNumber());
    LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Server_Port"$Chr(9)$Level.Game.GetServerPort());
    if (bWorld)
    {
        if( Level.ConsoleCommand("get UdpServerUplink douplink") ~= string(true) )
            LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Server_Public"$Chr(9)$"1");
        else
            LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"Server_Public"$Chr(9)$"0");
    }

   LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"AceInstalled"$Chr(9)$string(bAceInstalled));

   // Check for InstaGib
  foreach AllActors(class'Mutator',zzMutator)
   {
       if ((Arena(zzMutator) != none && ClassIsChildOf(Arena(zzMutator).DefaultWeapon, class'SuperShockRifle')))
           LogEventString(GetTimeStamp()$Chr(9)$"game"$Chr(9)$"insta"$chr(9)$"True");
   }

   AceHandler = Spawn(class'UTSAceHandler');

   UTSHTTP = Spawn(class'UTStatsHTTPClient');

   //UTSHTTP.Browse("212.42.16.16","/myip.php",80,10);
   LogIP(IPOnly(UTSHTTP.GetIP()));
   UTSHTTP.Destroy();
}

function LogIP (string zzMyIP)
{
   LogEventString(GetTimeStamp()$Chr(9)$"info"$Chr(9)$"True_Server_IP"$Chr(9)$zzMyIP);
}

function StartLog()
{
	Super.StartLog();

  SetEncoding();

	OpenLog();
}

// =============================================================================
// LogPlayerInfo ~ Called right after a player connects
// =============================================================================

function LogPlayerInfo(Pawn Player)
{
  local int i;
  local bool found;

  Super.LogPlayerInfo(Player);

  If (Player.IsA('Spectator'))
    return;

  // Check if this player has already been logged
  for (i = 0; i < ArrayCount(PlayerInfo); ++i)
  {
        if (PlayerInfo[i].zzPlayerName == Player.PlayerReplicationInfo.PlayerName)
        {
            found = true;
            break;
        }
  }

  if (!found)
  {
      for (i = 0; i < 4; ++i)
      {
          if (PlayerInfo[i].zzID == -1) // This slot is free
              break;
      }
  }
  
  // If no free slot is found and player is not already logged, log an error or handle appropriately
  if (i == ArrayCount(PlayerInfo) && !found)
  {
      Log("No free slots available in PlayerInfo array for new player.");
      return;
  }

   PlayerInfo[i].zzID = Player.PlayerReplicationInfo.PlayerID;
   PlayerInfo[i].zzPawn = Player;
   PlayerInfo[i].zzSpree = 0;
   PlayerInfo[i].zzCombo = 1;
   PlayerInfo[i].zzKills = 0;
   PlayerInfo[i].zzDeaths = 0;
   PlayerInfo[i].zzSuicides = 0;
   PlayerInfo[i].zzTeamKills = 0;
   PlayerInfo[i].zzLastKill = 0.0;
   PlayerInfo[i].zzEndTime = 0.0;
   PlayerInfo[i].zzJoinTime = Level.TimeSeconds;
   PlayerInfo[i].bHasFlag = false;

}

// =============================================================================
// LogKill ~ Called for each killevent
// =============================================================================

function LogKill( int KillerID, int VictimID, string KillerWeaponName, string VictimWeaponName, name DamageType )
{
    local int zzKillerID,zzVictimID;

    if (!bGameStarted && !GameStarted())
      return;

    zzKillerID = GetID(KillerID);
    zzVictimID = GetID(VictimID);

    LogEventString(GetTimeStamp()$Chr(9)$"kill"$Chr(9)$KillerID$Chr(9)$KillerWeaponName$Chr(9)$VictimID$Chr(9)$VictimWeaponName$Chr(9)$DamageType);

    PlayerInfo[zzKillerID].zzKills++;
    PlayerInfo[zzVictimID].zzDeaths++;

    if (!bFirstBlood)
    {
      LogEventString(GetTimeStamp()$chr(9)$"first_blood"$chr(9)$KillerID);
      bFirstBlood = true;
    }

    LogSpree(zzKillerID,zzVictimID);
    LogCombo(zzKillerID);

    if (PlayerInfo[zzVictimID].bHasFlag)
    {
      LogEventString(GetTimeStamp()$chr(9)$"flag_kill"$chr(9)$KillerID);
      PlayerInfo[zzVictimID].bHasFlag = false;
    }
}

// =============================================================================
// LogSpree ~ Handle killing sprees
// Note: killing sprees get logged when they end. If someone has a killing spree
// at the end of the game or while he disconnects, this function gets called
// with KillerID 33
// =============================================================================

function LogSpree (int KillerID,int VictimID)
{
    local int i;
    local string spree;

    if (KillerID != 33)
      PlayerInfo[KillerID].zzSpree++;

    i = PlayerInfo[VictimID].zzSpree;
    PlayerInfo[VictimID].zzSpree = 0;

    switch (i)
    {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
            return;
        case 5:
        case 6:
        case 7:
        case 8:
        case 9:
            spree = "spree_kill";
            break;
        case 10:
        case 11:
        case 12:
        case 13:
        case 14:
            spree = "spree_rampage";
            break;
        case 15:
        case 16:
        case 17:
        case 18:
        case 19:
            spree = "spree_dom";
            break;
        case 20:
        case 21:
        case 22:
        case 23:
        case 24:
            spree = "spree_uns";
            break;
        default:
            spree = "spree_god";
            break;
    }

    LogEventString(GetTimeStamp()$Chr(9)$"spree"$chr(9)$spree$chr(9)$PlayerInfo[VictimID].zzID);
}

// =============================================================================
// LogCombo ~ Handle combos
// Note: combos get logged when they end.
// =============================================================================

function LogCombo (int KillerID, optional bool bEndGame,optional bool bDisconnect)
{
    local float zzNow;

    if (bEndGame)
      zzNow = zzEndTime;
    else if (bDisconnect)
      zzNow = PlayerInfo[KillerID].zzEndTime;
    else
      zzNow = Level.TimeSeconds;

    if (zzNow - PlayerInfo[KillerID].zzLastKill < 3.0)
    {
      if ((bEndGame || bDisconnect) && (PlayerInfo[KillerID].zzCombo > 1))  // Combo was still going on when player disconnected
        LogEventString(GetTimeStamp()$chr(9)$"spree"$chr(9)$zzComboCode[Clamp(PlayerInfo[KillerID].zzCombo-2,0,3)]$chr(9)$PlayerInfo[KillerID].zzID);
      else
        PlayerInfo[KillerID].zzCombo++;
    }
    else
    {
      if (PlayerInfo[KillerID].zzCombo > 1)
        LogEventString(GetTimeStamp()$chr(9)$"spree"$chr(9)$zzComboCode[Clamp(PlayerInfo[KillerID].zzCombo-2,0,3)]$chr(9)$PlayerInfo[KillerID].zzID);
      PlayerInfo[KillerID].zzCombo = 1;
    }

    PlayerInfo[KillerID].zzLastKill = zzNow;
}

// =============================================================================
// LogTeamKill ~ :/
// =============================================================================

function LogTeamKill( int KillerID, int VictimID, string KillerWeaponName, string VictimWeaponName, name DamageType )
{
   local int zzKillerID, zzVictimID;

   if (!Level.Game.IsA('TeamGamePlus'))
   {
       LogKill(KillerID,VictimID,KillerWeaponName,VictimWeaponName,DamageType);
       return;
   }

   if (!bGameStarted && !GameStarted())
     return;

   zzKillerID = GetID(KillerID);
   zzVictimID = GetID(VictimID);

   PlayerInfo[zzKillerID].zzTeamKills++;
   PlayerInfo[zzVictimID].zzDeaths++;

   super.LogTeamKill(KillerID,VictimID,KillerWeaponName,VictimWeaponName,DamageType);

   if (PlayerInfo[zzVictimID].bHasFlag)
      PlayerInfo[zzVictimID].bHasFlag = false;
}

// =============================================================================
// LogSuicide
// =============================================================================

function LogSuicide (Pawn Killed, name DamageType, Pawn Instigator)
{
   local int zzKilled;

   if (!bGameStarted && !GameStarted())
     return;

   zzKilled = GetID(Killed.PlayerReplicationInfo.PlayerID);

   PlayerInfo[zzKilled].zzSuicides++;

   Super.LogSuicide(Killed,DamageType,Instigator);

   if (PlayerInfo[zzKilled].bHasFlag)
      PlayerInfo[zzKilled].bHasFlag = false;
}

// =============================================================================
// LogACEInfo - Retrieve the HWID and MACs from the ACECheck object
// =============================================================================

function LogACEInfo (out PlayerStruct P)
{
  local Actor Ace;
	local Actor AceCheck;

  Ace = AceHandler.GetACE();

  if (P.zzHWID != "")
      return;

  if (Ace != none)
      {
        foreach AllActors(class'Actor', AceCheck)
          {
            if (AceCheck.IsA('IACECheck') && AceHandler.GetAceCheckHWHash(AceCheck) != "" && P.zzID == AceHandler.GetAceCheckPlayerId(AceCheck))
            {
                log("[UTStatsLite]: ACE PlayerID: "$AceHandler.GetAceCheckPlayerId(AceCheck)$"");
                log("[UTStatsLite]: PRI PlayerID: "$P.zzID$"");

                P.zzHWID = AceHandler.GetAceCheckHWHash(AceCheck);
                P.zzMAC1 = AceHandler.GetAceCheckUTDCMacHash(AceCheck);
                P.zzMAC2 = AceHandler.GetAceCheckMACHash(AceCheck);

                LogEventString(GetTimeStamp()$Chr(9)$"player"$Chr(9)$"HWID"$Chr(9)$P.zzID$Chr(9)$P.zzHWID); 
                LogEventString(GetTimeStamp()$Chr(9)$"player"$Chr(9)$"MAC1"$Chr(9)$P.zzID$Chr(9)$P.zzMAC1);
                LogEventString(GetTimeStamp()$Chr(9)$"player"$Chr(9)$"MAC2"$Chr(9)$P.zzID$Chr(9)$P.zzMAC2); 
      
                Log("[UTStatsLite]: PlayerID: "$P.zzID$" already has HWID "$P.zzHWID$"");
                Log("[UTStatsLite]: PlayerID: "$P.zzID$" already has MAC1 "$P.zzMAC1$"");
                Log("[UTStatsLite]: PlayerID: "$P.zzID$" already has MAC2 "$P.zzMAC2$"");
                break;
              }
          }
      }
      
  if (AceCheck == none || AceHandler.GetAceCheckHWHash(AceCheck) == "")
      {
        Log("[UTStatsLite]: No ACECheck object found for player"@P.zzID);
        return; // retry later
      }
 }

// =============================================================================
// LogPlayerConnect ~ We don't like spectators
// =============================================================================

function LogPlayerConnect(Pawn Player, optional string Checksum)
{
    if (Player.IsA('Spectator'))
        return;

    super.LogPlayerConnect(Player,Checksum);
}

// =============================================================================
// LogPlayerDisconnect ~ Handle sprees/combos, then add to the buffer
// =============================================================================

function LogPlayerDisconnect(Pawn Player)
{
    local int i;

    if (Player.IsA('Spectator'))
        return;

    i = GetID(Player.PlayerReplicationInfo.PlayerID);

    LogEventString(GetTimeStamp()$Chr(9)$"player"$Chr(9)$"Disconnect"$Chr(9)$Player.PlayerReplicationInfo.PlayerID);

    PlayerInfo[i].zzEndTime = Level.TimeSeconds;

    if (!bGameStarted && !GameStarted())
        return;

    LogSpree(33,i);
    LogCombo(i,,true);

    AddToBuffer(i);

    PlayerInfo[i].zzID = -1;
}

// =============================================================================
// LogSpecialEvent ~ Any gametype-specific event goes trough this function
// Note: we don't log translocation events as it's a lot of spam and it's not
// usefull at all
// =============================================================================

function LogSpecialEvent(string EventType, optional coerce string Arg1, optional coerce string Arg2, optional coerce string Arg3, optional coerce string Arg4)
{
    local int i;

    if ((InStr(EventType,"transloc") != -1) || (InStr(EventType,"dom_") != -1) && (Level.Game.NumPlayers == 0))
    {
        if (EventType=="translocate")
        {
            i = GetID(int(Arg1));
            PlayerInfo[i].bHasFlag = false;
        }
    }
    else
    {
        super.LogSpecialEvent(EventType,Arg1,Arg2,Arg3,Arg4);
    }

    if (!bGameStarted && !GameStarted())
        return;

    if (EventType=="flag_taken" || EventType=="flag_PlayerInfockedup")
    {
        i = GetID(int(Arg1));

        PlayerInfo[i].bHasFlag = true;
    }
    else if (EventType=="flag_captured")
    {
        i = GetID(int(Arg1));

        PlayerInfo[i].bHasFlag = false;
    }
}

// =============================================================================
// We're using the tick function to set IP's
// =============================================================================

function Tick (float DeltaTime)
{
   local pawn NewPawn;

   super.Tick(DeltaTime);

   if (Level.Game.CurrentID > CurrentID)
   {
       for( NewPawn = Level.PawnList ; NewPawn!=None ; NewPawn = NewPawn.NextPawn )
       {
           if(NewPawn.bIsPlayer && NewPawn.PlayerReplicationInfo.PlayerID == CurrentID)
           {
	           SetIP(NewPawn);
			   break;
           }
       }
       ++CurrentID;
   }
}

function SetIP( Pawn Player)
{
   local string zzIP;

   if (Player.IsA('PlayerPawn'))
     zzIP = PlayerPawn(Player).GetPlayerNetworkAddress();
   else
     zzIP = "0.0.0.0";

   zzIP = IPOnly(zzIP);

   LogEventString(GetTimeStamp()$Chr(9)$"player"$Chr(9)$"IP"$Chr(9)$Player.PlayerReplicationInfo.PlayerID$Chr(9)$zzIP);
}

function string IPOnly (string zzIP)
{
    if (InStr(zzIP,":") != -1)
         zzIP = Left(zzIP,InStr(zzIP,":"));

    return zzIP;
}

// =============================================================================
// Game Start/End functions
// =============================================================================

function LogGameStart()
{
    LogEventString(GetTimeStamp()$Chr(9)$"game_start");
}

function LogGameEnd( string Reason )
{
    local int i;

    zzEndTime = Level.TimeSeconds;

    Super.LogGameEnd(Reason);

    for (i=0;i<32;++i)
    {
       if (PlayerInfo[i].zzID != -1) // Player is still on the server
       {
         LogSpree(33,i);
         LogCombo(i,true);
         AddToBuffer(i);
         PlayerInfo[i].zzID = -1;
       }
    }

    ProcessBuffer();
}

// =============================================================================
// Using buffer to log all playerstats at the end of the
// game, not during the game.
// =============================================================================

function AddToBuffer ( int zzPlayerID )
{
    local float zzEfficiency,zzTTL,zzTimeOnServer,CurrentTime;

    if (PlayerInfo[zzPlayerID].zzPawn == none)
        return;

    CurrentTime = Level.TimeSeconds;

    zzTimeOnServer = Min(CurrentTime-PlayerInfo[zzPlayerID].zzJoinTime,CurrentTime-zzWarmupTime);

    if (PlayerInfo[zzPlayerID].zzDeaths != 0)
      zzTTL = zzTimeOnServer/(PlayerInfo[zzPlayerID].zzDeaths) ;
    else
      zzTTL = zzTimeOnServer;

    if ((PlayerInfo[zzPlayerID].zzKills+PlayerInfo[zzPlayerID].zzDeaths+PlayerInfo[zzPlayerID].zzSuicides+PlayerInfo[zzPlayerID].zzTeamKills) == 0)
      zzEfficiency = 0.0;
    else
      zzEfficiency = float(PlayerInfo[zzPlayerID].zzKills)/float(PlayerInfo[zzPlayerID].zzKills+PlayerInfo[zzPlayerID].zzDeaths+PlayerInfo[zzPlayerID].zzSuicides+PlayerInfo[zzPlayerID].zzTeamKills)*100.0;

    BufferLog("stat_player","score",PlayerInfo[zzPlayerID].zzID,string(int(PlayerInfo[zzPlayerID].zzPawn.PlayerReplicationInfo.Score)));
    BufferLog("stat_player","frags",PlayerInfo[zzPlayerID].zzID,string(PlayerInfo[zzPlayerID].zzKills - PlayerInfo[zzPlayerID].zzSuicides));
    BufferLog("stat_player","kills",PlayerInfo[zzPlayerID].zzID,string(PlayerInfo[zzPlayerID].zzKills));
    BufferLog("stat_player","deaths",PlayerInfo[zzPlayerID].zzID,string(PlayerInfo[zzPlayerID].zzDeaths));
    BufferLog("stat_player","suicides",PlayerInfo[zzPlayerID].zzID,string(PlayerInfo[zzPlayerID].zzSuicides));
    BufferLog("stat_player","teamkills",PlayerInfo[zzPlayerID].zzID,string(PlayerInfo[zzPlayerID].zzTeamKills));
    BufferLog("stat_player","efficiency",PlayerInfo[zzPlayerID].zzID,string(zzEfficiency));
    BufferLog("stat_player","time_on_server",PlayerInfo[zzPlayerID].zzID,string(CurrentTime-PlayerInfo[zzPlayerID].zzJoinTime));
    BufferLog("stat_player","ttl",PlayerInfo[zzPlayerID].zzID,string(zzTTL));

}

function BufferLog ( string zzTag, string zzType, int zzPlayerID, string zzValue )
{
    zzBuffer = zzBuffer$":::"$zzTag$chr(9)$zzType$chr(9)$string(zzPlayerID)$chr(9)$zzValue;
}

function ProcessBuffer () // This will cause extreme cpu usage on the server for a sec :)
{
    local int index,i;

    while (InStr(zzBuffer,":::") != -1)
    {
        index = InStr(zzBuffer,":::");
        LogEventString(GetTimeStamp()$chr(9)$Left(zzBuffer,index));
        zzBuffer = Mid(zzBuffer,index+3);
    }

    LogEventString(GetTimeStamp()$chr(9)$zzBuffer);

    if (Level.Game.IsA('TeamGamePlus')) // Requested by the php-coders :o
    {
        for (i=0;i<TeamGamePlus(Level.Game).MaxTeams;++i)
        {
            LogEventString(GetTimeStamp()$chr(9)$"teamscore"$chr(9)$string(i)$chr(9)$string(int(TeamGamePlus(Level.Game).Teams[i].Score)));
        }
    }
}

// =============================================================================
// SetEncoding ~ Set the encoding to UTF8_BOM if the engine supports it
// =============================================================================

function SetEncoding() {
    local int EngineVersion;
    local string EngineRevision;

    EngineVersion = int(Level.EngineVersion);
    if (EngineVersion >= 469) {
        EngineRevision = Level.GetPropertyText("EngineRevision");
        EngineRevision = Left(EngineRevision, InStr(EngineRevision, " "));

        if (Len(EngineRevision) > 0 && EngineRevision != "a" && EngineRevision != "b") {
            SetPropertyText("Encoding", "FILE_ENCODING_UTF8_BOM");
        }
    }
}


// =============================================================================
// Functions used to get the offset in the PI array
// =============================================================================

function int GetID (int PID)
{
    local int i;

    for (i=0;i<32;++i)
    {
       if (PlayerInfo[i].zzID == PID)
         return i;
    }

    return -1;
}

// =============================================================================
// Functions that shouldn't be active in warmup mode
// =============================================================================

function LogPings ()
{
   if (!bGameStarted && !GameStarted())
     return;

   super.LogPings();
}

function LogItemActivate (Inventory Item, Pawn Other)
{
   if (!bGameStarted && !GameStarted())
     return;

   Super.LogItemActivate(Item,Other);
}

function LogItemDeactivate (Inventory Item, Pawn Other)
{
   if (!bGameStarted && !GameStarted())
     return;

   super.LogItemDeactivate(Item,Other);
}

function LogPickup (Inventory Item, Pawn Other)
{
   if (!bGameStarted && !GameStarted())
     return;

   super.LogPickup(Item,Other);
}

// =============================================================================
// Warmupmode
// =============================================================================

function bool GameStarted()
{
    if(DeathMatchPlus(Level.Game).bTournament && DeathMatchPlus(Level.Game).CountDown > 0)
        return false;
    else
    {
        if (!bGameStarted)
        {
            zzWarmupTime = Level.TimeSeconds;
            LogEventString(GetTimeStamp()$Chr(9)$"game"$chr(9)$"realstart");
        }

        bGameStarted = true;
        return true;
    }
}

// =============================================================================
// AddMutator ~ Add mutatorclass to our list
// =============================================================================

function AddMutator (Mutator M)
{
    zzMutatorList = zzMutatorList$":::"$M.class;
}

// =============================================================================
// LogMutatorList ~ Log the list
// =============================================================================

function LogMutatorList()
{
    local string zzEntry,zzDesc;
    local int zzNum;

    zzEntry = "(none)";

    while (zzEntry != "")
    {
        if ((InStr(CAPS(zzMutatorList),CAPS(zzEntry)) != -1) && zzDesc != "")
        {
            if (InStr(zzDesc,",") != -1)
                zzDesc = Left(zzDesc,InStr(zzDesc,","));
            LogEventString(GetTimeStamp()$chr(9)$"game"$chr(9)$"GoodMutator"$chr(9)$zzDesc);
        }
        GetNextIntDesc("Engine.Mutator",zzNum++,zzEntry,zzDesc);
    }
}

// =============================================================================
// Defaultproperties
// =============================================================================

defaultproperties
{
	zzVersion="1.1"
}
