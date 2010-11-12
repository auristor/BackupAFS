#!/usr/bin/perl

#my %lang;
#use strict;

# --------------------------------

$Lang{Start_Archive} = "Start Archive";
$Lang{Stop_Dequeue_Archive} = "Stop/Dequeue Archive";
$Lang{Start_Full_Backup} = "Start Full Backup";
$Lang{Start_Incr_Backup} = "Start Incr Backup";
$Lang{Stop_Dequeue_Backup} = "Stop/Dequeue Backup";
$Lang{Restore} = "Restore";

$Lang{Type_full} = "full";
$Lang{Type_incr} = "incremental";

# -----

$Lang{Only_privileged_users_can_view_admin_options} = "Only privileged users can view admin options.";
$Lang{H_Admin_Options} = "BackupAFS Server: Admin Options";
$Lang{Admin_Options} = "Admin Options";
$Lang{Admin_Options_Page} = <<EOF;
\${h1(qq{$Lang{Admin_Options}})}
<br>
\${h2("Server Control")}
<form name="ReloadForm" action="\$MyURL" method="get">
<input type="hidden" name="action" value="">
<table class="tableStnd">
  <tr><td>Reload the server configuration:<td><input type="button" value="Reload"
     onClick="document.ReloadForm.action.value='Reload';
              document.ReloadForm.submit();">
</table>
</form>
<!--
\${h2("Server Configuration")}
<ul>
  <li><i>Other options can go here... e.g.,</i>
  <li>Edit server configuration
</ul>
-->
EOF

$Lang{Unable_to_connect_to_BackupAFS_server} = "Unable to connect to BackupAFS server";
$Lang{Unable_to_connect_to_BackupAFS_server_error_message} = <<EOF;
This CGI script (\$MyURL) is unable to connect to the BackupAFS
server on \$Conf{ServerHost} port \$Conf{ServerPort}.<br>
The error was: \$err.<br>
Perhaps the BackupAFS server is not running or there is a configuration error.
Please report this to your Sys Admin.
EOF

$Lang{Admin_Start_Server} = <<EOF;
\${h1(qq{$Lang{Unable_to_connect_to_BackupAFS_server}})}
<form action="\$MyURL" method="get">
The BackupAFS server at <tt>\$Conf{ServerHost}</tt> port <tt>\$Conf{ServerPort}</tt>
is not currently running (maybe you just stopped it, or haven't yet started it).<br>
Do you want to start it?
<input type="hidden" name="action" value="startServer">
<input type="submit" value="Start Server" name="ignore">
</form>
EOF

# -----

$Lang{H_BackupAFS_Server_Status} = "BackupAFS Server Status";

$Lang{BackupAFS_Server_Status_General_Info}= <<EOF;
\${h2(\"General Server Information\")}

<ul>
<li> The server's PID is \$Info{pid}, on host \$Conf{ServerHost},
     version \$Info{Version}, started at \$serverStartTime.
<li> This status was generated at \$now.
<li> The configuration was last loaded at \$configLoadTime.
<li> Backups will be next queued at \$nextWakeupTime.
<li> Other info:
    <ul>
        <li>\$numBgQueue pending backup requests from last scheduled wakeup,
        <li>\$numUserQueue pending user backup requests,
        <li>\$numCmdQueue pending other requests,
        <li>Backup file system was recently at \$Info{DUlastValue}%
            (\$DUlastTime), today\'s max is \$Info{DUDailyMax}% (\$DUmaxTime)
            and yesterday\'s max was \$Info{DUDailyMaxPrev}%.
    </ul>
</ul>
EOF

$Lang{BackupAFS_Server_Status} = <<EOF;
\${h1(qq{$Lang{H_BackupAFS_Server_Status}})}

<p>
\$generalInfo

\${h2("Currently Running Jobs")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3">
<tr class="tableheader"><td> VolumeSet </td>
    <td> Type </td>
    <td> User </td>
    <td> Start Time </td>
    <td> Command </td>
    <td align="center"> PID </td>
    <td align="center"> Xfer PID </td>
    </tr>
\$jobStr
</table>
<p>

\${h2("Failures that need attention")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3">
<tr class="tableheader"><td align="center"> VolSet </td>
    <td align="center"> Type </td>
    <td align="center"> User </td>
    <td align="center"> Last Try </td>
    <td align="center"> Details </td>
    <td align="center"> Error Time </td>
    <td> Last error </td></tr>
\$statusStr
</table>
EOF

# --------------------------------
$Lang{BackupAFS__Server_Summary} = "BackupAFS: VolumeSet Summary";
$Lang{BackupAFS__Archive} = "BackupAFS: Archive";
$Lang{BackupAFS_Summary} = <<EOF;

\${h1(qq{$Lang{BackupAFS__Server_Summary}})}
<p>
<ul>
<li>This status was generated at \$now.
<li>Backup file system was recently at \$Info{DUlastValue}%
    (\$DUlastTime), today\'s max is \$Info{DUDailyMax}% (\$DUmaxTime)
        and yesterday\'s max was \$Info{DUDailyMaxPrev}%.
</ul>
</p>

\${h2("VolumeSets with good Backups")}
<p>
There are \$volsetCntGood VolumeSets that have been backed up, for a total of \${sizeTot}GB (\${sizeCompTot}GB after compression).
<ul>
<li> \$fullTot full backups of total size \${fullSizeTot}GB
     (\${fullSizeCompTot}GB after compression)
<li> \$incrTot incr backups of total size \${incrSizeTot}GB
     (\${incrSizeCompTot}GB after compression)
<li> Compression is saving you \${GBsaved}GB, or \${percentsaved}% disk space
</ul>
</p>
<table class="sortable" id="volset_summary_backups" border cellpadding="3" cellspacing="1">
<tr class="tableheader"><td style="vertical-align:top"> VolumeSet </td>
    <td align="center" style="vertical-align:top"> User </td>
    <td align="center" style="vertical-align:top"> #Full </td>
    <td align="center" style="vertical-align:top"> Full Age (days) </td>
    <td align="center" style="vertical-align:top"> Full Size (GB) </td>
    <td align="center" style="vertical-align:top"> Speed (MB/s) </td>
    <td align="center" style="vertical-align:top"> #Incr </td>
    <td align="center" style="vertical-align:top"> Incr Age (days) </td>
    <td align="center" style="vertical-align:top"> Last Backup (days) </td>
    <td align="center" style="vertical-align:top"> State </td>
    <td align="center" style="vertical-align:top"> #Xfer errs </td>
    <td align="center" style="vertical-align:top"> Last attempt </td></tr>
\$strGood
</table>
<br><br>
\${h2("VolumeSets with no Backups")}
<p>
There are \$volsetCntNone VolumeSets with no backups.
<p>
<table class="sortable" id="volset_summary_nobackups" border cellpadding="3" cellspacing="1">
<tr class="tableheader"><td style="vertical-align:top"> VolumeSet </td>
    <td align="center" style="vertical-align:top"> User </td>
    <td align="center" style="vertical-align:top"> #Full </td>
    <td align="center" style="vertical-align:top"> Full Age (days) </td>
    <td align="center" style="vertical-align:top"> Full Size (GB) </td>
    <td align="center" style="vertical-align:top"> Speed (MB/s) </td>
    <td align="center" style="vertical-align:top"> #Incr </td>
    <td align="center" style="vertical-align:top"> Incr Age/days </td>
    <td align="center" style="vertical-align:top"> Last Backup (days) </td>
    <td align="center" style="vertical-align:top"> State </td>
    <td align="center" style="vertical-align:top"> #Xfer errs </td>
    <td align="center" style="vertical-align:top"> Last attempt </td></tr>
\$strNone
</table>
EOF

$Lang{BackupAFS_Archive} = <<EOF;
\${h1(qq{$Lang{BackupAFS__Archive}})}
<script language="javascript" type="text/javascript">
<!--

    function checkAll(location)
    {
      for (var i=0;i<document.form1.elements.length;i++)
      {
        var e = document.form1.elements[i];
        if ((e.checked || !e.checked) && e.name != \'all\') {
            if (eval("document.form1."+location+".checked")) {
                e.checked = true;
            } else {
                e.checked = false;
            }
        }
      }
    }

    function toggleThis(checkbox)
    {
       var cb = eval("document.form1."+checkbox);
       cb.checked = !cb.checked;
    }

//-->
</script>

There are \$volsetCntGood VolumeSets that have been backed up for a total size of \${fullSizeTot}GB
<p>
<form name="form1" method="post" action="\$MyURL">
<input type="hidden" name="fcbMax" value="\$checkBoxCnt">
<input type="hidden" name="type" value="1">
<input type="hidden" name="volset" value="\${EscHTML(\$archVolSet)}">
<input type="hidden" name="action" value="Archive">
<table class="tableStnd" border cellpadding="3" cellspacing="1">
<tr class="tableheader"><td align=center> VolumeSet</td>
    <td align="center"> User </td>
    <td align="center"> Backup Size </td>
\$strGood
\$checkAllVolSets
</table>
</form>
<p>

EOF

# -----------------------------------
$Lang{Pool_Stat} = <<EOF;
        <li>Nightly cleanup removed \$info->{"\${name}FileCntRm"} files of
            size \${poolRmSize}GB (around \$poolTime),
EOF

# --------------------------------
$Lang{BackupAFS__Backup_Requested_on__volset} = "BackupAFS: Backup Requested on \$volset";
# --------------------------------
$Lang{REPLY_FROM_SERVER} = <<EOF;
\${h1(\$str)}
<p>
Reply from server was: \$reply
<p>
Go back to <a href="\$MyURL?volset=\$volset">\$volset home page</a>.
EOF
# --------------------------------
$Lang{BackupAFS__Start_Backup_Confirm_on__volset} = "BackupAFS: Start Backup Confirm on \$volset";
# --------------------------------
$Lang{Are_you_sure_start} = <<EOF;
\${h1("Are you sure?")}
<p>
You are about to start a \$type backup on \$volset.

<form name="Confirm" action="\$MyURL" method="get">
<input type="hidden" name="volset" value="\$volset">
<input type="hidden" name="volsetIP" value="\$ipAddr">
<input type="hidden" name="doit" value="1">
<input type="hidden" name="action" value="">
Do you really want to do this?
<input type="button" value="\$buttonText"
  onClick="document.Confirm.action.value='\$In{action}';
           document.Confirm.submit();">
<input type="submit" value="No" name="ignore">
</form>
EOF
# --------------------------------
$Lang{BackupAFS__Stop_Backup_Confirm_on__volset} = "BackupAFS: Stop Backup Confirm on \$volset";
# --------------------------------
$Lang{Are_you_sure_stop} = <<EOF;

\${h1("Are you sure?")}

<p>
You are about to stop/dequeue backups on \$volset;

<form name="Confirm" action="\$MyURL" method="get">
<input type="hidden" name="volset"   value="\$volset">
<input type="hidden" name="doit"   value="1">
<input type="hidden" name="action" value="">
Also, please don\'t start another backup for
<input type="text" name="backoff" size="10" value="\$backoff"> hours.
<p>
Do you really want to do this?
<input type="button" value="\$buttonText"
  onClick="document.Confirm.action.value='\$In{action}';
           document.Confirm.submit();">
<input type="submit" value="No" name="ignore">
</form>

EOF
# --------------------------------
$Lang{Only_privileged_users_can_view_queues_} = "Only privileged users can view queues.";
# --------------------------------
$Lang{Only_privileged_users_can_archive} = "Only privileged users can Archive.";
# --------------------------------
$Lang{BackupAFS__Queue_Summary} = "BackupAFS: Queue Summary";
# --------------------------------
$Lang{Backup_Queue_Summary} = <<EOF;
\${h1("Backup Queue Summary")}
<br>
<br>
\${h2("User Queue Summary")}
<p>
The following user requests are currently queued:
</p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td> VolumeSet </td>
    <td> Req Time </td>
    <td> User </td></tr>
\$strUser
</table>
<br><br>

\${h2("Background Queue Summary")}
<p>
The following background requests are currently queued:
</p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td> VolumeSet </td>
    <td> Req Time </td>
    <td> User </td></tr>
\$strBg
</table>
<br><br>
\${h2("Command Queue Summary")}
<p>
The following command requests are currently queued:
</p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td> VolumeSet </td>
    <td> Req Time </td>
    <td> User </td>
    <td> Command </td></tr>
\$strCmd
</table>
EOF

# --------------------------------
$Lang{Backup_PC__Log_File__file} = "BackupAFS: File \$file";
$Lang{Log_File__file__comment} = <<EOF;
\${h1("File \$file \$comment")}
<p>
EOF
# --------------------------------
$Lang{Contents_of_log_file} = <<EOF;
Contents of file <tt>\$file</tt>, modified \$mtimeStr \$comment
EOF

# --------------------------------
$Lang{skipped__skipped_lines} = "[ skipped \$skipped lines ]\n";
# --------------------------------
$Lang{_pre___Can_t_open_log_file__file} = "<pre>\nCan\'t open log file \$file\n";

# --------------------------------
$Lang{BackupAFS__Log_File_History} = "BackupAFS: Log File History";
$Lang{Log_File_History__hdr} = <<EOF;
\${h1("Log File History \$hdr")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td align="center"> File </td>
    <td align="center"> Size </td>
    <td align="center"> Modification time </td></tr>
\$str
</table>
EOF

# -------------------------------
$Lang{Recent_Email_Summary} = <<EOF;
\${h1("Recent Email Summary (Reverse time order)")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td align="center"> Recipient </td>
    <td align="center"> VolumeSet </td>
    <td align="center"> Time </td>
    <td align="center"> Subject </td></tr>
\$str
</table>
EOF
 

# ------------------------------
$Lang{Browse_backup__num_for__volset} = "BackupAFS: Browse backup \$num for \$volset";

# ------------------------------
$Lang{Restore_Options_for__volset} = "BackupAFS: Restore Options for \$volset";
$Lang{Restore_Options_for__volset2} = <<EOF;
\${h1("Restore Options for \$volset")}
<p>
You have selected the following files/directories from
share \$share, backup number #\$num:
<ul>
\$fileListStr
</ul>
</p>
\${h2("Direct Restore")}
<p>
EOF

$Lang{Restore_Options_for__volset_Option1} = <<EOF;
You can start a restore that will restore these files directly onto
<b>\$directVolSet</b>.
</p><p>
<b>Warning:</b> any existing files that match the ones you have
selected will be overwritten!
</p>
<form action="\$MyURL" method="post" name="direct">
<input type="hidden" name="volset" value="\${EscHTML(\$volset)}">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="type" value="3">
\$hiddenStr
<input type="hidden" value="\$In{action}" name="action">
<table class="tableStnd" border="0">
<tr>
    <td>Restore the files to AFS</td>
    <td><!--<input type="text" size="40" value="\${EscHTML(\$volset)}"
	 name="volsetDest">-->
	 <select name="volsetDest" onChange="document.direct.shareDest.value=''">
	 \$volsetDestSel
	 </select>
	 <script language="Javascript">
	 function myOpen(URL) {
		window.open(URL,'','width=500,height=400');
	 }
	 </script>
	 <!--<a href="javascript:myOpen('\$MyURL?action=findShares&volset='+document.direct.volsetDest.options.value)">Search for available shares (NOT IMPLEMENTED)</a>--></td>
</tr><tr>
    <td>Restore the files to share</td>
    <td><input type="text" size="40" value="\${EscHTML(\$share)}"
	 name="shareDest"></td>
</tr><tr>
    <td>Restore the files below dir<br>(relative to share)</td>
    <td valign="top"><input type="text" size="40" maxlength="256"
	value="\${EscHTML(\$pathHdr)}" name="pathHdr"></td>
</tr><tr>
    <td><input type="submit" value="Start Restore" name="ignore"></td>
</table>
</form>
EOF

$Lang{Restore_Options_for__afs_Option1} = <<EOF;
You may start a restore that will restore these volume(s) directly into
AFS.
<form action="\$MyURL" method="post" name="direct">
<input type="hidden" name="volset" value="\${EscHTML(\$volset)}">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="type" value="3">
\$hiddenStr
<input type="hidden" value="\$In{action}" name="action">
<table border="0">
<tr><td>AFS fileserver to hold restored volumes (Required)</td><td><input type="text" size="40" value="someserver.your.cell.org" name = "serverDest"</td></tr>
<tr><td><br>Partition to hold restored volumes (Required)</td><td><br><input type="text" size="40" value="/vicepX" name = "partitionDest"</td></tr>
<tr><td><br><br>Extension to append to restored volume names (Optional)</td><td><br><br><input type="text" size="40" value=".r" name = "extensionDest"</td></tr>
<tr><td></td><td><b><i>Warning</i></b> If you make the extension blank, any existing volume with the same name as that of any volume you're restoring <strong>WILL BE OVERWRITTEN!</strong></td>
</tr>

<tr><td colspan="2"><br><br>Note that BackupAFS does not verify the existence of the destination server or partition, or that sufficient space exists on the destination prior to attempting the restoration. It is assumed that the system administrator will do this.</td></tr>
<tr>
    <td><input type="submit" value="Start Restore" name="ignore"></td>
</table>
</form>
EOF

$Lang{Restore_Options_for__volset_Option1_disabled} = <<EOF;
Direct restore has been disabled for VolumeSet \${EscHTML(\$volsetDest)}.
Please select one of the other restore options.
EOF

# ------------------------------
$Lang{Option_2__Download_Zip_archive} = <<EOF;
<p>
\${h2("Option 2: Download Zip archive")}
<p>
You can download a Zip archive containing all the files/directories you have
selected.  You can then use a local application, such as WinZip,
to view or extract any of the files.
</p><p>
<b>Warning:</b> depending upon which files/directories you have selected,
this archive might be very very large.  It might take many minutes to
create and transfer the archive, and you will need enough local disk
space to store it.
</p>
<form action="\$MyURL" method="post">
<input type="hidden" name="volset" value="\${EscHTML(\$volset)}">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="type" value="2">
\$hiddenStr
<input type="hidden" value="\$In{action}" name="action">
<input type="checkbox" value="1" name="relative" checked> Make archive relative
to \${EscHTML(\$pathHdr eq "" ? "/" : \$pathHdr)}
(otherwise archive will contain full paths).
<br>
Compression (0=off, 1=fast,...,9=best)
<input type="text" size="6" value="5" name="compressLevel">
<br>
<input type="submit" value="Download Zip File" name="ignore">
</form>
EOF

# ------------------------------

$Lang{Option_2__Download_Zip_archive2} = <<EOF;
<p>
\${h2("Option 2: Download Zip archive")}
<p>
Archive::Zip is not installed so you will not be able to download a
zip archive.
Please ask your system adminstrator to install Archive::Zip from
<a href="http://www.cpan.org">www.cpan.org</a>.
</p>
EOF


# ------------------------------
$Lang{Option_3__Download_Zip_archive} = <<EOF;
\${h2("Option 3: Download Tar archive")}
<p>
You can download a Tar archive containing all the files/directories you
have selected.  You can then use a local application, such as tar or
WinZip to view or extract any of the files.
</p><p>
<b>Warning:</b> depending upon which files/directories you have selected,
this archive might be very very large.  It might take many minutes to
create and transfer the archive, and you will need enough local disk
space to store it.
</p>
<form action="\$MyURL" method="post">
<input type="hidden" name="volset" value="\${EscHTML(\$volset)}">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="type" value="1">
\$hiddenStr
<input type="hidden" value="\$In{action}" name="action">
<input type="checkbox" value="1" name="relative" checked> Make archive relative
to \${EscHTML(\$pathHdr eq "" ? "/" : \$pathHdr)}
(otherwise archive will contain full paths).
<br>
<input type="submit" value="Download Tar File" name="ignore">
</form>
EOF


# ------------------------------
$Lang{Restore_Confirm_on__volset} = "BackupAFS: Restore Confirm on \$volset";

$Lang{Are_you_sure} = <<EOF;
\${h1("Are you sure?")}
<p>
You are about to start a restore directly to AFS from \$In{volsetDest},
backup number \$num via \$Conf{XferMethod}.
<p>
<table class="tableStnd" border>
<tr class="tableheader"><td>Source</td><td>Restore to AFS</td></tr>
\$restTablerows
</table>

<form name="RestoreForm" action="\$MyURL" method="post">
<input type="hidden" name="volset" value="\${EscHTML(\$volset)}">
<input type="hidden" name="volsetDest" value="\${EscHTML(\$In{volsetDest})}">
<input type="hidden" name="shareDest" value="\${EscHTML(\$In{shareDest})}">
<input type="hidden" name="pathHdr" value="\${EscHTML(\$In{pathHdr})}">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="type" value="4">
<input type="hidden" name="action" value="">
\$hiddenStr
Do you really want to do this?
<input type="button" value="\$Lang->{Restore}"
 onClick="document.RestoreForm.action.value='Restore';
          document.RestoreForm.submit();">
<input type="submit" value="No" name="ignore">
</form>
EOF


# --------------------------
$Lang{Restore_Requested_on__volsetDest} = "BackupAFS: Restore Requested on \$volsetDest";
$Lang{Reply_from_server_was___reply} = <<EOF;
\${h1(\$str)}
<p>
Reply from server was: \$reply
<p>
Go back to <a href="\$MyURL?volset=\$volsetDest">\$volsetDest home page</a>.
EOF

$Lang{BackupAFS_Archive_Reply_from_server} = <<EOF;
\${h1(\$str)}
<p>
Reply from server was: \$reply
EOF


# -------------------------
$Lang{VolSet__volset_Backup_Summary} = "BackupAFS: VolumeSet \$volset Backup Summary";

$Lang{VolSet__volset_Backup_Summary2} = <<EOF;
\${h1("VolumeSet &quot;\$volset&quot; Backup Summary")}
<p>
\$warnStr
<ul>
\$statusStr
</ul>
</p>
\${h2("User Actions")}
<p>
<form name="StartStopForm" action="\$MyURL" method="get">
<input type="hidden" name="volset"   value="\$volset">
<input type="hidden" name="action" value="">
\$startIncrStr
<input type="button" value="\$Lang->{Start_Full_Backup}"
 onClick="document.StartStopForm.action.value='Start_Full_Backup';
          document.StartStopForm.submit();">
<input type="button" value="\$Lang->{Stop_Dequeue_Backup}"
 onClick="document.StartStopForm.action.value='Stop_Dequeue_Backup';
          document.StartStopForm.submit();">
</form>
</p>
\${h2("Backup Summary")}
<p>
Click on the backup number to browse and restore backup files.
</p>
<table class="sortable" id="Backup_Summary" border cellspacing="1" cellpadding="3">
<tr class="tableheader"><td align="center"> Backup# </td>
    <td align="center"> Type </td>
    <td align="center"> Level </td>
    <td align="center"> Start Date </td>
    <td align="center"> Duration/mins </td>
    <td align="center"> Age/days </td>
    <td align="center"> VolumeSet Backup Directory on Server </td>
</tr>
\$str
</table>
<p>

\$restoreStr
</p>
<br><br>
\${h2("Xfer Error Summary")}
<br><br>
<table class="sortable" id="Xfer_Error_Summary" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td align="center"> Backup# </td>
    <td align="center"> Type </td>
    <td align="center"> View </td>
    <td align="center"> #Xfer errs </td>
    <td align="center"> #bad files </td>
    <td align="center"> #bad share </td>
</tr>
\$errStr
</table>
<br><br>

\${h2("File Size, Count, &amp; Compression Summary")}
<p>
Empty files and errors aren\'t included in the new counts.
</p>
<table class="sortable" id="test" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader">
    <td align="center"> Backup# </td>
    <td align="center"> Type </td>
    <td align="center"> Total # Files </td>
    <td align="center"> Backup Speed [MB/sec] </td>
    <td align="center"> Comp Level </td>
    <td align="center"> Original Size [GB] </td>
    <td align="center"> Comp Size [GB] </td>
    <td align="center"> Comp [%saved] </td>
</tr>
\$sizeStr
</table>
<br><br>
EOF

$Lang{VolSet__volset_Archive_Summary} = "BackupAFS: VolumeSet \$volset Archive Summary";
$Lang{VolSet__volset_Archive_Summary2} = <<EOF;
\${h1("VolumeSet \$volset Archive Summary")}
<p>
\$warnStr
<ul>
\$statusStr
</ul>

\${h2("User Actions")}
<p>
<form name="StartStopForm" action="\$MyURL" method="get">
<input type="hidden" name="archivevolset" value="\$volset">
<input type="hidden" name="volset" value="\$volset">
<input type="hidden" name="action" value="">
<input type="button" value="\$Lang->{Start_Archive}"
 onClick="document.StartStopForm.action.value='Start_Archive';
          document.StartStopForm.submit();">
<input type="button" value="\$Lang->{Stop_Dequeue_Archive}"
 onClick="document.StartStopForm.action.value='Stop_Dequeue_Archive';
          document.StartStopForm.submit();">
</form>

\$ArchiveStr

EOF

# -------------------------
$Lang{Error} = "BackupAFS: Error";
$Lang{Error____head} = <<EOF;
\${h1("Error: \$head")}
<p>\$mesg</p>
EOF

# -------------------------
$Lang{NavSectionTitle_} = "Server";

# -------------------------
$Lang{Backup_browse_for__volset} = <<EOF;
\${h1("Backup browse for \$volset")}

<script language="javascript" type="text/javascript">
<!--

    function checkAll(location)
    {
      for (var i=0;i<document.form1.elements.length;i++)
      {
        var e = document.form1.elements[i];
        if ((e.checked || !e.checked) && e.name != \'all\') {
            if (eval("document.form1."+location+".checked")) {
            	e.checked = true;
            } else {
            	e.checked = false;
            }
        }
      }
    }
    
    function toggleThis(checkbox)
    {
       var cb = eval("document.form1."+checkbox);
       cb.checked = !cb.checked;	
    }

//-->
</script>

<form name="form0" method="post" action="\$MyURL">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="volset" value="\$volset">
<input type="hidden" name="share" value="\${EscHTML(\$share)}">
<input type="hidden" name="action" value="browse">
You are browsing backup #\$num, which started around \$backupTime
        (\$backupAge days ago).<br><br>
You may:
<ul>
<li> Click on a volume name below to navigate into that volume\'s directory,
<li> Click on the name of a file (.vdmp or .vdmp.gz) to download that file via your browser,
<li> Type a volume name backed up by this VolumeSet to go directly to the specified volume\'s directory\: <input type="text" name="dir" size="50" maxlength="4096" value=""> <input type="submit" value="\$Lang->{Go}" name="Submit">
<li> Select one or more volumes (using the checkboxes below) to restore that volume(s) from this backup,
\$filledBackup
<li> View the backup <a href="\$MyURL?action=dirHistory&volset=\${EscURI(\$volset)}&share=\$shareURI&dir=\$pathURI">history</a> of volumes within the current VolumeSet,
<li> Do something else entirely using the navigation to the left.
</ul>
</form>

\${h2("Contents of \${EscHTML(\$TopDir)}/volsets/\${EscHTML(\$volset)}/\${EscHTML(\$Backups\[\$i\]\{num\})}/\${EscHTML(\$dirDisplay)}   ")}

<form name="form1" method="post" action="\$MyURL">
<input type="hidden" name="num" value="\$num">
<input type="hidden" name="volset" value="\$volset">
<input type="hidden" name="share" value="\${EscHTML(\$share)}">
<input type="hidden" name="fcbMax" value="\$checkBoxCnt">
<input type="hidden" name="action" value="Restore">
<br>
<table width="100%">
<tr><td valign="top" width="20%">
    <table align="left" border="0" cellpadding="0" cellspacing="0" bgcolor="#ffffff">
    \$dirStr
    </table>
</td><td width="3%">
</td><td valign="top">
    <br>
        <table border width="100%" align="left" cellpadding="3" cellspacing="1">
        \$fileHeader
        \$topCheckAll
        \$fileStr
        \$checkAll
        </table>
    </td></tr></table>
<br>
<!--
This is now in the checkAll row
<input type="submit" name="Submit" value="Restore selected files">
-->
</form>
EOF

# ------------------------------
$Lang{DirHistory_backup_for__volset} = "BackupAFS: Directory backup history for \$volset";

#
# These two strings are used to build the links for directories and
# file versions.  Files are appended with a version number.
#
$Lang{DirHistory_dirLink}  = "dir";
$Lang{DirHistory_fileLink} = "v";

$Lang{DirHistory_for__volset} = <<EOF;
\${h1("Directory backup history for \$volset")}
<p>
This display shows each unique version of files across all
the backups:
<ul>
<li> Click on a backup number to return to the backup browser,
<li> Click on a directory link (\$Lang->{DirHistory_dirLink}) to navigate
     into that directory,
<li> Click on a file version link (\$Lang->{DirHistory_fileLink}0,
     \$Lang->{DirHistory_fileLink}1, ...) to download that file,
<li> Files with the same contents between different backups have the same
     version number,
<li> Files or directories not present in a particular backup have an
     empty box.
<li> Files shown with the same version might have different attributes.
     Select the backup number to see the file attributes.
</ul>

\${h2("History of \${EscHTML(\$dirDisplay)}")}

<br>
<table border cellspacing="2" cellpadding="3">
<tr class="fviewheader"><td>Backup number</td>\$backupNumStr</tr>
<tr class="fviewheader"><td>Backup time</td>\$backupTimeStr</tr>
\$fileStr
</table>
EOF

# ------------------------------
$Lang{Restore___num_details_for__volset} = "BackupAFS: Restore #\$num details for \$volset";

$Lang{Restore___num_details_for__volset2} = <<EOF;
\${h1("Restore #\$num Details for \$volset")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="90%">
<tr><td class="tableheader"> Number </td><td class="border"> \$Restores[\$i]{num} </td></tr>
<tr><td class="tableheader"> Requested by </td><td class="border"> \$RestoreReq{user} </td></tr>
<tr><td class="tableheader"> Request time </td><td class="border"> \$reqTime </td></tr>
<tr><td class="tableheader"> Result </td><td class="border"> \$Restores[\$i]{result} </td></tr>
<tr><td class="tableheader"> Error Message </td><td class="border"> \$Restores[\$i]{errorMsg} </td></tr>
<tr><td class="tableheader"> Source VolumeSet </td><td class="border"> \$RestoreReq{volsetSrc} </td></tr>
<tr><td class="tableheader"> Source backup num </td><td class="border"> \$RestoreReq{num} </td></tr>
<tr><td class="tableheader"> Destination </td><td class="border"> \$RestoreReq{shareDest} </td></tr>
<tr><td class="tableheader"> Start time </td><td class="border"> \$startTime </td></tr>
<tr><td class="tableheader"> Duration </td><td class="border"> \$duration min </td></tr>
<tr><td class="tableheader"> Number of files </td><td class="border"> \$Restores[\$i]{nFiles} </td></tr>
<tr><td class="tableheader"> Total size </td><td class="border"> \${MB} MB </td></tr>
<tr><td class="tableheader"> Transfer rate </td><td class="border"> \$MBperSec MB/sec </td></tr>
<tr><td class="tableheader"> TarCreate errors </td><td class="border"> \$Restores[\$i]{tarCreateErrs} </td></tr>
<tr><td class="tableheader"> Xfer errors </td><td class="border"> \$Restores[\$i]{xferErrs} </td></tr>
<tr><td class="tableheader"> Xfer log file </td><td class="border">
<a href="\$MyURL?action=view&type=RestoreLOG&num=\$Restores[\$i]{num}&volset=\$volset">View</a>,
<a href="\$MyURL?action=view&type=RestoreErr&num=\$Restores[\$i]{num}&volset=\$volset">Errors</a>
</tr></tr>
</table>
</p>
\${h1("File/Directory list")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="100%">
<tr class="tableheader"><td>Original file/dir</td><td>Restored to</td></tr>
\$fileListStr
</table>
EOF

# ------------------------------
$Lang{Archive___num_details_for__volset} = "BackupAFS: Archive #\$num details for \$volset";

$Lang{Archive___num_details_for__volset2 } = <<EOF;
\${h1("Archive #\$num Details for \$volset")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr><td class="tableheader"> Number </td><td class="border"> \$Archives[\$i]{num} </td></tr>
<tr><td class="tableheader"> Requested by </td><td class="border"> \$ArchiveReq{user} </td></tr>
<tr><td class="tableheader"> Request time </td><td class="border"> \$reqTime </td></tr>
<tr><td class="tableheader"> Result </td><td class="border"> \$Archives[\$i]{result} </td></tr>
<tr><td class="tableheader"> Error Message </td><td class="border"> \$Archives[\$i]{errorMsg} </td></tr>
<tr><td class="tableheader"> Start time </td><td class="border"> \$startTime </td></tr>
<tr><td class="tableheader"> Duration </td><td class="border"> \$duration min </td></tr>
<tr><td class="tableheader"> Xfer log file </td><td class="border">
<a href="\$MyURL?action=view&type=ArchiveLOG&num=\$Archives[\$i]{num}&volset=\$volset">View</a>,
<a href="\$MyURL?action=view&type=ArchiveErr&num=\$Archives[\$i]{num}&volset=\$volset">Errors</a>
</tr></tr>
</table>
<p>
\${h1("VolumeSet list")}
<p>
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td>VolumeSet</td><td>Backup Number</td></tr>
\$VolSetListStr
</table>
EOF

# -----------------------------------
$Lang{Email_Summary} = "BackupAFS: Email Summary";

# -----------------------------------
#  !! ERROR messages !!
# -----------------------------------
$Lang{BackupAFS__Lib__new_failed__check_apache_error_log} = "BackupAFS::Lib->new failed: check apache error_log\n";
$Lang{Wrong_user__my_userid_is___} =  
              "Wrong user: my userid is \$>, instead of \$uid"
            . "(\$Conf{BackupAFSUser})\n";
# $Lang{Only_privileged_users_can_view_PC_summaries} = "Only privileged users can view PC summaries.";
$Lang{Only_privileged_users_can_stop_or_start_backups} = 
                  "Only privileged users can stop or start backups on"
		. " \${EscHTML(\$volset)}.";
$Lang{Invalid_number__num} = "Invalid number \$num";
$Lang{Unable_to_open__file__configuration_problem} = "Unable to open \$file: configuration problem?";
$Lang{Only_privileged_users_can_view_log_or_config_files} = "Only privileged users can view log or config files.";
$Lang{Only_privileged_users_can_view_log_files} = "Only privileged users can view log files.";
$Lang{Only_privileged_users_can_view_email_summaries} = "Only privileged users can view email summaries.";
$Lang{Only_privileged_users_can_browse_backup_files} = "Only privileged users can browse backup files"
                . " for volset \${EscHTML(\$In{volset})}.";
$Lang{Empty_volset_name} = "Empty volset name.";
$Lang{Directory___EscHTML} = "Directory \${EscHTML(\"\$TopDir/volsets/\$volset/\$num\")}"
		    . " is empty";
$Lang{Can_t_browse_bad_directory_name2} = "Can\'t browse bad directory name"
	            . " \${EscHTML(\$relDir)}";
$Lang{Only_privileged_users_can_restore_backup_files} = "Only privileged users can restore backup files"
                . " for volset \${EscHTML(\$In{volset})}.";
$Lang{Bad_volset_name} = "Bad volset name \${EscHTML(\$volset)}";
$Lang{You_haven_t_selected_any_files__please_go_Back_to} = "You haven\'t selected any files; please go Back to"
                . " select some files.";
$Lang{You_haven_t_selected_any_volsets} = "You haven\'t selected any volsets; please go Back to"
                . " select some volsets.";
$Lang{Nice_try__but_you_can_t_put} = "Nice try, but you can\'t put \'..\' in any of the file names";
$Lang{VolSet__doesn_t_exist} = "VolumeSet \${EscHTML(\$In{volsetDest})} doesn\'t exist";
$Lang{You_don_t_have_permission_to_restore_onto_volset} = "You don\'t have permission to restore onto volset"
		    . " \${EscHTML(\$In{volsetDest})}";
$Lang{Can_t_open_create__openPath} = "Can\'t open/create "
		. "\${EscHTML(\"\$openPath\")}";
$Lang{Only_privileged_users_can_restore_backup_files2} = "Only privileged users can restore backup files"
                . " for volset \${EscHTML(\$volset)}.";
$Lang{Empty_volset_name} = "Empty volset name";
$Lang{Unknown_volset_or_user} = "Unknown volset or user \${EscHTML(\$volset)}";
$Lang{Only_privileged_users_can_view_information_about} = "Only privileged users can view information about"
                . " volset \${EscHTML(\$volset)}." ;
$Lang{Only_privileged_users_can_view_archive_information} = "Only privileged users can view archive information.";
$Lang{Only_privileged_users_can_view_restore_information} = "Only privileged users can view restore information.";
$Lang{Restore_number__num_for_volset__does_not_exist} = "Restore number \$num for volset \${EscHTML(\$volset)} does"
	        . " not exist.";
$Lang{Archive_number__num_for_volset__does_not_exist} = "Archive number \$num for volset \${EscHTML(\$volset)} does"
                . " not exist.";
$Lang{Can_t_find_IP_address_for} = "Can\'t find IP address for \${EscHTML(\$volset)}";
$Lang{volset_is_a_DHCP_volset} = <<EOF;
\$volset is a DHCP volset, and I don\'t know its IP address.  I checked the
netbios name of \$ENV{REMOTE_ADDR}\$tryIP, and found that that machine
is not \$volset.
<p>
Until I see \$volset at a particular DHCP address, you can only
start this request from the client machine itself.
EOF

# ------------------------------------
# !! Server Mesg !!
# ------------------------------------

$Lang{Backup_requested_on_DHCP__volset} = "Backup requested on DHCP \$volset (\$In{volsetIP}) by"
		                      . " \$User from \$ENV{REMOTE_ADDR}";
$Lang{Backup_requested_on__volset_by__User} = "Backup requested on \$volset by \$User";
$Lang{Backup_stopped_dequeued_on__volset_by__User} = "Backup stopped/dequeued on \$volset by \$User";
$Lang{Restore_requested_to_volset__volsetDest__backup___num} = "Restore requested to volset \$volsetDest, backup #\$num,"
	     . " by \$User from \$ENV{REMOTE_ADDR}";
$Lang{Archive_requested} = "Archive requested by \$User from \$ENV{REMOTE_ADDR}";

# -------------------------------------------------
# ------- Stuff that was forgotten ----------------
# -------------------------------------------------

$Lang{Status} = "Status";
$Lang{PC_Summary} = "VolumeSet Summary";
$Lang{VolumeSet_LOG_file} = "VolumeSet LOG file";
$Lang{VolumeSet_LOG_files} = "Older VolumeSet LOG files";
$Lang{Server_LOG_file} = "Server LOG file";
$Lang{Server_LOG_files} = "Older Server LOG files";
$Lang{Email_summary} = "Email summary";
$Lang{Config_file} = "Config file";
# $Lang{VolSets_file} = "VolSets file";
$Lang{Current_queues} = "Current queues";
$Lang{Documentation} = "Documentation";

#$Lang{VolSet_or_User_name} = "<small>VolSet or User name:</small>";
$Lang{Go} = "Go";
$Lang{VolSets} = "VolumeSets";
$Lang{Select_a_volset} = "Select a VolumeSet...";

$Lang{There_have_been_no_archives} = "<h2> There have been no archives </h2>\n";
$Lang{This_PC_has_never_been_backed_up} = "<h2> This VolumeSet has never been backed up!! </h2>\n";
$Lang{This_PC_is_used_by} = "<li>This VolumeSet includes volumes used by \${UserLink(\$user)}";

$Lang{Extracting_only_Errors} = "(Extracting only Errors)";
$Lang{XferLOG} = "XferLOG";
$Lang{Errors}  = "Errors";

# ------------
$Lang{Last_email_sent_to__was_at___subject} = <<EOF;
<li>Last email sent to \${UserLink(\$user)} was at \$mailTime, subject "\$subj".
EOF
# ------------
$Lang{The_command_cmd_is_currently_running_for_started} = <<EOF;
<li>The command \$cmd is currently running for \$volset, started \$startTime.
EOF

# -----------
$Lang{VolSet_volset_is_queued_on_the_background_queue_will_be_backed_up_soon} = <<EOF;
<li>VolumeSet \$volset is queued on the background queue (will be backed up soon).
EOF

# ----------
$Lang{VolSet_volset_is_queued_on_the_user_queue__will_be_backed_up_soon} = <<EOF;
<li>VolumeSet \$volset is queued on the user queue (will be backed up soon).
EOF

# ---------
$Lang{A_command_for_volset_is_on_the_command_queue_will_run_soon} = <<EOF;
<li>A command for \$volset is on the command queue (will run soon).
EOF

# --------
$Lang{Last_status_is_state_StatusVolSet_state_reason_as_of_startTime} = <<EOF;
<li>Last status is state \"\$Lang->{\$StatusVolSet{state}}\"\$reason as of \$startTime.
EOF

# --------
$Lang{Last_error_is____EscHTML_StatusVolSet_error} = <<EOF;
<li>Last error is \"\${EscHTML(\$StatusVolSet{error})}\".
EOF

# ------
$Lang{Pings_to_volset_have_failed_StatusVolSet_deadCnt__consecutive_times} = <<EOF;
<li>Pings to \$volset have failed \$StatusVolSet{deadCnt} consecutive times.
EOF

# -----
$Lang{Prior_to_that__pings} = "Prior to that, pings";

# -----
$Lang{priorStr_to_volset_have_succeeded_StatusVolSetaliveCnt_consecutive_times} = <<EOF;
<li>\$priorStr to \$volset have succeeded \$StatusVolSet{aliveCnt}
        consecutive times.
EOF

$Lang{Because__volset_has_been} = <<EOF;
<li>\$volset will not be backed up from \$blackoutStr.
EOF

$Lang{__time0_to__time1_on__days} = "\$t0 to \$t1 on \$days";

$Lang{Backups_are_deferred_for_hours_hours_change_this_number} = <<EOF;
<li>Backups are deferred for \$hours hours
(<a href=\"\$MyURL?action=Stop_Dequeue_Backup&volset=\$volset\">change this number</a>).
EOF

$Lang{tryIP} = " and \$StatusVolSet{dhcpVolSetIP}";

# $Lang{VolSet_Involset} = "VolSet \$In{volset}";

$Lang{checkAll} = <<EOF;
<tr><td class="fviewborder">
<input type="checkbox" name="allFiles" onClick="return checkAll('allFiles');">&nbsp;Select all
</td><td colspan="5" align="center" class="fviewborder">
<input type="submit" name="Submit" value="Restore selected files">
</td></tr>
EOF

$Lang{checkAllVolSets} = <<EOF;
<tr><td class="fviewborder">
<input type="checkbox" name="allFiles" onClick="return checkAll('allFiles');">&nbsp;Select all
</td><td colspan="2" align="center" class="fviewborder">
<input type="submit" name="Submit" value="Archive selected volsets">
</td></tr>
EOF

$Lang{fileHeader} = <<EOF;
    <tr class="fviewheader"><td align=center> Name</td>
       <td align="center"> Type</td>
       <td align="center"> #</td>
       <td align="center"> Size</td>
       <td align="center"> Date modified</td>
    </tr>
EOF

$Lang{Home} = "Home";
$Lang{Browse} = "Browse backups";
$Lang{Last_bad_XferLOG} = "Last bad XferLOG";
$Lang{Last_bad_XferLOG_errors_only} = "Last bad XferLOG (errors&nbsp;only)";

$Lang{This_display_is_merged_with_backup} = <<EOF;
<li> This display is merged with backup #\$numF.
EOF

$Lang{Visit_this_directory_in_backup} = <<EOF;
<li> Select a different backup of this VolumeSet to view: <select onChange="window.location=this.value">\$otherDirs </select>
EOF

$Lang{Restore_Summary} = <<EOF;
\${h2("Restore Summary")}
<p>
Click on the restore number for more details.
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td align="center"> Restore# </td>
    <td align="center"> Result </td>
    <td align="right"> Start Date</td>
    <td align="right"> Duration [mins] </td>
    <td align="right"> #files </td>
    <td align="right"> Size [GB] </td>
    <td align="right"> #tar errs </td>
    <td align="right"> #xferErrs </td>
</tr>
\$restoreStr
</table>
<p>
EOF

$Lang{Archive_Summary} = <<EOF;
\${h2("Archive Summary")}
<p>
Click on the archive number for more details.
<table class="tableStnd" border cellspacing="1" cellpadding="3" width="80%">
<tr class="tableheader"><td align="center"> Archive# </td>
    <td align="center"> Result </td>
    <td align="right"> Start Date</td>
    <td align="right"> Dur/mins</td>
</tr>
\$ArchiveStr
</table>
<p>
EOF

$Lang{BackupAFS__Documentation} = "BackupAFS: Documentation";

$Lang{No} = "no";
$Lang{Yes} = "yes";

$Lang{The_directory_is_empty} = <<EOF;
<tr><td bgcolor="#ffffff">The directory \${EscHTML(\$dirDisplay)} is empty
</td></tr>
EOF

#$Lang{on} = "on";
$Lang{off} = "off";

$Lang{backupType_full}    = "full";
$Lang{backupType_incr}    = "incr";
$Lang{backupType_partial} = "partial";

$Lang{failed} = "failed";
$Lang{success} = "success";
$Lang{and} = "and";

# ------
# VolSets states and reasons
$Lang{Status_idle} = "idle";
$Lang{Status_backup_starting} = "backup starting";
$Lang{Status_backup_in_progress} = "backup in progress";
$Lang{Status_restore_starting} = "restore starting";
$Lang{Status_restore_in_progress} = "restore in progress";
$Lang{Status_compress_pending} = "compress pending";
$Lang{Status_compress_running} = "compress running";

$Lang{Reason_backup_done}    = "done";
$Lang{Reason_restore_done}   = "restore done";
$Lang{Reason_archive_done}   = "archive done";
$Lang{Reason_nothing_to_do}  = "idle";
$Lang{Reason_backup_failed}  = "backup failed";
$Lang{Reason_restore_failed} = "restore failed";
$Lang{Reason_archive_failed} = "archive failed";
$Lang{Reason_no_ping}        = "no ping";
$Lang{Reason_backup_canceled_by_user}  = "backup canceled by user";
$Lang{Reason_restore_canceled_by_user} = "restore canceled by user";
$Lang{Reason_archive_canceled_by_user} = "archive canceled by user";
$Lang{Disabled_OnlyManualBackups}  = "auto disabled";  
$Lang{Disabled_AllBackupsDisabled} = "disabled";                  


# ---------
# Email messages

# No backup ever
$Lang{EMailNoBackupEverSubj} = "BackupAFS: no backups of \$volset have succeeded";
$Lang{EMailNoBackupEverMesg} = <<'EOF';
To: $user$domain
cc:
Subject: $subj
$headers
Dear $userName,

Your AFS VolumeSet ($volset) has never been successfully backed up by our
AFS backup software.  AFS backups should occur automatically
on the schedule established by your systems administrator. You
should contact your systems administrator or computer support
staff if this is unexpected.

Otherwise, please make sure your PC is connected to the network
next time you are in the office.

Regards,
BackupAFS Genie
http://backupafs.sourceforge.net
EOF

# No recent backup
$Lang{EMailNoBackupRecentSubj} = "BackupAFS: no recent backups on \$volset";
$Lang{EMailNoBackupRecentMesg} = <<'EOF';
To: $user$domain
cc:
Subject: $subj
$headers
Dear $userName,

Your PC ($volset) has not been successfully backed up for $days days.
Your PC has been correctly backed up $numBackups times from $firstTime to $days days
ago.  PC backups should occur automatically when your PC is connected
to the network.

If your PC has been connected for more than a few hours to the
network during the last $days days you should contact IS to find
out why backups are not working.

Otherwise, if you are out of the office, there's not much you can
do, other than manually copying especially critical files to other
media.  You should be aware that any files you have created or
changed in the last $days days (including all new email and
attachments) cannot be restored if your PC disk crashes.

Regards,
BackupAFS Genie
http://backupafs.sourceforge.net
EOF

$Lang{howLong_not_been_backed_up} = "not been backed up successfully";
$Lang{howLong_not_been_backed_up_for_days_days} = "not been backed up for \$days days";

#######################################################################
# RSS strings
#######################################################################
$Lang{RSS_Doc_Title}       = "BackupAFS Server";
$Lang{RSS_Doc_Description} = "RSS feed for BackupAFS";
$Lang{RSS_VolSet_Summary}    = <<EOF;
Full Count: \$fullCnt;
Full Age/days: \$fullAge;
Full Size/GB: \$fullSize;
Speed MB/sec: \$fullRate;
Incr Count: \$incrCnt;
Incr Age/Days: \$incrAge;
State: \$volset_state;
Last Attempt: \$volset_last_attempt;
EOF

#######################################################################
# Configuration editor strings
#######################################################################

$Lang{Only_privileged_users_can_edit_config_files} = "Only privileged users can edit configuation settings.";
$Lang{CfgEdit_Edit_Server_Config} = "Edit Server Config";
$Lang{CfgEdit_Edit_VS_Config} = "Edit VolumeSet Config";
$Lang{CfgEdit_Edit_VolSets}  = "Edit Volumesets";

$Lang{CfgEdit_Title_Server} = "Server";
$Lang{CfgEdit_Title_General_Parameters} = "General Parameters";
$Lang{CfgEdit_Title_Wakeup_Schedule} = "Wakeup Schedule";
$Lang{CfgEdit_Title_Concurrent_Jobs} = "Concurrent Jobs";
$Lang{CfgEdit_Title_Pool_Filesystem_Limits} = "Backup Filesystem Limits";
$Lang{CfgEdit_Title_Other_Parameters} = "Other Parameters";
$Lang{CfgEdit_Title_Remote_Apache_Settings} = "Remote Apache Settings";
$Lang{CfgEdit_Title_Program_Paths} = "Program Paths";
$Lang{CfgEdit_Title_Install_Paths} = "Install Paths";
$Lang{CfgEdit_Title_Email} = "Email";
$Lang{CfgEdit_Title_Email_settings} = "Email settings";
$Lang{CfgEdit_Title_Email_User_Messages} = "Email User Messages";
$Lang{CfgEdit_Title_CGI} = "CGI";
$Lang{CfgEdit_Title_Admin_Privileges} = "Admin Privileges";
$Lang{CfgEdit_Title_Page_Rendering} = "Page Rendering";
$Lang{CfgEdit_Title_Paths} = "Paths";
$Lang{CfgEdit_Title_User_URLs} = "User URLs";
$Lang{CfgEdit_Title_User_Config_Editing} = "User Config Editing";
$Lang{CfgEdit_Title_Xfer} = "Xfer";
$Lang{CfgEdit_Title_Xfer_Settings} = "Xfer Settings";
$Lang{CfgEdit_Title_Ftp_Settings} = "FTP Settings";
$Lang{CfgEdit_Title_Smb_Settings} = "Smb Settings";
$Lang{CfgEdit_Title_Tar_Settings} = "Tar Settings";
$Lang{CfgEdit_Title_Rsync_Settings} = "Rsync Settings";
$Lang{CfgEdit_Title_Rsyncd_Settings} = "Rsyncd Settings";
$Lang{CfgEdit_Title_Archive_Settings} = "Archive Settings";
$Lang{CfgEdit_Title_Include_Exclude} = "Include/Exclude";
$Lang{CfgEdit_Title_Smb_Paths_Commands} = "Smb Paths/Commands";
$Lang{CfgEdit_Title_Tar_Paths_Commands} = "Tar Paths/Commands";
$Lang{CfgEdit_Title_Rsync_Paths_Commands_Args} = "Rsync Paths/Commands/Args";
$Lang{CfgEdit_Title_Rsyncd_Port_Args} = "Rsyncd Port/Args";
$Lang{CfgEdit_Title_Archive_Paths_Commands} = "Archive Paths/Commands";
$Lang{CfgEdit_Title_Schedule} = "Schedule";
$Lang{CfgEdit_Title_Full_Backups} = "Full Backups";
$Lang{CfgEdit_Title_Incremental_Backups} = "Incremental Backups";
$Lang{CfgEdit_Title_Blackouts} = "Blackouts";
$Lang{CfgEdit_Title_Other} = "Other";
$Lang{CfgEdit_Title_Backup_Settings} = "Backup Settings";
$Lang{CfgEdit_Title_Client_Lookup} = "Ping Options";
$Lang{CfgEdit_Title_Other} = "Other";
$Lang{CfgEdit_Title_User_Commands} = "User Commands";
$Lang{CfgEdit_Title_VolSets} = "VolumeSet Definitions";

$Lang{CfgEdit_VolSets_Comment} = <<EOF;
To add a new VolumeSet, select <b>Add</b> and then enter the name and volume-matching criteria.<br>
To delete a VolumeSet, hit the <b>Delete</b> button.<br>For Add, Delete,
and configuration copy, changes don't take effect until you select
<b>Save</b>.<br>When deleting a Volumeset, none of the deleted VolumeSet's backups will actually be removed,
so if you accidently delete a VolumeSet, simply re-add it.  To completely
remove a VolumeSet's backups, you need to manually remove the files
below \$topDir/volsets/<i>VOLUMESETname</i>.
EOF

$Lang{CfgEdit_Header_Main} = <<EOF;
\${h1("Main Configuration Editor")}
EOF

$Lang{CfgEdit_Header_VolSet} = <<EOF;
\${h1("VolumeSet \$volset Configuration Editor")}
<p>
Note: Check Override if you want to modify a value specific to this VolumeSet.
<p>
EOF

$Lang{CfgEdit_Button_Save}     = "Save";
$Lang{CfgEdit_Button_Insert}   = "Insert";
$Lang{CfgEdit_Button_Delete}   = "Delete";
$Lang{CfgEdit_Button_Add}      = "Add";
$Lang{CfgEdit_Button_Override} = "Override";
$Lang{CfgEdit_Button_New_Key}  = "New Key";

$Lang{CfgEdit_Error_No_Save}
            = "Error: No save due to errors";
$Lang{CfgEdit_Error__must_be_an_integer}
            = "Error: \$var must be an integer";
$Lang{CfgEdit_Error__must_be_real_valued_number}
            = "Error: \$var must be a real-valued number";
$Lang{CfgEdit_Error__entry__must_be_an_integer}
            = "Error: \$var entry \$k must be an integer";
$Lang{CfgEdit_Error__entry__must_be_real_valued_number}
            = "Error: \$var entry \$k must be a real-valued number";
$Lang{CfgEdit_Error__must_be_executable_program}
            = "Error: \$var must be a valid executable path";
$Lang{CfgEdit_Error__must_be_valid_option}
            = "Error: \$var must be a valid option";
$Lang{CfgEdit_Error_Copy_volset_does_not_exist}
            = "Copy VolumeSet \$copyVolSet doesn't exist; creating new VolumeSet with name \$fullVolSet.  Delete this volset if that is not what you wanted.";

$Lang{CfgEdit_Log_Copy_volset_config}
            = "\$User copied config from VolumeSet \$fromVolSet to \$volset\n";
$Lang{CfgEdit_Log_Delete_param}
            = "\$User deleted \$p from \$conf\n";
$Lang{CfgEdit_Log_Add_param_value}
            = "\$User added \$p to \$conf, set to \$value\n";
$Lang{CfgEdit_Log_Change_param_value}
            = "\$User changed \$p in \$conf to \$valueNew from \$valueOld\n";
$Lang{CfgEdit_Log_VolSet_Delete}
            = "\$User deleted VolumeSet \$volset\n";
$Lang{CfgEdit_Log_VolSet_Change}
            = "\$User VolumeSet \$volset changed \$key from \$valueOld to \$valueNew\n";
$Lang{CfgEdit_Log_VolSet_Add}
            = "\$User added VolumeSet \$volset: \$value\n";
  
#end of lang_en.pm
