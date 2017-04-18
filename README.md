# ConvertTo-Json

ConvertTo-STJson is a basic PowerShell version 2-compatible ConvertTo-Json that's under heavy development as of 2017-04-18.
You can read about JSON syntax here: http://json.org

If you have PowerShell version 3 or higher, it's already built into the system.

Online blog documentation: http://www.powershelladmin.com/wiki/ConvertTo-Json_for_PowerShell_version_2

Complex example object screenshot:

![alt tag](/ConvertTo-STJson-complex-structure-example2.png)

Resulting JSON from ConvertTo-STJson:

![alt tag](/ConvertTo-STJson-complex-structure-json-output-example2.png)

For a while calculated properties caused bugs for now (sort of) known reasons (some sort of inheritance), but it now works directly. I am looking into converting DateTime objects to a different type, like the PowerShell team's ConvertTo-Json does.

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

{"c":{"c1":"value1","c2":false,"c3":null},"d":[{"foo":"bar"},{"foo_inner_array":[
{"deephash2":{"a":1},"deephash":[1,2,3,4,"foobar",{"hrm":"hrmz"}]}],"foo2":"bar2"
}],"b":["test",42.3e-10],"a":{"a1":"val\t\nue1","a2":"va\"lue2","a3":[1,"t\\wo\b-
--\f",3]}}
```

As of v0.8.2, calculated properties also work.

```powershell
[PSCustomObject] @{ testkey = 'testvalue' } | Select *, @{ n='added'; e={'yep, added'}} | ConvertTo-STJson
{
    "added": "yep, added",
    "testkey": "testvalue"
}
```

I was using "-is [PSCustomObject]" to check and changed it to GetType().FullName, because while the object is a System.String, PS still believes it's a PS custom object. As seen here:

```powershell
[PSCustomObject] @{ testkey = 'testvalue' } | Select *, @{ n='added'; e={'yep, added'}} |
    %{ $_.added.GetType().FullName; $_.added -is [PSCustomObject] }
System.String
True
```

A little test of how standards-conforming it is. The PS team quotes scientific numbers, so I'm fixing that on the fly in mine. I think that's a small flaw in the PS team's version? Doh, of course they don't quote it if it's a _numerical type_, but mine forces numerical types on all strings that match numbers. I'll fix this in an upcoming version.

```powershell
PS C:\temp> . C:\Dropbox\PowerShell\ConvertTo-Json\ConvertTo-STJson.ps1

PS C:\temp> $ComplexObject = @{
    a = @{ a1 = 'val\t\nue1'; a2 = 'va\"lue2'; a3 = @(1, 't\wo\b---\f', 3) }
    b = "te`nst", "42.3e-10"
    c = [pscustomobject] @{ c1 = 'value1'; c2 = "false"; c3 = "null" }
    d = @( @{ foo = 'bar' }, @{ foo2 = 'bar2';
    foo_inner_array = @( @{ deephash = @(@(1..4) + @('foobar', @{ nullvalue = $null; nullstring = 'null';
    trueval = $true; falseval = $false; falsestring = "false" }));
    deephash2 = [pscustomobject] @{ a = 1.23 } }  )})
}

PS C:\temp> ($ComplexObject | ConvertTo-Json -Compress -Depth 99) -eq (($ComplexObject | ConvertTo-STJson -Compress) -replace "(42\.3e-10)", '"$1"')
True

PS C:\temp> $ComplexObject | ConvertTo-STJson -Compress
{"c":{"c1":"value1","c2":"false","c3":"null"},"d":[{"foo":"bar"},{"foo_inner_array":[{"deephash2":{"a":1.23},"deephash":[1,2,3,4,"foobar",{"trueval":true,"falseval":false,"nullstring"
:"null","falsestring":"false","nullvalue":null}]}],"foo2":"bar2"}],"b":["te\nst",42.3e-10],"a":{"a1":"val\\t\\nue1","a2":"va\\\"lue2","a3":[1,"t\\wo\\b---\\f",3]}}

```

Passing through $true and $false as of v0.9.2, but it turns out $null is buggy. Will look into it.

```powershell
PS C:\temp> ($false | ConvertTo-STJson) -eq $false
True

PS C:\temp> ($true | ConvertTo-STJson) -eq $true
True
```
