# Author: Joakim Borger Svendsen, 2017. http://www.json.org
# Svendsen Tech. Public domain licensed code.
# v0.3, 2017-04-12 (second release of the day, I actually read some JSON syntax this time)
#       Fixed so you don't double-whack the allowed escapes from the diagram, not quoting null, false and true as values.
# v0.4. Scientific numbers are supported (not quoted as values). 2017-04-12.
# v0.5. Adding switch parameter EscapeAllowedEscapesToo (couldn't think of anything clearer),
#       which also double-whacks (escapes with backslash) allowed escape sequences like \r, \n, \f, \b, etc.
#       Still 2017-04-12.
# v0.6: It's after midnight, so 2017-04-13 now. Added -QuoteValueTypes that makes it quote null, true and false as values.
# v0.7: Changed parameter name from EscapeAllowedEscapesToo to EscapeAll (... seems obvious now). Best to do it before it's
#       too late. 2017-04-13.
# v0.7.1: Made the +/- after "e" in numbers optional as this is apparently valid (as plus, then)
# v0.8: Added a -Compress parameter! 2017-04-13.
# v0.8.1: Fixed bug that made "x.y" be quoted (but scientific numbers and integers worked all the while). 2017-04-14.
# v0.8.2: Fixed bug with calculated properties (yay, this improves flexibility significantly). 2017-04-14.
# v0.9: Almost too many changes to mention. Now null, true and false as _value types_ are unquoted, otherwise they
#       are quoted. Comparing to the PowerShell team's ConvertTo-Json. Now escaping works better and more
#       standards-conforming. If you have a newline in the strings, it'll be replaced by "\n" (literally, not a newline),
# while if you have "\n" literally, it'll turn into \\n. Code quality improvements. Refactoring. Still some more to fix,
# but it's getting better. Datetime stuff is bothering me, not sure I like how it's handled in the PS team's cmdlet, but I
# don't have a sufficiently informed opinion.

function FormatString {
    param(
        [String] $String)
    # Returned
    $String -replace '\\', '\\' -replace '\n', '\n' `
        -replace '\u0008', '\b' -replace '\u000C', '\f' -replace '\r', '\r' `
        -replace '\t', '\t' -replace '"', '\"'
}

function ConvertToJsonInternal {
    param(
        $InputObject, # no type for a reason
        [Int32] $WhiteSpacePad = 0)
    [String] $Json = ""
    $Keys = @()
    Write-Verbose -Message "WhiteSpacePad: $WhiteSpacePad."
    if ($null -eq $InputObject) {
        Write-Verbose -Message "Got null in inner function"
        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "null"
    }
    elseif ($InputObject -is [bool] -and $InputObject -eq $true) {
        Write-Verbose -Message "Got 'true' in `$InputObject in inner function"
        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "true"
    }
    elseif ($InputObject -is [bool] -and $InputObject -eq $false) {
        Write-Verbose -Message "Got 'false' in `$InputObject in inner function"
        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "false"
    }
    elseif ($InputObject -is [HashTable]) {
        $Keys = @($InputObject.Keys)
        Write-Verbose -Message "Input object is a hash table (Keys: $($Keys -join ', '))."
    }
    elseif ($InputObject.GetType().FullName -eq "System.Management.Automation.PSCustomObject") {
        $Keys = @(Get-Member -InputObject $InputObject -MemberType NoteProperty |
            Select-Object -ExpandProperty Name)
        Write-Verbose -Message "Input object is a custom PowerShell object (properties: $($Keys -join ', '))."
    }
    elseif ($InputObject.GetType().Name -match '\[\]|Array') {
        Write-Verbose -Message "Input object appears to be of a collection/array type."
        Write-Verbose -Message "Building JSON for array input object."
        $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "[`n" + (($InputObject | ForEach-Object {
            if ($null -eq $_) {
                Write-Verbose -Message "Got null inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "null"
            }
            elseif ($_ -is [bool] -and $_ -eq $true) {
                Write-Verbose -Message "Got 'true' inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "true"
            }
            elseif ($_ -is [bool] -and $_ -eq $false) {
                Write-Verbose -Message "Got 'false' inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + "false"
            }
            elseif ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" -or $_.GetType().Name -match '\[\]|Array') {
                Write-Verbose -Message "Found array, hash table or custom PowerShell object inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 4)) -replace '\s*,\s*$'
            }
            elseif ($_ -match $Script:NumberRegex) {
                Write-Verbose -Message "Got a number inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + $_
            }
            else {
                Write-Verbose -Message "Got a string inside array."
                $TempJsonString = FormatString -String $_ 
                " " * ((4 * ($WhiteSpacePad / 4)) + 4) + '"' + $TempJsonString + '"'
            }
        }) -join ",`n") + "`n$(" " * ((4 * ($WhiteSpacePad / 4)) + 4))],`n"
    }
    elseif ($InputObject -match $Script:NumberRegex) {
        Write-Verbose -Message "Input object is a number."
        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + $InputObject
    }
    else {
        Write-Verbose -Message "Input object is a single element."
        $TempJsonString = FormatString -String $InputObject
        '"' + $TempJsonString + '"'
    }
    if ($Keys.Count) {
        Write-Verbose -Message "Building JSON for hash table or custom PowerShell object."
        $Json += "{`n"
        foreach ($Key in $Keys) {
            # -is [PSCustomObject]) { # this was buggy with calculated properties, the value was thought to be PSCustomObject
            if ($null -eq $InputObject.$Key) {
                Write-Verbose -Message "Got null as `$InputObject.`$Key in inner hash or PS object."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": null,`n"
            }
            elseif ($InputObject.$Key -is [bool] -and $InputObject.$Key -eq $true) {
                Write-Verbose -Message "Got 'true' in `$InputObject.`$Key in inner hash or PS object."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": true,`n"            }
            elseif ($InputObject.$Key -is [bool] -and $InputObject.$Key -eq $false) {
                Write-Verbose -Message "Got 'false' in `$InputObject.`$Key in inner hash or PS object."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": false,`n"
            }
            elseif ($InputObject.$Key -is [HashTable] -or $InputObject.$Key.GetType().FullName -eq "System.Management.Automation.PSCustomObject") {
                Write-Verbose -Message "Input object's value for key '$Key' is a hash table or custom PowerShell object."
                $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ($WhiteSpacePad + 4))"
                $Json += ConvertToJsonInternal -InputObject $InputObject.$Key -WhiteSpacePad ($WhiteSpacePad + 4)
            }
            elseif ($InputObject.$Key.GetType().Name -match '\[\]|Array') {
                Write-Verbose -Message "Input object's value for key '$Key' has a type that appears to be a collection/array."
                Write-Verbose -Message "Building JSON for ${Key}'s array value."
                $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ((4 * ($WhiteSpacePad / 4)) + 4))[`n" + (($InputObject.$Key | ForEach-Object {
                    #Write-Verbose "Type inside array inside array/hash/PSObject: $($_.GetType().FullName)"
                    if ($null -eq $_) {
                        Write-Verbose -Message "Got null inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "null"
                    }
                    elseif ($_ -is [bool] -and $_ -eq $true) {
                        Write-Verbose -Message "Got 'true' inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "true"
                    }
                    elseif ($_ -is [bool] -and $_ -eq $false) {
                        Write-Verbose -Message "Got 'false' inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "false"
                    }
                    elseif ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" `
                        -or $_.GetType().Name -match '\[\]|Array') {
                        Write-Verbose -Message "Found array, hash table or custom PowerShell object inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 8)) -replace '\s*,\s*$'
                    }
                    elseif ($_ -match $Script:NumberRegex) {
                        Write-Verbose -Message "Got a number inside array inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + $_
                    }
                    else {
                        Write-Verbose -Message "Got a string inside inside array."
                        $TempJsonString = FormatString -String $_
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + '"' + $TempJsonString + '"'
                    }
                }) -join ",`n") + "`n$(" " * (4 * ($WhiteSpacePad / 4) + 4 ))],`n"
            }
            elseif ($InputObject.$Key -match $Script:NumberRegex) {
                Write-Verbose -Message "Got a number inside inside hashtable or PSObject."
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": $($InputObject.$Key),`n"
            }
            else {
                Write-Verbose -Message "Got a string inside inside hashtable or PSObject."
                # '\\(?!["/bfnrt]|u[0-9a-f]{4})'
                $TempJsonString = FormatString -String $InputObject.$Key
                $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": ""$TempJsonString"",`n"
            }
        }
        $Json = $Json -replace '\s*,$' # remove trailing comma that'll break syntax
        $Json += "`n" + " " * $WhiteSpacePad + "},`n"
    }
    $Json
}

function ConvertTo-STJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $InputObject,
        [Switch] $Compress)
    begin{
        [String] $JsonOutput = ""
        $Collection = @()
        # Not optimal, but the easiest now.
        [String] $Script:NumberRegex = '^-?\d+(?:(?:\.\d+)?(?:e[+\-]?\d+)?)?$'
        #$Script:NumberAndValueRegex = '^-?\d+(?:(?:\.\d+)?(?:e[+\-]?\d+)?)?$|^(?:true|false|null)$'
    }
    process {
        # Hacking on pipeline support ...
        if ($_) {
            Write-Verbose -Message "Adding object to `$Collection. Type of object: $($_.GetType().FullName)."
            $Collection += $_
        }
    }
    end {
        if ($Collection.Count) {
            Write-Verbose -Message "Collection count: $($Collection.Count), type of first object: $($Collection[0].GetType().FullName)."
            $JsonOutput = ConvertToJsonInternal -InputObject ($Collection | ForEach-Object { $_ })
        }
        else {
            $JsonOutput = ConvertToJsonInternal -InputObject $InputObject
        }
        if ($Compress) {
            (
                ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" `
                    -replace '^\s*|\s*,\s*$' -replace '\ *\]\ *$', ']'
            ) -replace ( # these next lines compress ...
                '(?m)^\s*("(?:\\"|[^"])+"): ((?:"(?:\\"|[^"])+")|(?:null|true|false|(?:' + `
                    $Script:NumberRegex.Trim('^$') + `
                    ')))\s*(?<Comma>,)?\s*$'), "`${1}:`${2}`${Comma}`n" `
              -replace '(?m)^\s*|\s*\z|[\r\n]+'
        }
        else {
            ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" `
                -replace '^\s*|\s*,\s*$' -replace '\ *\]\ *$', ']'
        }
    }
}
