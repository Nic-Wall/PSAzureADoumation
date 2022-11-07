$mList = @("Nestor", "Alex", "Clark", "Diego", "Joni", "Lee")
$counter = 0
foreach($fake in $mList)
{
    $objectHolder = get-azureaduser -searchstring $fake | select-object objectid
    $pnameHolder = get-azureaduser -searchstring $fake | select-object userprincipalname


    $pattern = "@{ObjectId=([A-z]*[0-9]*[A-z]*[0-9]*[A-z]*[0-9]*[A-z]*[0-9]*-[A-z]*[0-9]*[A-z]*[0-9]*-[A-z]*[0-9]*[A-z]*[0-9]*-[A-z]*[0-9]*[A-z]*[0-9]*-[A-z]*[0-9]*[A-z]*[0-9]*[A-z]*[0-9]*[A-z]*[0-9]*)"
    if($objectHolder -match $pattern)
    {
        $objectHolder = $Matches[1]
    }
    $pattern = "@{UserPrincipalName=([A-z]*@811ee.onmicrosoft.com)"
    if($pnameHolder -match $pattern)
    {
        $pnameHolder = $Matches[1]
    }

    set-azureaduser -objectid $objectHolder -accountenabled $false    

    if($counter -eq 0 -or $counter -eq 1)
    {
        set-azureaduser -objectID $objectHolder -country "Terminated"
        set-mailbox $pnameHolder -litigationholdenabled $true
    }
    elseif($counter -eq 2)
    {
        

        set-azureaduser -objectID $objectHolder -country "Terminated"

    }
    elseif($counter -eq 3)
    {
        

        set-azureaduser -objectID $objectHolder -country "Terminated"

    }
    elseif($counter -eq 4)
    {
        

        set-azureaduser -objectID $objectHolder -country "United States"

    }
    elseif($counter -eq 5)
    {
        

        set-azureaduser -objectID $objectHolder -country "United States"

    }
    else{}
    $counter += 1
}