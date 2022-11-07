#Finding Groups and Making Necessary Declarations
$bigListofGroups = get-azureadgroup -all $true
$header = ""
$groupUserslist = @()
$largestGrouplength = 0
$counter = 0

foreach($individualGroup in $bigListofGroups)
{

    $groupMemberslistHolder = @()
    $groupMemberslist = @()

    #Getting Creation Date
    $pattern = "@{CreatedDateTime=([0-9]*/[0-9]*/[0-9]*) "
    $creationDate = get-azureadmsgroup -id $individualGroup.objectid | select-object CreatedDateTime
    if($creationDate -match $pattern)
    {
        $creationDate = $Matches[1]
    }
    $groupMemberslist += @(, $creationDate)

    #Checking for Manager/Owner
    try
    {
        $managerCheck = get-unifiedgroup -filter {ExternalDirectoryObjectId -eq "$individualGroup.objectid"} | select-object managedby | format-list | out-string
        $pattern = "ManagedBy : [\{](.+)[\}]"
        if($managerCheck -match $pattern)
        {
            $managerCheck = "1"
        }
        else
        {
            $managerCheck = "0"
        }
    }
    catch
    {
        $managerCheck = "-1"
    }
    $groupMemberslist += @(, $managerCheck)

    #Creating the header of the CSV
    $headerHolder = get-azureadgroup -objectid $individualGroup.objectid | select-object displayname
    $pattern = "@{DisplayName=(.*)}"
    if($headerHolder -match $pattern)
    {
        $headerHolder = $Matches[1]
        $headerHolder = $headerHolder.replace(",", "(comma)")
    }
    $header += $headerHolder
    $header += ","

    #Creating the list where each value is a user in the group
    $groupMemberslistHolder = get-azureadgroupmember -objectid $individualgroup.objectid | select-object displayname
    $personHolder = ""
    foreach($individualPerson in $groupMemberslistHolder)
    {
        if($individualPerson -match $pattern)
        {
            $personHolder = $Matches[1]
            $personHolder = $personHolder.replace(",", "(comma)")
            $groupMemberslist += @(, $personHolder)
        }
        elseif($null -eq $personHolder -or $personHolder -eq " " -or $personHolder -eq "")
        {
        }
    }

    #Updating the largest group length so the writing loop knows how many times to loop
    if($groupMemberslist.length -gt $largestGrouplength)
    {
        $largestGrouplength = $groupMemberslist.length
    }

    #Adding info to the lists
    $groupUserslist += @(, $groupMemberslist)

    #Writing Progress
    $counter += 1
    write-progress -PercentComplete (($counter/$bigListofGroups.length)*100) -Activity "Finding Groups and Users" -CurrentOperation "Your time is invaluable! Learn something new while you're waiting!"
}

#Start writing to the CSV
$header | out-file -filepath ".\groupAudit.csv" -encoding UTF8

#Filling in lists to match the length of the longest for the writing loop
foreach($individualGroup in $groupUserslist)
{
    while($individualGroup.length -lt $largestGrouplength)
    {
        $individualGroup += " "
    }
}

#Loop that writes the rows
$counter = 0
while($counter -lt $largestGrouplength)
{
    $stringHolder = ""
    #Adding Info to the CSV
    foreach($individualGroup in $groupUserslist)
    {
        $stringHolder += $individualGroup[$counter]
        $stringHolder += ","
    }
    $stringHolder | out-file -filepath ".\groupAudit.csv" -append -encoding UTF8

    #Writing Progress
    $counter += 1
    write-progress -PercentComplete (($counter/$largestGrouplength)*100) -Activity "Adding Groups and Users to a CSV" -CurrentOperation "Almost done."
}
write-host "DONE!"

<#Notes
https://docs.microsoft.com/en-us/microsoft-365/solutions/microsoft-365-groups-expiration-policy?view=o365-worldwide
https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-lifecycle#:~:text=The%20policy%20ID-,The%20lifetime%20for%20all%20Microsoft%20365%20groups%20in%20the%20Azure,%27
https://devblogs.microsoft.com/scripting/testing-rpc-ports-with-powershell-and-yes-its-as-much-fun-as-it-sounds/

Intune Automation
https://docs.microsoft.com/en-us/samples/microsoftgraph/powershell-intune-samples/intune-graph-samples/
#>