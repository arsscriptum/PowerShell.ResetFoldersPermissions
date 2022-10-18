
#### Show-ResetPermissionsDialog

#### __To help this dude u/NegativelyMagnetic__

https://www.reddit.com/r/PowerShell/comments/y6taqb/please_help_my_readwrite_access_permissions_are/


#### Show-ResetPermissionsDialog

This file implements the GUI:
- The RichTextBox text formats - Logs
- Getting the base ath fron the user
- Getting the owner username


#### Reset-DirectoryAcl

**THIS IS THE MEAT OF THE SCRIPT - WHERE THE SHIT HAPPENS**

This function will change the acls on the bub folders: enables inheritance, give access to current user and administrator.

**IMPORTANT NOTE**: Since we enabled inheritance, we don't add anymore ACLs to this oject and rely on the parent rights. I want this script to apply minimal privileges changes possile for evey objects.

If the inheritance is setup properly, this is the best way to "RESET" the access rights.
           

## How To Use

```
    .\Show-ResetPermissionsDialog.ps1
```

---------------------------------------------------------------


![DIALOG](https://github.com/arsscriptum/PowerShell.ResetFoldersPermissions/blob/main/img/dialogs.png)

1) Browse and select the BASE directory from which the script will run
2) Enter the username that will be the owner and have full control over the objects that are processed
3) Select the listing of child objects. Those will be processed. Default is subfolders only. Select Files if you want to
   change the access rights over files as well.
   **NOTE 1** For Large folders, it is not recommended to select Files, Changing the ACLs over thousands of files will be very long.
   **NOTE 2** If your parent folders are configured properly with inheritance. After processed, the inheritance will be passed down to all subfolders
              and so you may not need to process the files, just the sub folders may be  sufficient
4) Step 4 **IMPORTANT** SIMULATION It is recommended that you check this box initially in order to test the objects that will be processed.
5) Step 5 GO


---------------------------------------------------------------

## DEMO

![Demo](https://github.com/arsscriptum/PowerShell.ResetFoldersPermissions/blob/main/img/demo.gif?raw=true)