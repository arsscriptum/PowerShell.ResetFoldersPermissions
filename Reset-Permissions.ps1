<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

    
[CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Mandatory=$False)]
        [switch]$TestMode
    )


#requires -runasadministrator


function Reset-AccessRights{
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
        [switch]$Simulation
    )
    Begin{
        $Paths = (gci -Path $BasePath -Directory).Fullname
        $Paths += $BasePath
        $is_admin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) 
        if($False -eq $is_admin)   { throw "Administrator privileges required" } 
        $object_count = $Paths.Count
        $username = (Get-LocalUser).Name -replace '(.*\s.*)',"'`$1'" | Where-Object { $_ -match "$Owner"}
        Write-Verbose "Reset-AccessRights for owner $Owner. Num $object_count paths"
        Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "Reset-AccessRights for owner $Owner. Num $object_count paths" -FontWeight Bold -FontSize 12 -NewLine
    }
    Process{
      try{

        $usr_allow  = "$ENV:USERDOMAIN\$username"               , 'FullControl'  , "none, none","none","Allow"
        $secobj_user_allow  = New-Object System.Security.AccessControl.FileSystemAccessRule $usr_allow 
        $i = 0
        Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete 0
        if($Null -eq $secobj_user_allow)    { throw "Error on FileSystemAccessRule creation $usr_allow" }
        [system.collections.arraylist]$results = [system.collections.arraylist]::new()
        ForEach($obj in $Paths){
            if($obj.Contains('[') ){ Write-Host "$_" ; continue;  }
            $userobject = New-Object System.Security.Principal.NTAccount("$ENV:USERDOMAIN", "$username")
            $acl = Get-Acl -Path $obj
            #foreach ($aceToRemove in $acl.Access){
            #    $r= $acl.RemoveAccessRule($aceToRemove)
            #}
            
            $acl.SetAccessRuleProtection($false, $false)
            $acl.SetAccessRule($secobj_user_allow)
           
            $acl.SetOwner($userobject)

            Write-Verbose "Save the access rules for `"$obj`""
            # Save the access rules to disk:
            try{
                if($Simulation){
                    Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "$obj"  -FontSize 10 -NewLine -BackGroundColor Yellow
                }else{
                    $acl | Set-Acl $obj -ErrorAction Stop
                    [int]$per=[math]::Round($i / $object_count * 100)
                    Write-Progress -Activity 'Reset-AccessRights' -Status "Done $i on $object_count.  $per %" -PercentComplete $per
                    Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "$obj"  -FontSize 10 -NewLine -ForeGroundColor LightGreen
                    $i++
                }

                
            }catch{
                Write-Host "Set-Acl ERROR `"$obj`" $_" -f Red
            }
        }
        Write-Progress -Activity 'Reset-AccessRights' -Complete
        Write-Verbose "$($results.Count) paths modified"
        Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text  "$i paths modified" -FontSize 10 -NewLine
        $results
      }catch{
        Write-Error $_
      }
    }
}


function Get-ImgPath{ 
    [CmdletBinding(SupportsShouldProcess)]
    Param ()  
    $ScriptPath = $PSScriptRoot
    $imgpath = Join-Path $ScriptPath 'img'
    return $imgpath
}


function TextFormatting {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String]$Text,
        [Switch]$Bold, #https://docs.microsoft.com/en-us/uwp/api/windows.ui.text.fontweights
        [Switch]$Italic, #https://docs.microsoft.com/en-us/uwp/api/windows.ui.text.fontstyle
        [String]$TextDecorations, #https://docs.microsoft.com/en-us/uwp/api/windows.ui.text.textdecorations
        [Int]$FontSize,
        [String]$Foreground,
        [String]$Background,
        [Switch]$NewLine
    )
    Begin {
        #https://docs.microsoft.com/en-us/uwp/api/windows.ui.text
        $ObjRun = New-Object System.Windows.Documents.Run
        function TextUIElement {
            Param (
                    [parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
                    [String]$PropertyName
                )
            $Script:PropValue = $PropertyName
            Switch ($PropertyName) {
                'Bold' {'FontWeight'} #Thin, SemiLight, SemiBold, Normal, Medium, Light, ExtraLight, ExtraBold, ExtraBlack, Bold, Black
                'Italic' {'FontStyle'} #Italic, Normal, Oblique
                'TextDecorations' {'TextDecorations'} #None, Strikethrough, Underline
                'FontSize' {'FontSize'}
                'Foreground' {'Foreground'}
                'Background' {'Background'}
                'NewLine' {'NewLine'}
            }
        }
    }
    Process {
        if ($PSBoundParameters.ContainsKey('NewLine')) {
            $ObjRun.Text = "`n$Text "
        }
        else  {
            $ObjRun.Text = $Text
        }
        
        $AllParameters = $PSBoundParameters.Keys | Where-Object {$_ -ne 'Text'}

        foreach ($SelectedParam in $AllParameters) {
            $Prop = TextUIElement -PropertyName $SelectedParam
            if ($PSBoundParameters[$SelectedParam] -eq [System.Management.Automation.SwitchParameter]::Present) {
                $ObjRun.$Prop = $PropValue
            }
            else {
                $ObjRun.$Prop = $PSBoundParameters[$Prop]
            }
        }
        $ObjRun
    }
}

Function Get-StartingFolder{
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Position=0, Mandatory=$False)]
        [String]$InitialDirectory=""
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

function Format-RichTextBox {
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Windows.Controls.RichTextBox]$RichTextBoxControl,
        [String]$Text,
        [String]$ForeGroundColor = 'Black',
        [String]$BackGroundColor = 'White',
        [String]$FontSize = '12',
        [String]$FontStyle = 'Normal',
        [String]$FontWeight = 'Normal',
        [Switch]$NewLine
    )
    $ParamOptions = $PSBoundParameters
    $RichTextRange = New-Object System.Windows.Documents.TextRange(<#$RichTextBoxControl.Document.ContentStart#>$RichTextBoxControl.Document.ContentEnd, $RichTextBoxControl.Document.ContentEnd)
    if ($ParamOptions.ContainsKey('NewLine')) {
        $RichTextRange.Text = "`n$Text"
    }
    else  {
        $RichTextRange.Text = $Text
    }

    $Defaults = @{ForeGroundColor='Black';BackGroundColor='White';FontSize='12'; FontStyle='Normal'; FontWeight='Normal'}
    foreach ($Key in $Defaults.Keys) {
        if ($ParamOptions.Keys -notcontains $Key) {
            $ParamOptions.Add($Key, $Defaults[$Key])
        }
    }  

    $AllParameters = $ParamOptions.Keys | Where-Object {@('RichTextBoxControl','Text','NewLine') -notcontains $_}
    foreach ($SelectedParam in $AllParameters) {
        if ($SelectedParam -eq 'ForeGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::ForegroundProperty}
        elseif ($SelectedParam -eq 'BackGroundColor') {$TextElement = [System.Windows.Documents.TextElement]::BackgroundProperty}
        elseif ($SelectedParam -eq 'FontSize') {$TextElement = [System.Windows.Documents.TextElement]::FontSizeProperty}
        elseif ($SelectedParam -eq 'FontStyle') {$TextElement = [System.Windows.Documents.TextElement]::FontStyleProperty}
        elseif ($SelectedParam -eq 'FontWeight') {$TextElement = [System.Windows.Documents.TextElement]::FontWeightProperty}
        $RichTextRange.ApplyPropertyValue($TextElement, $ParamOptions[$SelectedParam])
    }
}

function Show-ResetPermissionsDialog{
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Mandatory=$False)]
        [switch]$TestMode
    )


    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

    $ImgPath = Get-ImgPath
    Write-Verbose "Get-ImgPath $ImgPath"
    $ImgSrc = (Join-Path $ImgPath "BackGround.jpg")

   
    #Load required libraries 

    [xml]$xaml = @"

    <Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
            xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
            xmlns:local="clr-namespace:WpfApp10"
            Title="Reddit Support - Reset-Permissions" Height="417.861" Width="476.995" ResizeMode="NoResize" Topmost="True" WindowStartupLocation="CenterScreen">

    <Grid>
        <Image HorizontalAlignment="Left" Height="419" VerticalAlignment="Top" Width="469" Source="F:\Scripts\PowerShell.Reddit.Support\Reset-Permissions\img\BackGround.jpg" Margin="0,0,0,-58"/>
        <Label Name='Url' Content='by http://arsscriptum.github.io - For u/NegativelyMagnetic on Reddit' HorizontalAlignment="Left" Margin="10,70,0,0" VerticalAlignment="Top" Foreground="Gray" Cursor='Hand' ToolTip='by http://arsscriptum.github.io - For u/NegativelyMagnetic on Reddit'/>
        <TextBox Name='Path' HorizontalAlignment="Left" Height="23" Margin="69,10,0,0" TextWrapping="Wrap" Text="$env:APPDATA" VerticalAlignment="Top" Width="325"/>
        <Button Name='ResetPermissions' Content="Go" HorizontalAlignment="Left" Margin="361,352,0,0" VerticalAlignment="Top" Height="23" Width="75" RenderTransformOrigin="0.161,14.528"/>
        <RichTextBox Name='OutputStream' HorizontalAlignment="Left" Height="239" Margin="10,102,0,0" VerticalAlignment="Top" Width="440">
            <RichTextBox.Resources>
                <Style TargetType="{x:Type Paragraph}">
                    <Setter Property="Margin" Value="0" />
                </Style>
            </RichTextBox.Resources>
            <FlowDocument>
                <Paragraph>
                    <!-- <Run Text="RichTextBox"/> -->
                </Paragraph>
            </FlowDocument>
        </RichTextBox>
        <Label x:Name="labelpath" Content="Start Path" HorizontalAlignment="Left" Margin="3,9,0,0" VerticalAlignment="Top"/>
        <Button x:Name="browse" Content="..." HorizontalAlignment="Left" Margin="404,10,0,0" VerticalAlignment="Top" Width="32" Height="25"/>
        <CheckBox x:Name="whatif_check" Content="WhatIf: Don't change permissions. Just list actions" HorizontalAlignment="Left" Margin="10,356,0,0" VerticalAlignment="Top" Width="310" Height="25"/>
        <Label x:Name="owner_label" Content="Owner" HorizontalAlignment="Left" Margin="3,40,0,0" VerticalAlignment="Top"/>
        <TextBox x:Name='Owner' HorizontalAlignment="Left" Height="23" Margin="69,41,0,0" TextWrapping="Wrap" Text="$env:APPDATA" VerticalAlignment="Top" Width="325"/>
    </Grid>
</Window>
"@ 

    #Read the form 
    $Reader = (New-Object System.Xml.XmlNodeReader $xaml)  
    $Form = [Windows.Markup.XamlReader]::Load($reader)  
    $Script:SimulationOnly = $False
    #AutoFind all controls 
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {  
      New-Variable  -Name $_.Name -Value $Form.FindName($_.Name) -Force  -Scope Script 
    }

    $Script:OutputStream.IsReadOnly = $true
    $Url.Add_MouseLeftButtonUp({ &"start" "https://www.reddit.com/r/PowerShell/comments/y6taqb/please_help_my_readwrite_access_permissions_are/"})
    $Url.Add_MouseEnter({$Url.Foreground = 'DarkGray'})
    $Url.Add_MouseLeave({$Url.Foreground = 'LightGray'})

    $browse.Add_Click({ 
        $InitialDirectory = [Environment]::GetFolderPath('Desktop')
        $SelectedPath =  Get-StartingFolder $InitialDirectory
        $Path.Text = $SelectedPath

    } ) 

    $Owner.Text = "$ENV:USERNAME"

    if($TestMode){
        $Path.Text = "E:\Tmp"
    }

    $whatif_check.Add_Click({ 
        $Script:SimulationOnly = !$Script:SimulationOnly
        Write-Verbose "SimulationOnly $Script:SimulationOnly"
    })

    $ResetPermissions.Add_Click({

        $LocalUsers = (Get-LocalUser).Name
        if(-not($LocalUsers.Contains($($Owner.Text)))){
            Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "$($Owner.Text) is not a valid local user!" -FontWeight Bold -FontSize 14 -NewLine -ForeGroundColor DarkRed
            return
        }
        If ($whatif_check.Checked){
            Write-Verbose "SimulationOnly $Script:SimulationOnly"
            $SimulationOnly = $True
        }
        
        Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "Starting Path: $($Path.Text)" -FontWeight Bold -FontSize 12 -NewLine
        Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "Owner $ENV:USERNAME" -FontWeight Bold -FontSize 12 -NewLine -ForeGroundColor DarkRed
        Format-RichTextBox -RichTextBoxControl $Script:OutputStream -Text "SimulationOnly $Script:SimulationOnly" -FontWeight Bold -FontSize 12 -NewLine -ForeGroundColor DarkRed


        Reset-AccessRights "$($Path.Text)" -Owner "$ENV:USERNAME" -Simulation:$Script:SimulationOnly
    })

    [void]$Form.ShowDialog() 
}


Show-ResetPermissionsDialog -TestMode:$TestMode