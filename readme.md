#backup.bat

##A Windows 7 backup script using onboard tools only
The script supports differential backups, full backups and single backups. It supports multiple backup jobs on NTFS volumes.

###Differential Backup
Only modified files are copied. For unmodified files a hardlink is created so that the original folder structure is retained and can be restored/ copied as a whole. Helps to save disk space and minimizes backup time.

###Full backup
All files are copied, without using hardlinks. Needs most disk space and takes longest backup time.

###Single backup
Only modified files are copied. For unmodified files a hardlink is created. But only the latest version will be kept. This can be used in conjunction with other backup mechanisms, e.g. time backup, which handle the file history.

##Files
- backup-ger.bat - The script itself (German version)
- backup.odg - The flowchart's source
- backup.pdf - The flowchart
- backup-overview-original.pdf - The original flowchart from Mark

##Usage
**backup.bat /n bu_name c:\users** (passing **/diff** as parameter is optional)  
Creates a new job: differential backup of "c:\users" with name "bu_name".

**backup.bat /n bu_name c:\users /full**  
Creates a new job: full backup of "c:\users" with name "bu_name".

**backup.bat /n bu_name c:\users /single**  
Creates a new job: single backup of "c:\users" with name "bu_name".

**backup.bat /b bu_name**  
Backs up the current state of "c:\users".

**backup.bat /?**  
Show the available commands.

##Misc
The script has not been extensively tested, yet. So please be careful at the beginning and double check the result.

#####Thanks to Mark Neugebauer (info@raketenphysik.de) for the good starting point.