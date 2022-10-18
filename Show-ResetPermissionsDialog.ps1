


[CmdletBinding(SupportsShouldProcess)]
Param (
    [parameter(Mandatory=$False, HelpMessage="This argument is for development purposes only. It help for testing.")]
    [switch]$TestMode
    )



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


function Get-ImgPath{ 
    [CmdletBinding(SupportsShouldProcess)]
    Param ()  
    $ScriptPath = $PSScriptRoot
    $imgpath = Join-Path $ScriptPath 'img'
    return $imgpath
}



function Write-RichTextBox {
[CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [System.Windows.Controls.RichTextBox]$RichTextBoxControl,
        [parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String]$Text,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [String]$FontStyle = 'Normal',
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [String]$FontWeight = 'Normal',
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [String]$FontSize= '12',
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [String]$ForeGroundColor = 'Black',
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [String]$BackGroundColor = 'White',
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
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

    $Defaults = @{ForeGroundColor='Black';BackGroundColor='White';FontSize='12'; }
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

Add-Type -TypeDefinition @"
   public enum LogTypes
   {
      LogError,
      LogSuccess,
      LogHighlight,
      LogNormal,
      LogTitle
   }
"@





Function Out-LogMessage{
    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [String]$Message,
        [Parameter(Mandatory=$False,Position=1)]
        [ValidateSet('LogError','LogSuccess','LogHighlight','LogNormal','LogTitle')]
        [string]$Type='LogNormal',
        [parameter(Mandatory=$false)]
        [Alias('f')]
        [string]$ForeGround = 'Gray',
        [parameter(Mandatory=$false)]
        [Alias('n')]
        [switch]$NoNewLine
    )
    Write-Verbose "Out-LogMessage $Message $Type"
    $AddNewLine = $True
    if($NoNewLine) { $AddNewLine = $False } 

    switch ($Type)
    {
        "LogError"      { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '12' -Foreground Red         -Background Yellow          -FontWeight 'Bold'       -NewLine:$AddNewLine  } 
        "LogSuccess"    { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '14' -Foreground White       -Background Green           -FontStyle 'Italic'      -NewLine:$AddNewLine  } 
        "LogHighlight"  { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '10' -Foreground DarkOrange  -FontWeight 'Bold'          -NewLine:$AddNewLine                           } 
        "LogNormal"     { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '10' -Foreground Teal        -NewLine:$AddNewLine                                                       } 
        "LogTitle"      { Write-RichTextBox -RichTextBoxControl $Script:OutputStream -Text $Message -FontSize '16' -Foreground Yellow      -Background Fuchsia         -FontWeight 'Bold'       -NewLine:$AddNewLine  } 
    }
}

New-Alias -Name "glog" -Value Out-LogMessage -Force -Scope Global -ErrorAction Ignore | Out-Null

Function logerr([string]$m){ glog $m "LogError"     }
Function lognrm([string]$m){ glog $m "LogNormal"    }
Function logerr([string]$m){ glog $m "LogError"     }
Function logscs([string]$m){ glog $m "LogSuccess"   } 
Function loghlt([string]$m){ glog $m "LogHighlight" }
Function logttt([string]$m){ glog $m "LogTitle"     }
try{
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
            Title="Reddit Support - Reset-Permissions" Height="463.632" Width="476.995" ResizeMode="NoResize" Topmost="True" WindowStartupLocation="CenterScreen">

    <Grid>
        <Image HorizontalAlignment="Left" Height="419" VerticalAlignment="Top" Width="469" Source="F:\Scripts\PowerShell.Reddit.Support\Reset-Permissions\img\BackGround.jpg" Margin="0,0,0,-58"/>
        <Label Name='Url' Content='by http://arsscriptum.github.io - For u/NegativelyMagnetic on Reddit' HorizontalAlignment="Left" Margin="10,70,0,0" VerticalAlignment="Top" Foreground="Gray" Cursor='Hand' ToolTip='by http://arsscriptum.github.io - For u/NegativelyMagnetic on Reddit'/>
        <TextBox Name='Path' HorizontalAlignment="Left" Height="23" Margin="69,10,0,0" TextWrapping="Wrap" Text="$env:APPDATA" VerticalAlignment="Top" Width="325"/>
        <Button Name='ResetPermissions' Content="Go" HorizontalAlignment="Left" Margin="361,378,0,0" VerticalAlignment="Top" Height="23" Width="75" RenderTransformOrigin="0.161,14.528"/>
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
        <CheckBox x:Name="whatif_check" Content="WhatIf: Don't change permissions. Just list actions" HorizontalAlignment="Left" Margin="10,390,0,0" VerticalAlignment="Top" Width="310" Height="25"/>
        <Label x:Name="owner_label" Content="Owner" HorizontalAlignment="Left" Margin="3,40,0,0" VerticalAlignment="Top"/>
        <TextBox x:Name='Owner' HorizontalAlignment="Left" Height="23" Margin="69,41,0,0" TextWrapping="Wrap" Text="$env:APPDATA" VerticalAlignment="Top" Width="325"/>
        <CheckBox x:Name="check_dir" IsChecked="True" Content="Process Sub-directories" HorizontalAlignment="Left" Margin="10,364,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="check_files" IsChecked="False" Content="Process Files (childs)" HorizontalAlignment="Left" Margin="178,364,0,0" VerticalAlignment="Top"/>
    </Grid>
</Window>

"@ 


    Write-Host "[RShow-ResetPermissionsDialog] ================================" -f DarkYellow
    Write-Host "[RShow-ResetPermissionsDialog]             TEST MODE           " -f Red
    Write-Host "[RShow-ResetPermissionsDialog] ================================" -f DarkYellow
    #Read the form 
    $Reader = (New-Object System.Xml.XmlNodeReader $xaml)  
    $Form = [Windows.Markup.XamlReader]::Load($reader)  
    $Script:SimulationOnly = $False
    #AutoFind all controls 
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {  
        $VarName = $_.Name
        Write-Host "[RShow-ResetPermissionsDialog] New Gui Variable => $VarName. Scope: Script"
        New-Variable  -Name $_.Name -Value $Form.FindName($_.Name) -Force -Scope Script 
    }

    $ProcessFiles = $False
    $ProcessDirectories = $True

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

    $check_files.Add_Click({ 
        if(-not(Get-Variable -Name ONCE_NOTICE -Scope Global -ErrorAction Ignore -ValueOnly)){
            logerr "NOTE: For some directories containing a large amount of files, it is recommended to only list the sub directories. The time required to set the ACLs on thousands of files may be very long"
            Set-Variable -Name ONCE_NOTICE -Scope Global -ErrorAction Ignore -Value 1
        }
        
        $ProcessFiles = $check_files.IsChecked
        Write-Verbose "ProcessFiles $Script:ProcessFiles"
        if(($check_dir.IsChecked -eq $False) -And ($ProcessFiles -eq $False)){
            $check_dir.IsChecked = $True
            Write-Verbose "Overriding ProcessDirectories"
        }
    })

    $check_dir.Add_Click({ 
        $ProcessDirectories = $check_dir.IsChecked
        Write-Verbose "ProcessDirectories $ProcessDirectories"
        if(($check_files.IsChecked -eq $False) -And ($ProcessDirectories -eq $False)){
            $check_files.IsChecked = $True
            Write-Verbose "Overriding ProcessFiles"
        }
        
    })
    $ResetPermissions.Add_Click({
        $LocalUsers = (Get-LocalUser).Name
        if(-not($LocalUsers.Contains($($Owner.Text)))){
            glog "$($Owner.Text) is not a valid local user!" 2
            return
        }
        If ($whatif_check.IsChecked){
            Write-Verbose "SimulationOnly $Script:SimulationOnly"
            $SimulationOnly = $True
        }
        $ProcessDirectories = $check_dir.IsChecked
        $ProcessFiles = $check_files.IsChecked

        . "$PSScriptRoot\Reset-DirectoryAcl.ps1" "$($Path.Text)" -Owner "$($Owner.Text)" -Simulation $Script:SimulationOnly -Directories $ProcessDirectories -Files $ProcessFiles 
       
    })

    [void]$Form.ShowDialog() 

}catch{
    Show-ExceptionDetails $_ -ShowStack
}