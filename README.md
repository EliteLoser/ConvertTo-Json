# ConvertTo-Json

ConvertTo-STJson is a pure-PowerShell ConvertTo-Json that's compatible with PowerShell version 2.

You can read about JSON syntax here: http://json.org

If you have PowerShell version 3 or higher, it's already built into the system.

Online blog documentation: https://www.powershelladmin.com/wiki/ConvertTo-Json_for_PowerShell_version_2

There's a "Send-STSplunkMessage" script/function in this repo here if you're interested in ad hoc splunking from PowerShell (v2 and up):
https://github.com/EliteLoser/Send-SplunkMessage

Complex example object screenshot:

![alt tag](/ConvertTo-STJson-complex-structure-example2.png)

Resulting JSON from ConvertTo-STJson:

![alt tag](/ConvertTo-STJson-complex-structure-json-output-example2.png)

For a while calculated properties caused bugs for now (sort of) known reasons (some sort of inheritance), but it now works directly. I implemented a conversion of DateTime objects to a different type, ISO8601 string `(2023-10-20T19:22:00)`, like the PowerShell team's ConvertTo-Json does (in unpredictable ways).

```powershell
Get-ChildItem wat.psd1 | Select FullName, Name, LastWriteTime,
    @{ Name = 'MeasuredTime'; Expression = { [DateTime]::Now } } |
    ConvertTo-STJson
{
    "FullName": "C:\\temp\\wat.psd1",
    "LastWriteTime": "03/09/2017 19:40:21",
    "MeasuredTime": "04/14/2017 18:32:34",
    "Name": "wat.psd1"
}
```

Here's a demonstration of how to do the same as above using a ForEach-Object and the -InputObject parameter working on $_ and its properties.

```powershell
PS C:\temp> Get-ChildItem wat.psd1 | Select FullName, Name, LastWriteTime |
ForEach-Object { ConvertTo-STJson -InputObject @{
    FullName = $_.FullName
    Name = $_.Name
    LastWriteTime = $_.LastWriteTime
    MeasuredTime = [DateTime]::Now # trying to add
} }
{
    "FullName": "C:\\temp\\wat.psd1",
    "Name": "wat.psd1",
    "MeasuredTime": "04/13/2017 04:41:55",
    "LastWriteTime": "03/09/2017 19:40:21"
}
```

With -Compress:

```powershell
Get-ChildItem wat.psd1 | Select FullName, Name, LastWriteTime,
    @{ Name = 'MeasuredTime'; Expression = { [DateTime]::Now } } |
    ConvertTo-STJson -Compress
{"FullName":"C:\\temp\\wat.psd1","LastWriteTime":"03/09/2017 19:40:21","MeasuredTime":"04/14/2017 18:31:20","Name":"wat.psd1"}
```

Another demonstration of the -Compress parameter introduced in v0.8.

```powershell
. C:\Dropbox\PowerShell\ConvertTo-Json\ConvertTo-STJson.ps1;
@{
    a = @{ a1 = 'val\t\nue1'; a2 = 'va\"lue2'; a3 = @(1, 't\wo\b---\f', 3) }
    b = "test", "42.3e-10"
    c = [pscustomobject] @{ c1 = 'value1'; c2 = "false"; c3 = "null" }
    d = @( @{ foo = 'bar' }, @{ foo2 = 'bar2';
    foo_inner_array = @( @{ deephash = @(@(1..4) + @('foobar', @{ hrm = 'hrmz' }));
    deephash2 = [pscustomobject] @{ a = 1 } }  )})
} | ConvertTo-STJson -Compress

{"c":{"c1":"value1","c2":"false","c3":"null"},"d":[{"foo":"bar"},{"foo_inner_array":[{"dee
phash2":{"a":1},"deephash":[1,2,3,4,"foobar",{"hrm":"hrmz"}]}],"foo2":"bar2"}],"b":["test"
,"42.3e-10"],"a":{"a1":"val\\t\\nue1","a2":"va\\\"lue2","a3":[1,"t\\wo\\b---\\f",3]}}
```

As of v0.8.2, calculated properties also work.

```powershell
[PSCustomObject] @{ testkey = 'testvalue' } | Select *, @{ n='added'; e={'yep, added'}} | ConvertTo-STJson
{
    "added": "yep, added",
    "testkey": "testvalue"
}
```

Passing through $true and $false as of v0.9.2, but it turns out $null is buggy, but only when passed in as a _single value_ (would essentially just be passed through). Will look into it. It works as a value anywhere else (array or PSobject/hash value).

```powershell
PS C:\temp> ($false | ConvertTo-STJson) -eq $false
True

PS C:\temp> ($true | ConvertTo-STJson) -eq $true
True
```

Comparing my cmdlet to the PowerShell team's. DateTime objects are another story still. I'm unsure why they chose the \/Date(01234567...)\/ approach - and also with "meta properties" added (but not always...). As of 2018-06-25, I handle dates with the -DateTimeAsISO8601 parameter (terrible name). See the separate section below.

```powershell
> $ComplexObject = @{
    a = @{ a1 = "value`nwith`r`nnewlines"; a2 = 'va\"lue2'; a3 = @(1, 'tw"o"', 3) }
    b = "test\u0123\foo", "42.3e-10", "2.34", 2.34
    c = [pscustomobject] @{ c1 = 'value1'; c2 = "false"; c3 = "null" }
    d = @( @{ foo = 'bar/barb' }, @{ foo2 = 'bar2';
    foo_inner_array = @( @{ deephash = @(@(1..4) + @('foobar', 
    @{ boobar = @{ nullvalue = $null; nullstring = 'null';
    trueval = $true; falseval = $false; falsestring = "false" }}));
    deephash2 = [pscustomobject] @{ a = 1.23 } }  )})
}

# PS team cmdlet output vs. mine (mine works on PSv2).
> ($ComplexObject | ConvertTo-Json -Compress -Depth 99) -eq `
  ($ComplexObject | ConvertTo-STJson -Compress)
True
```

# DateTime handling

Specify the -DateTimeAsISO8601 parameter (or just -date for short since it's uniquely identifying in the parameter set...) to get dates formatted in the format: `yyyy-MM-ddTHH:mm:ss` (e.g. `2018-06-25T12:29:00` for today at the time of writing).

```powershell
PS C:\temp> @{ key = @((get-date), (get-date).AddDays(-1)) } | convertto-stjson -DateTimeAsISO8601
{
    "key":
    [
        "2018-06-25T12:27:32",
        "2018-06-24T12:27:32"
    ]
}

PS C:\temp> @{ key = @((get-date), (get-date).AddDays(-1)) } | convertto-stjson -DateTimeAsISO8601 -Compress
{"key":["2018-06-25T12:27:45","2018-06-24T12:27:45"]}
```
