class UTSShockBeamSN extends SpawnNotify;

var UTSDamageMut UTSDM;

simulated event Actor SpawnNotification(Actor A)
{
    if (A == None || A.Instigator == None)
        return A;

    UTSDM.zzBeamPlus(A);

    return A;
}

defaultproperties
{
   ActorClass=class'ShockBeam'
}
