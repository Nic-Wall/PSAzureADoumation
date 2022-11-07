<#What is this script doing?: 
Removing unnecessary bloatware automatically installed on Dell devices. What each is and what it does can be found below.
If the bloatware is not found it is skipped, allowing this script to be run on computers if they contain each listed or just one.
Output a final message that states what was deleted. 

What is it deleting?:
+ Dell Digital Delivery Services:
    - Dell's built-in store for buying licenses and software that Dell promotes, such as Adobe, Cyberlink, and Pocketcloud. These pieces of software usually require a digital 
        or physical key to claim but they're automatically added to your Dell account when purchased through Delivery Service. This is basically only necessary for people that
        bought their laptop from a physical or online retailer that offered (for example) Adobe for an upcharge. When they start their computer for the first time Dell recognizes
        the laptop service tag bought adobe and Delivery Service installs the application associated with the purchase as soon as the computer connects to the internet.
    - More info: https://www.dell.com/support/contents/en-us/article/product-support/self-support-knowledgebase/software-and-downloads/download-center/dell-digital-delivery

+ Dell Optimizer Service:
    - Uses machine learning (ML) to "intelligently and dynamically optimizes the performance of your computer". This includes; audio optmization, an extension that uses ML
        to increase battery life, faster computer wake-up times, faster application launching, and computer locking when the user steps away from the key board (creepy, does
        that mean it's spying on you through the camera at all times?). According to most of the internet this simple done by giving frequently used applications a lauch bias.
        This also idles opened lesser used application while keeping the more frequent open application running, which could negatively affect performance on either (not necessarily
        the intention, but it could happen). Windows already does this, but Dell does it better... ¯\_(ツ)_/¯ ?
    - https://www.dell.com/support/kbdoc/en-us/000128673/dell-optimizer-over-view-and-common-questions
    - https://www.dell.com/support/home/en-us/product-support/product/dell-optimizer/docs

+ Dell Power Manager Service:
    - Lists basically everything the hardware does; thermal management, "battery extender", controls charging speeds, draws from the 
        battery even when plugged in to save on power consumption and prolong battery health. All can be done manually in Windows advanced battery settings.
        The online concensus is the same as above, remove it.
    - https://www.dell.com/support/contents/en-us/article/product-support/self-support-knowledgebase/software-and-downloads/dell-power-manager

+ Dell SupportAssist OS Recovery Plugin for Dell Update: (Leave for Now)
    - Adds a one-time boot option (I think one-time means once you exit you have to restart the computer to boot into the option again) that gives suggestions on how to fix
        operating system related issues. Mixed opinions appear online; some users report Windows default boot giving them the option to boot into this without anything being wrong
        with their OS and the less experienced user may not know which option to boot into, others suggest keeping it because it can redownload/backup OS images to the cloud giving
        users a "quick" fix if their OS corrupts while IT isn't in the office. We can re-install OS's here with a live image, so I don't think it's necessary especially because we
        already tell users to save everything to Onedrive anyways.
    - https://www.dell.com/support/home/en-us/drivers/driversdetails?driverid=jvfgh&oscode=wt64a&productcode=xps-15-9500-laptop

+ Dell SupportAssist Remediation or Dell SupportAssist OS Recovery:
    - Acts similarly to OS Recovery Plugin, except it simply saves a snapshot of the OS everytime the computer is re-booted to reference in case an issue arises when attempting to
        boot. A user has said they keep in installed, but disables the automatic start-up as bugs are frequent with it. Once again, since we keep a live image USB in office and 
        all users store their information on Onedrive, I don't think this necessary. 
    - https://www.dell.com/community/SupportAssist-for-PCs/to-install-support-assist-remediation-back/td-p/8248214
    - https://www.dell.com/community/Inspiron/Dell-SupportAssist-remediation/td-p/7799079

+ Dell Partner Promo: (Leave for Now)
    - Very little word about what it is besides a nuisance. Keep or not, my computer is running fine without it
    - https://www.reddit.com/r/Dell/comments/s2tutl/dell_application/

What do you need to know about all this?:
Suggestions I see state the best solution is Microsoft's Media Creator, allowing users to create a USB that contains only the programs they desire. Unfortunetly, I don't believe
    this can be done, currently, in conjunction with Autopilot.
#>


function test-DellAppRemoval  #Removes all Bloatware containing the word Dell, returns a check if Support Assist already exists or not
{
    param 
    (
        $AppName
    )
    
    $SAInstalled = $False
    if($Null -eq $Appname)
    {
        write-host("`nThere are no Dell Packages Installed on this Computer...")  #Will write the following message if the command on line 83 finds no "Dell" packages
    }
    else
    {
        foreach($IndApplication in $AppName)                #For each package containing "Dell"...
        {
            if($IndApplication -notlike "*DellSupportAssist*")  #If it doesn't contain "DellSupportAssist" remove it
            {
                try {remove-appxpackage -package "$IndApplication"}
                catch {write-host "Failed to remove $IndApplication"}
            }
            else                                            #Else, continue as normal (leaving packages containing "DellSupportAssist" alone)
            {
                $SAInstalled = $True
                continue
            }
        }
    }
    return $SAInstalled

}

function test-SAInstall    #If Support Assist does not exist, this script installs and launches it for the user
{
    $user = get-childitem -path "C:\Users\" -Name       #Pulling list of users to find the downloads path this is required because... (see notes 1)
    foreach($item in $user)
    {
        if($item -eq "defaultuser0" -or $item -eq "Public" -or $item -eq "defaultuser") #Going through the three others that COULD be on there, but may not be to find just the user
        {
            continue
        }
        else
        {
            $user = $item   #Taking the users name to add to the path
            break
        }
    }
    $url = "downloads.dell.com/serviceability/catalog/SupportAssistInstaller.exe"   #Download link
    $todayIs = get-date -format "dd_MM_yyyy"                                        #Today's date, to append to the path
    $OutPath = "C:\Users\$user\Downloads\Dell_SAI_$todayIs.exe"                     #Where I want the download to go, or "the path"

    #Invoke-Webrequest Attempt
    try
    {
        invoke-webrequest -URI $URL -OutFile $OutPath -UseBasicParsing      #Downloading the SupportAssist.exe
    }
    catch
    {
        write-host("Failed to find download link or organize the Path to send the executable. You'll have to perform this task manually.")
    }

    #Starting the Executable installed from the Web-Request
    start-sleep -seconds 2
    Start-Process -Filepath $OutPath -Verb RunAs    #Start the executable as an admin
}

function test-DellPackageRemoval
{
    param 
    (
        $PackageName
    )

    foreach($IndPack in $PackageName)
    {
        if($IndPack -notlike "*Dell SupportAssist*" -or $IndPackage -notlike "*dell*-*")
        {
            uninstall-package -name $IndPack
        }
        else
        {
            continue
        }
    }
}


#Main Script
write-host("If prompted to install 'NuGet' enter 'A' or 'Y' and press enter...")
for($itteration = [int](0); $itteration -le [int](4); $itteration++)
{
    $BloatApps = (get-appxpackage).packagefullname | where-object {$_ -like "*dell*"}       #Finds all apps containing the key word "Dell"
    $BloatPackages = (get-package).name | where-object {$_ -like "*dell*"}
    if($itteration -eq [int](0))
    {
        $SAExists = test-DellAppRemoval($BloatApps)       #Points to above function
        if($SAExists -eq $False)
        {
            test-SAInstall
        }
        else{continue}
    }
    elseif($itteration -eq [int](1))
    {
        write-host("`n`nEnsure the only app below contains 'DellSupportAssist'...")
        foreach($IndApp in $BloatApps)
        {
            write-host("$IndApp")
        }
    }
    elseif($itteration -eq [int](2))
    {
        $ElusivePackages = @("Dell Optimizer Service", "Dell SupportAssist Remediation")
        foreach($EP in $ElusivePackages)
        {
            $UninstallEXE = get-itemproperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | where-object {$_.DisplayName -match "$EP"}
            if($EP -eq "Dell SupportAssist Remediation")
            {
                $UninstallEXE = $UninstallEXE.QuietUninstallString
                $isEXEOnly = test-path -literalpath $uninstallEXE
                if($isEXEOnly)
                {
                    $uninstallEXE = "`"$uninstallEXE`""
                }
                $UninstallEXE += ' /uninstall /quiet'
            }
            else
            {
                $UninstallEXE = $UninstallEXE.UninstallString
                $isEXEOnly = test-path -literalpath $uninstallEXE
                if($isEXEOnly)
                {
                    $uninstallEXE = "`"$uninstallEXE`""
                }
            }
            & "C:\Windows\SYSTEM32\cmd.exe" /c $uninstallEXE
        }
    }
    elseif($itteration -eq [int](3)) 
    {
        if($SAExists -eq $False)    #If SupportAssist does not exist, neither should the other packages, so there is no need to run this portion
        {
            continue
        }
        else 
        {
            test-DellPackageRemoval($BloatPackages)
        }
    }
    else
    {
        write-host("`n`nEnsure the only packages below contains 'Dell SupportAssist', 'Dell SupportAssist OS Recovery Plugin for Dell Update', or anything with a '-' and version number...")
        foreach($IndPackage in $BloatPackages)
        {
            write-host("$IndPackage")
        }
    }
}
write-host("`n`nThe script has concluded, please type 'set-executionpolicy' and press enter.") 
write-host("When prompted type 'restricted' and press enter. `nWhen prompted again enter 'A' or 'Y', then press enter.`nYou may then close the window.")



<#Notes:
General Notes and Alternetives: https://www.reddit.com/r/PowerShell/comments/ur01s1/uninstalling_dell_bloatware/
+ Dell SupportAssist OS Recovery Plugin for Dell Update is found using "get-wmiobject win32_product"
    - https://gregramsey.net/2012/02/20/win32_product-is-evil/
    - Alternatives : https://www.reddit.com/r/PowerShell/comments/w8ogkd/is_win32_product_still_a_steaming_pile_of_garbage/
+ Uninstalling MSI packages with uninstall strings
    - https://stackoverflow.com/questions/73489962/remove-dell-optimizer-service-powershell
    - https://stackoverflow.com/questions/64071377/executing-uninstall-string-with-powershell
    - https://www.dell.com/community/Windows-10/windows-10-firmware-dell-update-untrutsted/td-p/7768552
+ 1. Get-LocalUser returns DefaultAccount, not the users name
#>