# Author: Joakim Borger Svendsen, 2017. http://www.json.org
# Svendsen Tech. Public domain licensed code.
# v0.3, 2017-04-12 (second release of the day, I actually read some JSON syntax this time)
#       Fixed so you don't double-whack the allowed escapes from the diagram, not quoting null, false and true as values.
# v0.4. Scientific numbers are supported (not quoted as values). 2017-04-12.
# v0.5. Adding switch parameter EscapeAllowedEscapesToo (couldn't think of anything clearer),
#       which also double-whacks (escapes with backslash) allowed escape sequences like \r, \n, \f, \b, etc.
#       Still 2017-12-04.
# v0.6: It's after midnight, so 2017-04-13 now. Added -QuoteValueTypes that makes it quote null, true and false as values.
# v0.7: Changed parameter name from EscapeAllowedEscapesToo to EscapeAll (... seems obvious now). Best to do it before it's
#       too late. 2017-04-13.

function ConvertToJsonInternal {
    param(
        $InputObject, # no type for a reason
        [Int32] $WhiteSpacePad = 0)
    [String] $Json = ""
    Write-Verbose -Message "WhiteSpacePad: $WhiteSpacePad."
    if ($InputObject -is [HashTable]) {
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
        $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 8) + "[`n" + (($InputObject | ForEach-Object {
            if ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" -or $_.GetType().Name -match '\[\]|Array') {
                Write-Verbose -Message "Found array, hash table or custom PowerShell object inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 12) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 12)) -replace '\s*,\s*$'
            }
            elseif ($_ -match $Script:NumberAndValueRegex) {
                Write-Verbose -Message "Got a number, true, false or null inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 8) + $_
            }
            else {
                Write-Verbose -Message "Got a string inside array."
                " " * ((4 * ($WhiteSpacePad / 4)) + 8) + '"' + $_ + '"'
            }
        }) -join ",`n") + "`n$(" " * ((4 * ($WhiteSpacePad / 4)) + 8))],`n"
    }
    else {
        Write-Verbose -Message "Input object is a single element."
        '"' + $InputObject + '"'
    }
    if ($Keys.Count) {
        Write-Verbose -Message "Building JSON for hash table or custom PowerShell object."
        $Json += "{`n"
        foreach ($Key in $Keys) {
            if ($InputObject.$Key -is [HashTable] -or $InputObject.$Key -is [PSCustomObject]) {
                Write-Verbose -Message "Input object's value for key '$Key' is a hash table or custom PowerShell object."
                $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ($WhiteSpacePad + 4))"
                $Json += ConvertToJsonInternal -InputObject $InputObject.$Key -WhiteSpacePad ($WhiteSpacePad + 4)
            }
            elseif ($InputObject.$Key.GetType().Name -match '\[\]|Array') {
                Write-Verbose -Message "Input object's value for key '$Key' has a type that appears to be a collection/array."
                Write-Verbose -Message "Building JSON for ${Key}'s array value."
                $Json += " " * ($WhiteSpacePad + 4) + """$Key"":`n$(" " * ((4 * ($WhiteSpacePad / 4)) + 4))[`n" + (($InputObject.$Key | ForEach-Object {
                    Write-Verbose "Type inside array inside array/hash/PSObject: $($_.GetType().FullName)"
                    if ($_ -is [HashTable] -or $_.GetType().FullName -eq "System.Management.Automation.PSCustomObject" `
                        -or $_.GetType().Name -match '\[\]|Array') {
                        Write-Verbose -Message "Found array, hash table or custom PowerShell object inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + (ConvertToJsonInternal -InputObject $_ -WhiteSpacePad ($WhiteSpacePad + 8)) -replace '\s*,\s*$'
                    }
                    elseif ($_ -match $Script:NumberAndValueRegex) {
                        Write-Verbose -Message "Got a number, true, false or null inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + $_
                    }
                    else {
                        Write-Verbose -Message "Got a string inside inside array."
                        " " * ((4 * ($WhiteSpacePad / 4)) + 8) + '"' + $_ + '"'
                    }
                }) -join ",`n") + "`n$(" " * (4 * ($WhiteSpacePad / 4) + 4 ))],`n"
            }
            else {
                if ($InputObject.$Key -match $Script:NumberAndValueRegex) {
                    $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": $($InputObject.$Key),`n"
                }
                else {
                    $Json += " " * ((4 * ($WhiteSpacePad / 4)) + 4) + """$Key"": ""$($InputObject.$Key)"",`n"
                }
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
        [Switch] $EscapeAll,
        [Switch] $QuoteValueTypes)
    begin{
        [String] $JsonOutput = ""
        $Collection = @()
        [String] $Script:NumberAndValueRegex = '^-?\d+(?:(?:\.\d+)?e[+\-]\d+)?$|^(?:true|false|null)$'
        if ($QuoteValueTypes) {
            $Script:NumberAndValueRegex = '^-?\d+(?:(?:\.\d+)?e[+\-]\d+)?$'
        }
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
        if ($EscapeAll) {
            ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" -replace '^\s*|\s*,\s*$' -replace '\\', '\\' -replace '\ *\]\ *$', ']'
        }
        else {
            ($JsonOutput -split "\n" | Where-Object { $_ -match '\S' }) -join "`n" -replace '^\s*|\s*,\s*$' -replace '\\(?!["/bfnrt]|u[0-9a-f]{4})', '\\' -replace '\ *\]\ *$', ']'
        }
    }
}
