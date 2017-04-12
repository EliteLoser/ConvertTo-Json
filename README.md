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

