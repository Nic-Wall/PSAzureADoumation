<#Attempting Invoke-WebRequest (which won't work because it only returns barebones web pages. It won't let any JavaScript load)
$URL = "https://www.dell.com/support/home/en-us"
$response = Invoke-WebRequest -URI $URL -UseBasicParsing
$response
#>





<#
function test-DateChange{
    param(
        $OldDate
    )
    $OldDate = @($OldDate -split " ")
    $OldDate = $OldDate[1..3]
    $OldDate[2] = [int]($OldDate[2]) + 4
    $newDate = ""
    foreach($index in $OldDate)
    {
        $NewDate += [string]$index + " "
    }
    return $NewDate
}
#Using internet explorer automation, similar to Selenium
#$UserData = get-intunemanageddevice | select-object -property userDisplayName, serialNumber     #Acquiring the user and the service tag of their assigned device
$UserData = "9LDS203"

$InternetEx = new-object -com InternetExplorer.application  #Opening Internet Explorer (IE)
$InternetEx.visible = $true #Setting it so IE is open on the screen
$InternetEx.Navigate("https://www.dell.com/support/home/en-us")     #Moving to dell's support
while($InternetEx.busy){start-sleep -Seconds 10}  #Waiting for IE to load the AJAX script before continuing (else an error will occur as it can't find the HTML location below)
#$InternetEx.Document.getElementById("inpEntrySelection").value = "$UserData.serialNumber"   #Inputting the service tag
$InternetEx.Document.getElementById("inpEntrySelection").value = "$UserData"

$InternetEx.Document.getElementById("btn-entry-select").click()     #Clicking search
$ExpirationDate = @($InternetEx.Document.getElementByTagName("warrantyExpiringLabel mb-0 ml-1 mr-1"))[0]    #Pulling the warranty expiration date from the newly loaded page
$ExpirationDate = test-DateChange ($ExpirationDate) #Bumping the date forward four years (The company's device experiation date)
write-host("$UserData   |   $ExpirationDate")
#>
#https://devblogs.microsoft.com/powershell/controlling-internet-explorer-object-from-powershell/