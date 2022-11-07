#Misc Declarations 
$TodaysDate = get-date
$TodaysDate = [int](([datetimeoffset]$TodaysDate).tounixtimeseconds())
$CSVHeaders = "DisplayName,DeviceName,ServiceTag,ShipDate,ExpirationDate,TimeToExire(Days)"
$allAzureADdevices = get-azureaddevice -all $true
$stringHolder = ""
$masterList = @()
$counter = 0
$counterHolder = 100
$origin = New-Object -type DateTime -ArgumentList 1970,1,1      #Creating the origin of Unix time to use as a reference when converting the dates back into date time

#Declarations of API Key and Secret Key
$clientID = "l73e69be38e5db45249abd47af5cc5037b"
$clientSecret = "48792f1be36b4f5d96953359efb89d5e"

#Writing info to user
write-host "Starting"

#Collecting first Bearer Token 
$currentTime = get-date
$currentTime = [int]([datetimeoffset]$currentTime).ToUnixTimeSeconds()
#Requesting Bearer Token. Need to have a start and end time, and request a new token EVERY HOUR
$authURI = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"  #Declaring Auth URL(I) to get bearer token
$Auth = "$clientID`:$clientSecret"                              #Creating header to hold Keys
$bytes = [System.Text.Encoding]::ASCII.GetBytes($Auth)          #Encoding Keys...
$EncodingAuth = [Convert]::ToBase64String($bytes)               #...
$Header = @{ }                                                  #Creating dictionary for headers
$Header.Add("authorization", "Basic $EncodingAuth")             #Adding necessary headers to tell the API who we are and the information we're sending/ requesting...
$AuthBody = 'grant_type=client_credentials'                     #...
#[Net.ServicePointManager]::SecurityProtocol = [Net.securityprotocoltype]::Tls12                 #Changing Net protocol (TLS =  Transport Level Security) not necessary and Windows actually recommends against hardcoding a change in scripts
$AuthReturned = Invoke-RESTMethod -Method Post -Uri $authURI -Body $AuthBody -head $Header      #Requesting Data and creating the URI
$token = $AuthReturned.access_token     #Pulling bearer token out of what was returned
$Header = @{"Accept" = "application/json"}  #Creating new header for the new URL(I)
$Header.add("Authorization", "Bearer $token")       #Adding the token to the new header

foreach($servicetag in $allAzureADdevices)
{

    if($currentTime -ge ($currentTime + 86400) -or $counter -eq ($counterHolder)) #Refreshing token if it's been over an hour
    {
        $currentTime = get-date
        $currentTime = [int]([datetimeoffset]$currentTime).ToUnixTimeSeconds()
        $authURI = "https://apigtwb2c.us.dell.com/auth/oauth/v2/token"  
        $Auth = "$clientID`:$clientSecret"                              
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($Auth)         
        $EncodingAuth = [Convert]::ToBase64String($bytes)              
        $Header = @{ }                                                  
        $Header.Add("authorization", "Basic $EncodingAuth")             
        $AuthBody = 'grant_type=client_credentials'                     
        #[Net.ServicePointManager]::SecurityProtocol = [Net.securityprotocoltype]::Tls12                 
        $AuthReturned = Invoke-RESTMethod -Method Post -Uri $authURI -Body $AuthBody -head $Header     
        $token = $AuthReturned.access_token     
        $Header = @{"Accept" = "application/json"}  
        $Header.add("Authorization", "Bearer $token")
        $counterHolder += 100   
    }
    else
    {
        $stdn = $servicetag.displayname
        $pattern = "DisplayName : (.+)"
        if($stdn -match $pattern)
        {
            $stdn = $Matches[1]
            $stdn = $stdn.substring(0,7)    #popping the space off the string so "5WDS203 " becomes "5WDS203"
        }

        if(($stdn).length -eq 7)    #Only taking dell device ST, HP has much longer ST's than the 7 of Dell's and Mac has slightly longer
        {
            #Inputting Service Tag
            try
            {
                $userName = get-azureaddevice -objectid $serviceTag.objectid | select-object DevicePhysicalIds | format-list | out-string
                $pattern = "[\[]USER-GID[\]]:(.+):.+, [\[]GID[\]]"
                if($userName -match $pattern)
                {
                    $userName = $Matches[1]
                }
                $userName = get-azureaduser -objectid $userName | select-object DisplayName | format-list | Out-String
                $pattern = "DisplayName : (.+)"
                if($userName -match $pattern)
                {
                    $userName = $Matches[1]
                    $userName = $userName.substring(0,($userName.length))
                }
            }
            catch
            {
                $userName = "No Current User"
            }
            #Will want to enter a foreach loop here when you pull all the service tags from intune (See note)
            #Requesting Info for each Service Tag
            $parameters = @{servicetags = $serviceTag.displayname; Method = "GET"}
            $Returned = Invoke-RestMethod -Uri "https://apigtwb2c.us.dell.com/PROD/sbil/eapi/v5/assets" -Headers $Header -body $parameters -method Get -contenttype "application/json" -ea 0
            $serviceTagReturned = $returned.servicetag
            $json = $Returned | ConvertTo-Json      #Converts Returned into a JSON format
            #write-host $json                       #Uncomment this to see what the json looks like, it's just one dictionary (allows you to see everything selectable)
            $response = $Json | ConvertFrom-Json    #Allows items in the json to be selected individually
            $shipdate = $null
            $ExpirationDate = $null
            $ExpiresIn = $null
            try
            {
                $shipdate = $response.ShipDate                              #Getting ShipDate...
                $shipdate = [int](([datetimeoffset]$shipdate).tounixtimeseconds()) #... and turning it into Unix time to easily measure the expiration
                $ProductLineDescription = $response.ProductLineDescription  #Getting Laptop Name (Ex. "Latitude 1420")

                $ExpirationDate = ([int]$shipDate + (31536000 * 4)) #Expiration date, i.e. 4 years after ship date
                $ExpiresIn = $ExpirationDate - $todaysdate          #Creating the time it'll take for the laptop to expire

                $ExpirationDate = $origin.AddSeconds($ExpirationDate)   #Turning expiration date into date time -f "MM/dd/yyyy"
                $shipdate = $origin.AddSeconds($shipdate)               #Same as ^ but for shipdate
                $ExpiresIn = [int][Math]::Floor($expiresin / 86400)     #Changing the expires in date to days (Always going to be the day it expires so even if it was shipped on 8/4/19 at 11:59 pm it'll say it expires 8/4/19 at 12:00 am)
                $pattern = "([0-9]+[\/][0-9]+[\/][0-9]+)"       #Removing the time of expiration and just formatting to month/day/year
                if($shipdate -match $pattern)
                {
                    $shipdate = $matches[1]
                }
                if($ExpirationDate -match $pattern)
                {
                    $ExpirationDate = $matches[1]
                }
            }
            catch
            {
                $shipdate = "None Found"
                $ExpirationDate = "None Found"
                $ExpiresIn = "None Found"
            }

            $stringHolder = "$userName,$ProductLineDescription,$serviceTagReturned,$shipdate,$ExpirationDate,$ExpiresIn"
            $masterList += $stringHolder
            $counter += 1
        }
        else {}
    }
    write-progress -PercentComplete (($counter/$allAzureADdevices.length)*100) -Activity "Sorting User and Devices" -CurrentOperation "Your time is INVALUABLE! Learn something new while you're waiting!"
}

$counter = 0
$CSVHeaders | out-file -filepath ".\UsersAndDevices.csv" -encoding UTF8
foreach($serviceTag in $masterList)
{
    $serviceTag | out-file -filepath ".\UsersAndDevices.csv" -append -encoding UTF8
    $counter += 1
    write-progress -PercentComplete (($counter/$masterList.length)*100) -Activity "Adding Users to CSV" -CurrentOperation "This'll be over before you know it..."
}

write-host "Done! Thanks for using and I'll see you again sometime soon!"






<#
Notes
1: https://docs.microsoft.com/en-us/dotnet/framework/network-programming/tls
2: https://docs.microsoft.com/en-us/dotnet/api/system.net.securityprotocoltype?view=net-6.0

Dells (semi) useful notes
https://www.dell.com/support/kbdoc/en-in/000177716/using-powershell-with-the-platform-api-the-basics
https://dl.dell.com/content/manual25792673-dell-emc-powerstore-rest-api-reference-guide.pdf?language=en-us
https://www.dell.com/support/manuals/en-us/powerstore-9000t/pwrstr-apidevg/the-powerstore-management-rest-api?guid=guid-33000e1c-83e0-4bf3-8fb3-44b65d57d2dc&lang=en-us
https://adamtheautomator.com/powershell-json/

Dell's Docs use and API formatter called 'PostMan', but PowerShell can do all of this too
Since Dell's Docs aren't much help, I found this online to show how to properly format
https://www.hull1.com/scriptit/2020/08/28/dell-api-warranty-lookup.html
(Don't know the trustworthiness of this site so DO NOT COPY AND PASTE at all. Only use what you are certain is safe and Google the rest to double check)


#>