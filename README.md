# ConvertTo-Json

ConvertTo-STJson is a PowerShell version 2-compatible ConvertTo-Json.

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
