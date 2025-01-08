class UTStatsBufferNode extends Object;

var string Buffer;
var UTStatsBufferNode Next;
var int CurrentSize;
var int MaxBufferSize;

defaultproperties
{
    MaxBufferSize=8192
    CurrentSize=0
}