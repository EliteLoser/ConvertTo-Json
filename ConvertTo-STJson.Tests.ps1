#requires -version 2
<#
Pester 4.x tests for Svendsen Tech's ConvertTo-STJson. Joakim Borger Svendsen.
Initially created on 2017-10-21.
#>

# Standardize the decimal separator to a period (not making it dynamic for now).
$Host.CurrentCulture.NumberFormat.NumberDecimalSeparator = "."

$MyScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
. "$MyScriptRoot\ConvertTo-STJson.ps1"

Describe ConvertTo-STJson {
    It "Test that null, true and false as value types are accounted for when passed in alone" {
        ConvertTo-STJson -InputObject $Null | Should -Be ""
        ConvertTo-STJson -InputObject $False | Should -Be "false"
        ConvertTo-STJson -InputObject $True | Should -Be "true"
    }
    It "Given a number as a value, it should not be quoted" {
        ConvertTo-STJson -InputObject 1 -Compress | Should -Be "1"
        ConvertTo-STJson -InputObject 1.1 -Compress | Should -Be "1.1"
        ConvertTo-STJson -InputObject 1.12e-2 -Compress | Should -Be "0.0112"
    }
    It "Given a number as a string, it should be quoted." {
        ConvertTo-STJson -InputObject "1" -Compress | Should -Be '"1"'
        ConvertTo-STJson -InputObject "1.1" -Compress | Should -Be """1.1"""
        ConvertTo-STJson -InputObject "1.12e-2" -Compress | Should -Be """1.12e-2"""
    }
    It "Given a number as a string, it should not be quoted if -CoerceNumberStrings is passed" {
        ConvertTo-STJson -InputObject "1" -Compress -CoerceNumberStrings | Should -Be "1"
        ConvertTo-STJson -InputObject "1.1" -Compress -CoerceNumberStrings | Should -Be "1.1"
        ConvertTo-STJson -InputObject "1.12e-2" -Compress -CoerceNumberStrings | Should -Be "1.12e-2"

    }
    It "Test hashtable structure with number, string, null, true and false as values" {
        ConvertTo-STJson -InputObject @{ Key = 1.23 } -Compress | Should -Be "{`"Key`":1.23}"
        ConvertTo-STJson -InputObject @{ Key = 'null' } -Compress | Should -Be "{`"Key`":`"null`"}"
        ConvertTo-STJson -InputObject @{ Key = $Null } -Compress | Should -Be "{`"Key`":null}"
        ConvertTo-STJson -InputObject @{ Key = $True } -Compress | Should -Be "{`"Key`":true}"
        ConvertTo-STJson -InputObject @{ Key = $False } -Compress | Should -Be "{`"Key`":false}"
    }
    It "Test custom PowerShell object with number, string, null, true and false as values" {
        ConvertTo-STJson -InputObject (New-Object -TypeName PSObject -Property @{ Key = 1.23 }) -Compress | 
            Should -Be "{`"Key`":1.23}"
        ConvertTo-STJson -InputObject (New-Object -TypeName PSObject -Property @{ Key = 'null' }) -Compress | 
            Should -Be "{`"Key`":`"null`"}"
        ConvertTo-STJson -InputObject (New-Object -TypeName PSObject -Property @{ Key = $Null }) -Compress |
            Should -Be "{`"Key`":null}"
        ConvertTo-STJson -InputObject (New-Object -TypeName PSObject -Property @{ Key = $True }) -Compress |
            Should -Be "{`"Key`":true}"
        ConvertTo-STJson -InputObject (New-Object -TypeName PSObject -Property @{ Key = $False }) -Compress |
            Should -Be "{`"Key`":false}"
    }
    It "Test single array with numbers, strings, null, true and false as values" {
        ConvertTo-STJson -InputObject @(1, 2, 3, "test", $Null, $True, $False, 'bar') -Compress |
            Should -Be '[1,2,3,"test",null,true,false,"bar"]'
    }
    It "Test array as hashtable value, with numbers and strings" {
        # Test a PSCustomObject at the same time. PSv2-compatible syntax/creation (not ordered).
        $Number = New-Object -TypeName PSObject -Property @{
            Key = @(1.12e-2, 2, "3", 'foo')
        }
        ConvertTo-STJson -InputObject $Number -Compress | Should -Be "{`"Key`":[0.0112,2,`"3`",`"foo`"]}"
    }
    It "Test complex/mixed data structure" {
        ConvertTo-STJson -InputObject @{
            a = @(1..3), 'a', 'b'
            nested = @{
                NestedMore = @(1, @{
                    foo = @{ key = 'bar'; a = "b" }
                })
                sleep = 'mom'
            }
        } -Compress |
            Should -Be '{"a":[[1,2,3],"a","b"],"nested":{"NestedMore":[1,{"foo":{"key":"bar","a":"b"}}],"sleep":"mom"}}'
    }
    It "Test that compressed output from the PowerShell team's ConvertTo-Json is identical if on PSv3+, with complex object" {
        if ($PSVersionTable.PSVersion.Major -lt 3) {
            1 | Should -Be 1 # Can't test this on PSv2 or 1.
            break
        }
        $Object = @{
            a = @(@(1..3), 'a', 'b', @{ key = @(1, @(5,6,7), 'x') })
            b = @{ a = @('y', 'z', @(1, @('innerinner', @('innerinnerinner', "innerinnerinner2", @{
            innerkey = 'g' }, @{ inkey = 'f'} ), @(3,4) ) ) )} }
        (ConvertTo-Json -InputObject $Object -Compress -Depth 99) -eq (ConvertTo-STJson -InputObject $Object -Compress) |
            Should -Be $True
        
    }
    It "Test formatting of a complex data structure" {
        ConvertTo-STJson -InputObject @{
            a = @(@(1..3), 'a', 'b', @{ key = @(1, @(5,6,7), 'x') })
            b = @{ a = @('y', 'z', @(1, @('innerinner', @('innerinnerinner', "innerinnerinner2", @{
                innerkey = 'g' }, @{ inkey = 'f'} ), @(3,4) ) ) )} } |
            Should -Be (
@"
{
    "a":
    [
        [
            1,
            2,
            3
        ],
        "a",
        "b",
        {
            "key":
            [
                1,
                [
                    5,
                    6,
                    7
                ],
                "x"
            ]
        }
    ],
    "b":
    {
        "a":
        [
            "y",
            "z",
            [
                1,
                [
                    "innerinner",
                    [
                        "innerinnerinner",
                        "innerinnerinner2",
                        {
                            "innerkey": "g"
                        },
                        {
                            "inkey": "f"
                        }
                    ],
                    [
                        3,
                        4
                    ]
                ]
            ]
        ]
    }
}
"@ -replace '\r') # \n becomes \r\n in this string, but is only \n in the JSON, 
                  # so it breaks the comparison. Workaround. Can't have \r in the test data.
    }
}
