<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

    

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('p', 'f','File')]
        [string]$BasePath,
        [Parameter(Mandatory=$true,Position=1)]
        [Alias('u')]
        [ValidateScript({
            if ([string]::IsNullOrEmpty($_)) {
                throw "Invalid username specified `"$1`""
            }
            else {
                $Owner = $_
                $UsrOrNull = (Get-LocalUser -ErrorAction Ignore).Name  | Where-Object { $_ -match "$Owner"}
                if ([string]::IsNullOrEmpty($UsrOrNull)) {
                    throw "Invalid username specified `"$Owner`""
                }
            }
            return $true 
        })]
        [string]$Owner,
        [parameter(Mandatory=$False)]
        [bool]$Simulation,
        [parameter(Mandatory=$False)]
        [bool]$Directories,
        [parameter(Mandatory=$False)]
        [bool]$Files
    )

    #requires -runasadministrator
    $is_admin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
    if($False -eq $is_admin)   { throw "Administrator privileges required" } 
    
    loghlt "[Reset-DirectoryAcl] Resetting ACLs for owner => $Owner"
    loghlt "[Reset-DirectoryAcl] From base path           => $BasePath"
    loghlt "[Reset-DirectoryAcl] Sub directories          => $Directories"
    loghlt "[Reset-DirectoryAcl] All subdirectories files => $Files"
    loghlt "Listing ... "
    $Paths = (gci -Path $BasePath -Directory:$Directories -File:$Files).Fullname
    $Paths += $BasePath
    $object_count = $Paths.Count
    logerr  "$object_count objects to process..."
 
    
    $username = (Get-LocalUser).Name -replace '(.*\s.*)',"'`$1'" | Where-Object { $_ -match "$Owner"}
    Write-Verbose "Reset-AccessRights for owner $Owner. Num $object_count paths"
    logttt "Reset-AccessRights for owner $Owner. Num $object_count paths"
    
    try{
        $usr_allow  = "$ENV:USERDOMAIN\$username", 'FullControl'  , "none, none","none","Allow"
        $secobj_user_allow  = New-Object System.Security.AccessControl.FileSystemAccessRule $usr_allow 
        $i = 0
        Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete 0
        if($Null -eq $secobj_user_allow)    { throw "Error on FileSystemAccessRule creation $usr_allow" }
        [system.collections.arraylist]$results = [system.collections.arraylist]::new()
        ForEach($obj in $Paths){
            if($obj.Contains('[') ){ Write-Host "$_" ; continue;  }
            $userobject = New-Object System.Security.Principal.NTAccount("$ENV:USERDOMAIN", "$username")

            # ===============================================================
            # BELOW - THIS IS THE MEAT OF THE SCRIPT - WHERE THE SHIT HAPPENS
            # ===============================================================

            # Fetch the ACL for the object listed.
            $acl = Get-Acl -Path $obj

            # Sets or removes protection of the access rules: Enables Inheritance (second argument is ignored if first is False)
            $acl.SetAccessRuleProtection($false, $false)

            # We SET a ACL for the specified user: FULL CONTROL
            $acl.SetAccessRule($secobj_user_allow)

            # IMPORTANT NOTE: Since we enabled inheritance, we don't add anymore ACLs to this oject and rely on 
            # the parent rights. I want this script to apply minimal privileges changes possile for evey objects.
            # If the inheritance is setup properly, this is the best way to "RESET" the access rights.
           
            # Lastly,  make sure that the owner is set correctly.
            $acl.SetOwner($userobject)

            # ================================================================
            # ABOVE -- THSI IS THE MEAT OF THE SCRIPT - WHERE THE SHIT HAPPENS
            # ================================================================

            # Save the access rules to disk:
            Write-Verbose "Save the access rules for `"$obj`""

            try{
                if($Simulation){
                    loghlt "$obj"
                }else{
                    $acl | Set-Acl $obj -ErrorAction Stop
                    [int]$per=[math]::Round($i / $object_count * 100)
                    Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete $per
                    lognrm "$obj"
                    $i++
                }
            }catch{
                logerr "Set-Acl ERROR `"$obj`" $_"
            }
        }
        Write-Progress -Activity 'Reset-AccessRights' -Complete
        logscs "$($results.Count) paths modified"
        
        $results
      }catch{
        Write-Error $_
      }
    
