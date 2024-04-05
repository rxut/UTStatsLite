UTStatsLite is a server-side mod for Unreal Tournament that generates custom NGStats log files. These files can be used to create websites with statistics.

This is a modified "lite" version of the original UTStats that removed buggy weapons logging code which caused servers to be laggy.

## Installation
From the System folder in the zip file, copy to your UTServer\System folder the following files:

**Step 1:** Add the following lines to the server UnrealTournament.ini

```
ServerPackages=UTStatsLite
ServerActors=UTStatsLite.UTStatsSA
```
**Step 2:** In the UnrealTournament.ini file, make sure **bLocalLog** is set to **false** like this **bLocalLog=False**.

Log files are stored in the ..\Logs folder inside of your main UT99 server location.

### Credits
UTStats mod was originally created by azazel, AnthraX and toa, with additions by Skillz, killereye, Enakin, Loki and rork.
