# ConvertTo-Json

ConvertTo-STJson is a PowerShell version 2-compatible ConvertTo-Json. You can read about JSON syntax here: http://json.org

If you have PowerShell version 3 or higher, it's already built into the system.

Online blog documentation: http://www.powershelladmin.com/wiki/ConvertTo-Json_for_PowerShell_version_2

Complex example object screenshot:

![alt tag](/ConvertTo-STJson-complex-structure-example.png)

Resulting JSON from ConvertTo-STJson:

![alt tag](/ConvertTo-STJson-complex-structure-json-output-example.png)

Demonstration of how -QuoteValueTypes will quote also "null", "true" and "false" as values/strings. Introduced in v0.6.

```powershell
PS C:\> ConvertTo-STJson @{ foo = 'null'; bar = 'anything' }
{
    "bar": "anything",
    "foo": null
}

PS C:\> ConvertTo-STJson @{ foo = 'null'; bar = 'anything' } -QuoteValueTypes
{
    "bar": "anything",
    "foo": "null"
}
```
Demonstration of when you might need the -EscapeAll parameter.

```powershell
PS C:\temp> Get-ChildItem wat.psd1 | Select FullName, LastWriteTime | ConvertTo-STJson
{
    "FullName": "C:\temp\\wat.psd1",
    "LastWriteTime": "03/09/2017 19:40:21"
}

PS C:\temp> Get-ChildItem wat.psd1 | Select FullName, LastWriteTime | ConvertTo-STJson -EscapeAll
{
    "FullName": "C:\\temp\\wat.psd1",
    "LastWriteTime": "03/09/2017 19:40:21"
}
```

It appears that calculated properties cause bugs for currently unknown reasons. To work around something where you might want to add a property to multiple objects coming in via the pipeline, you will have to resort to ForEach-Object and the ConvertTo-STJson's -InputObject parameter. Demonstrated here.

```powershell
PS C:\temp> Get-ChildItem wat.psd1 | Select FullName, Name, LastWriteTime |
ForEach-Object { ConvertTo-STJson -EscapeAll -InputObject @{
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

PS C:\temp> Get-ChildItem wat.psd1 | Select FullName, Name, LastWriteTime |
ForEach-Object { ConvertTo-STJson -EscapeAll -InputObject @{
    FullName = $_.FullName
    Name = $_.Name
    LastWriteTime = $_.LastWriteTime
    MeasuredTime = [DateTime]::Now # trying to add
} -Compress }
{"FullName":"C:\\temp\\wat.psd1","Name":"wat.psd1","MeasuredTime":"04/13/2017 04:42:29","LastWriteTime":"03/09/2017 19:40:21"}
```

Demonstration of the -Compress parameter introduced in v0.8.

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
    %{ $_.added.GetType().FullName; $_ -is [PSCustomObject] }
System.String
True
```
