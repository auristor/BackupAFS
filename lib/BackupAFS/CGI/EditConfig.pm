#============================================================= -*-perl-*-
#
# BackupAFS::CGI::EditConfig package
#
# DESCRIPTION
#
#   This module implements the EditConfig action for the CGI interface.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2005-2009  Craig Barratt
#   Copyright (C) 2010 Stephen Joyce
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 3 ONLY.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#========================================================================
#
# Version 1.0.0, released 22 Nov 2010.
#
# See http://backupafs.sourceforge.net.
#
#========================================================================

package BackupAFS::CGI::EditConfig;

use strict;
use BackupAFS::CGI::Lib qw(:all);
use BackupAFS::Config::Meta qw(:all);
use BackupAFS::Storage;
use Data::Dumper;
use Encode;

our %ConfigMenu = (
    server => {
        text  => "CfgEdit_Title_Server",
        param => [
            {text => "CfgEdit_Title_General_Parameters"},
            {name => "ServerHost"},
            {name => "BackupAFSUser"},
            {name => "BackupAFSUserVerify"},
            {name => "MaxOldLogFiles"},
            {name => "TrashCleanSleepSec"},

            {text => "CfgEdit_Title_Wakeup_Schedule"},
            {name => "WakeupSchedule"},

            {text => "CfgEdit_Title_Concurrent_Jobs"},
            {name => "MaxBackups"},
            {name => "MaxUserBackups"},
            {name => "MaxPendingCmds"},
            {name => "MaxBackupAFSNightlyJobs"},
            {name => "BackupAFSNightlyPeriod"},

            {text => "CfgEdit_Title_Pool_Filesystem_Limits"},
	    {name => "DfCmd"},
	    {name => "DfMaxUsagePct"},

            {text => "CfgEdit_Title_Other_Parameters"},
	    {name => "UmaskMode"},
	    {name => "MyPath"},
            {name => "CmdQueueNice"},
            {name => "PerlModuleLoad"},
            {name => "ServerInitdPath"},
            {name => "ServerInitdStartCmd"},

            {text => "CfgEdit_Title_Remote_Apache_Settings"},
            {name => "ServerPort"},
            {name => "ServerMesgSecret"},

            {text => "CfgEdit_Title_Program_Paths"},
	    {name => "AfsVosPath"},
	    {name => "AfsVosBackupArgs"},
	    {name => "AfsVosRestoreArgs"},
	    {name => "SshPath"},
	    {name => "PingPath"},
	    {name => "DfPath"},
	    {name => "CatPath"},
	    {name => "GzipPath"},
	    {name => "PigzPath"},
	    {name => "PigzThreads"},

            {text => "CfgEdit_Title_Install_Paths"},
            #
            # Can only edit TopDir and LogDir if we are in FHS mode.
            # Otherwise they are hardcoded in lib/BackupAFS/Lib.pm.
            #
            {name => "TopDir",
                    visible => sub { return $_[1]->useFHS(); } },
            {name => "LogDir",
                    visible => sub { return $_[1]->useFHS(); } },
	    {name => "CgiDir"},
            #
            # Cannot edit ConfDir or InstallDir, since the real value is hardcoded in
            # lib/BackupAFS/Lib.pm.
            # {name => "ConfDir"},
	    # {name => "InstallDir"},
            #
        ],
    },
    email => {
        text  => "CfgEdit_Title_Email",
        param => [
            {text => "CfgEdit_Title_Email_settings"},
            {name => "SendmailPath"},
            {name => "EMailNotifyMinDays"},
            {name => "EMailFromUserName"},
            {name => "EMailAdminUserName"},
            {name => "EMailUserDestDomain"},

            {text => "CfgEdit_Title_Email_User_Messages"},
	    {name => "EMailNoBackupEverSubj"},
	    {name => "EMailNoBackupEverMesg"},
	    {name => "EMailNotifyOldBackupDays"},
	    {name => "EMailNoBackupRecentSubj"},
	    {name => "EMailNoBackupRecentMesg"},
	    {name => "EMailHeaders"},
        ],
    },
    cgi => {
        text => "CfgEdit_Title_CGI",
        param => [
	    {text => "CfgEdit_Title_Admin_Privileges"},
	    {name => "CgiAdminUserGroup"},
	    {name => "CgiAdminUsers"},

	    {text => "CfgEdit_Title_Page_Rendering"},
	    {name => "Language"},
	    {name => "CgiNavBarAdminAllVolSets"},
	    {name => "CgiSearchBoxEnable"},
	    {name => "CgiNavBarLinks"},
	    {name => "CgiStatusHilightColor"},
	    {name => "CgiDateFormatMMDD"},
	    {name => "CgiHeaders"},
	    {name => "CgiExt2ContentType"},
	    {name => "CgiCSSFile"},

	    {text => "CfgEdit_Title_Paths"},
	    {name => "CgiURL"},
	    {name => "CgiImageDir"},
	    {name => "CgiImageDirURL"},

	    {text => "CfgEdit_Title_User_URLs"},
	    {name => "CgiUserHomePageCheck"},
	    {name => "CgiUserUrlCreate"},

	    {text => "CfgEdit_Title_User_Config_Editing"},
	    {name => "CgiUserConfigEditEnable"},
	    {name => "CgiUserConfigEdit"},
        ],
    },
    xfer => {
        text => "CfgEdit_Title_Xfer",
        param => [
            {text => "CfgEdit_Title_Xfer_Settings"},
            {name => "XferMethod", onchangeSubmit => 1},
            {name => "XferLogLevel"},
            {name => "ClientCharset"},
            {name => "ClientCharsetLegacy"},
        ],
    },
    schedule => {
        text => "CfgEdit_Title_Schedule",
        param => [
	    {text => "CfgEdit_Title_Full_Backups"},
	    {name => "FullPeriod"},
	    {name => "FullKeepCnt"},
	    {name => "FullKeepCntMin"},
	    {name => "FullAgeMax"},

	    {text => "CfgEdit_Title_Incremental_Backups"},
	    {name => "IncrPeriod"},
	    {name => "IncrKeepCnt"},
	    {name => "IncrKeepCntMin"},
	    {name => "IncrAgeMax"},
	    {name => "IncrLevels"},

	    {text => "CfgEdit_Title_Blackouts"},
            {name => "BackupsDisable"},
            {name => "BlackoutPeriods"},

	    {text => "CfgEdit_Title_Other"},
	    {name => "RestoreInfoKeepCnt"},
	    {name => "BackupZeroFilesIsFatal"},
	],
    },
    backup => {
        text => "CfgEdit_Title_Backup_Settings",
        param => [
	    {text => "CfgEdit_Title_Client_Lookup"},
	    {name => "PingCmd"},
	    {name => "PingMaxMsec"},
	    
	    {text => "CfgEdit_Title_Other"},
	    {name => "ClientTimeout"},
	    {name => "MaxOldPerPCLogFiles"},
	    {name => "CompressLevel"},

	    {text => "CfgEdit_Title_User_Commands"},
	    {name => "DumpPreUserCmd"},
	    {name => "DumpPostUserCmd"},
	    {name => "DumpPreShareCmd"},
	    {name => "DumpPostShareCmd"},
	    {name => "RestorePreUserCmd"},
	    {name => "RestorePostUserCmd"},
	    {name => "UserCmdCheckStatus"},
	],
    },
    volsets => {
        text => "CfgEdit_Title_VolSets",
        param => [
	    {text    => "CfgEdit_Title_VolSets"},
	    {name    => "VolSets",
             comment => "CfgEdit_VolSets_Comment"},
        ],
    },
);

sub action
{
    my($content, $contentHidden, $newConf, $override, $mainConf, $volsetConf);
    my $errors = {};

    my $volset = $In{volset};
    my $menu = $In{menu} || "server";
    my $volsets_path = $VolSets;
    my $config_path = $volset eq "" ? "$TopDir/conf/config.pl"
                                  : "$TopDir/volsets/$volset/config.pl";

    my $Privileged = CheckPermission($volset)
                       && ($PrivAdmin || $Conf{CgiUserConfigEditEnable});
    my $userVolSet = 1 if ( defined($volset) );
    my $debugText;

    if ( !$Privileged ) {
        ErrorExit(eval("qq{$Lang->{Only_privileged_users_can_edit_config_files}}"));
    }

    if ( defined($In{menu}) || $In{saveAction} eq "Save" ) {
	$errors = errorCheck();
	if ( %$errors ) {
	    #
	    # If there are errors, then go back to the same menu
	    #
	    $In{saveAction} = "";
	}
        if ( (my $var = $In{overrideUncheck}) ne "" ) {
            #
            # a compound variable was unchecked; delete or
            # add extra variables to make the shape the same.
            #
            #print STDERR Dumper(\%In);
            foreach my $v ( keys(%In) ) {
                if ( $v =~ /^v_zZ_(\Q$var\E(_zZ_.*|$))/ ) {
                    delete($In{$v}) if ( !defined($In{"orig_zZ_$1"}) );
                }
                if ( $v =~ /^orig_zZ_(\Q$var\E(_zZ_.*|$))/ ) {
                    $In{"v_zZ_$1"} = $In{$v};
                }
            }
            delete($In{"vflds.$var"});
        }

        ($newConf, $override) = inputParse($bafs, $userVolSet);
	$override = undef if ( $volset eq "" );

    } else {
	#
	# First time: pick up the current config settings
	#
	$mainConf = $bafs->ConfigDataRead();
	if ( $volset ne "" ) {
	    $volsetConf = $bafs->ConfigDataRead($volset);
	    $override = {};
	    foreach my $param ( keys(%$volsetConf) ) {
		$override->{$param} = 1;
	    }
	} else {
            my $volsetInfo = $bafs->VolSetInfoRead();
	    $volsetConf = {};
            $mainConf->{VolSets} = [map($volsetInfo->{$_}, sort(keys(%$volsetInfo)))];
	}
	$newConf = { %$mainConf, %$volsetConf };
    }

    if ( $In{saveAction} ne "Save" && $In{newMenu} ne ""
		    && defined($ConfigMenu{$In{newMenu}}) ) {
        $menu = $In{newMenu};
    }

    my %menuDisable;
    if ( $userVolSet ) {
        #
        # For a non-admin user editing the volset config, we need to
        # figure out which subsets of the menu tree will be visible,
        # based on what is enabled.  Admin users can edit all the
        # available per-volset settings.
        #
        foreach my $m ( keys(%ConfigMenu) ) {
            my $enabled = 0;
            my $text = -1;
            my $n = 0;
            my @mask = ();

            foreach my $paramInfo ( @{$ConfigMenu{$m}{param}} ) {
                my $param = $paramInfo->{name};
                if ( defined($paramInfo->{text}) ) {
                    $text = $n;
                    $mask[$text] = 1;
                } else {
                    if ( $bafs->{Conf}{CgiUserConfigEdit}{$param}
                          || (defined($bafs->{Conf}{CgiUserConfigEdit}{$param})
                                && $PrivAdmin) ) {
                        $mask[$text] = 0 if ( $text >= 0 );
                        $mask[$n] = 0;
                        $enabled ||= 1;
                    } else {
                        $mask[$n] = 1;
                    }
                }
                $n++;
            }
            $menuDisable{$m}{mask} = \@mask;
            $menuDisable{$m}{top}  = !$enabled;
        }
        if ( $menuDisable{$menu}{top} ) {
            #
            # Find an enabled menu if the current menu is empty
            #
            foreach my $m ( sort(keys(%menuDisable)) ) {
                if ( !$menuDisable{$m}{top} ) {
                    $menu = $m;
                    last;
                }
            }
        }
    }

    my $groupText="<td>|</td>";
    foreach my $m ( keys(%ConfigMenu) ) {
        next if ( $menuDisable{$m}{top} );
	my $text = eval("qq($Lang->{$ConfigMenu{$m}{text}})");
        if ( $m eq $menu ) {
            $groupText .= <<EOF;
<td class="editTabSel" align="middle"><a href="javascript:menuSubmit('$m')"><b>$text</b></a></td><td>|</td>
EOF
        } else {
            $groupText .= <<EOF;
<td class="editTabNoSel" align="middle"><a href="javascript:menuSubmit('$m')">$text</a></td><td>|</td>
EOF
        }
    }

    if ( $volset eq "" ) {
	$content .= eval("qq($Lang->{CfgEdit_Header_Main})");
    } else {
	$content .= eval("qq($Lang->{CfgEdit_Header_VolSet})");
    }

    my $saveStyle = "";
    my $saveColor = "#ff0000";
    
    if ( $In{modified} && $In{saveAction} ne "Save" && !%$errors ) {
        $saveStyle = "style=\"color:$saveColor\"";
    } else {
        $In{modified} = 0;
    }

    #
    # Add action and volset to the URL so the nav bar link is
    # highlighted
    #
    my $url = "$MyURL?action=editConfig";
    $url .= "&volset=$volset" if ( $volset ne "" );
    $content .= <<EOF;
<table border="0" cellpadding="2">
<tr>$groupText</tr>
<tr>
<form method="post" name="editForm" action="$url">
<input type="hidden" name="volset" value="$volset">
<input type="hidden" name="menu" value="$menu">
<input type="hidden" name="newMenu" value="">
<input type="hidden" name="modified" value="$In{modified}">
<input type="hidden" name="deleteVar" value="">
<input type="hidden" name="insertVar" value="">
<input type="hidden" name="overrideUncheck" value="">
<input type="hidden" name="addVar" value="">
<input type="hidden" name="action" value="editConfig">
<input type="hidden" name="saveAction" value="">
<input type="button" class="editSaveButton" name="editAction"
    value="${EscHTML($Lang->{CfgEdit_Button_Save})}" $saveStyle
    onClick="saveSubmit();"> 
<p>

<script language="javascript" type="text/javascript">
<!--

    function saveSubmit()
    {
        if ( document.editForm.modified.value != 0 ) {
            document.editForm.saveAction.value = 'Save';
            document.editForm.submit();
        }
        return false;
    }

    function deleteSubmit(varName)
    {
        document.editForm.deleteVar.value = varName;
	document.editForm.modified.value = 1;
        document.editForm.submit();
        return;
    }

    function insertSubmit(varName)
    {
        document.editForm.insertVar.value = varName;
	document.editForm.modified.value = 1;
        document.editForm.submit();
        return;
    }

    function addSubmit(varName, checkKey)
    {
        if ( checkKey
            && eval("document.editForm.addVarKey_" + varName + ".value") == "" ) {
            alert("New key must be non-empty");
            return;
        }
        document.editForm.addVar.value = varName;
	document.editForm.modified.value = 1;
        document.editForm.submit();
        return;
    }

    function menuSubmit(menuName)
    {
        document.editForm.newMenu.value = menuName;
        document.editForm.submit();
    }

    function varChange(varName)
    {
	document.editForm.modified.value = 1;
        document.editForm.editAction.style.color = '$saveColor';
    }

    function checkboxChange(varName)
    {
	document.editForm.modified.value = 1;
        document.editForm.editAction.style.color = '$saveColor';
	// Do nothing if the checkbox is now set
        if ( eval("document.editForm.override_" + varName + ".checked") ) {
	    return false;
	}
	var allVars = {};
	var varRE  = new RegExp("^v_zZ_(" + varName + ".*)");
	var origRE = new RegExp("^orig_zZ_(" + varName + ".*)");
        for ( var i = 0 ; i < document.editForm.elements.length ; i++ ) {
	    var e = document.editForm.elements[i];
	    var re;
	    if ( (re = varRE.exec(e.name)) != null ) {
		if ( allVars[re[1]] == null ) {
		    allVars[re[1]] = 0;
		}
		allVars[re[1]]++;
		//debugMsg("found v_zZ_ match with " + re[1]);
		//debugMsg("allVars[" + re[1] + "] = " + allVars[re[1]]);
	    } else if ( (re = origRE.exec(e.name)) != null ) {
		if ( allVars[re[1]] == null ) {
		    allVars[re[1]] = 0;
		}
		allVars[re[1]]--;
		//debugMsg("allVars[" + re[1] + "] = " + allVars[re[1]]);
	    }
	}
	var sameShape = 1;
	for ( v in allVars ) {
	    if ( allVars[v] != 0 ) {
		//debugMsg("Not the same shape because of " + v);
		sameShape = 0;
	    } else {
                // copy the original variable values
		//debugMsg("setting " + v);
		eval("document.editForm.v_zZ_" + v + ".value = document.editForm.orig_zZ_" + v + ".value");
            }
	}
	if ( sameShape ) {
	    return true;
	} else {
            // need to rebuild the form since the compound variable
            // has changed shape
            document.editForm.overrideUncheck.value = varName;
	    document.editForm.submit();
	    return false;
	}
    }

    function checkboxSet(varName)
    {
	document.editForm.modified.value = 1;
        document.editForm.editAction.style.color = '$saveColor';
        eval("document.editForm.override_" + varName + ".checked = 1;");
        return false;
    }

    var debugCounter = 0;
    function debugMsg(msg)
    {
	debugCounter++;
	var t = document.createTextNode(debugCounter + ": " + msg);
	var br = document.createElement("br");
	var debug = document.getElementById("debug");
	debug.appendChild(t);
	debug.appendChild(br);
    }

    function displayHelp(varName)
    {
	var help = document.getElementById("id_" + varName);
	help.style.display = help.style.display == "block" ? "none" : "block";
    }

//-->
</script>

<span id="debug">$debugText</span>

EOF

    $content .= <<EOF;
<table border="1" cellspacing="0">
EOF

    my $doneParam = {};
    my $tblContent;

    #
    # There is a special case of the user deleting just the field
    # that has the error(s).  So if the delete variable is a match
    # or parent to all the errors then ignore the errors.
    #
    if ( $In{deleteVar} ne "" && %$errors > 0 ) {
        my $matchAll = 1;
        foreach my $v ( keys(%$errors) ) {
            if ( $v ne $In{deleteVar} && $v !~ /^\Q$In{deleteVar}_zZ_/ ) {
                $matchAll = 0;
                last;
            }
        }
        $errors = {} if ( $matchAll );
    }

    my $isError = %$errors;

    if ( !$isError && $In{saveAction} eq "Save" ) {
        my($mesg, $err);
	if ( $volset ne "" ) {
	    $volsetConf = $bafs->ConfigDataRead($volset) if ( !defined($volsetConf) );
            my %volsetConf2 = %$volsetConf;
	    foreach my $param ( keys(%$newConf) ) {
                if ( $override->{$param} ) {
                    $volsetConf->{$param} = $newConf->{$param}
                } else {
                    delete($volsetConf->{$param});
                }
	    }
            $mesg = configDiffMesg($volset, \%volsetConf2, $volsetConf);
	    $err .= $bafs->ConfigDataWrite($volset, $volsetConf);
	} else {
	    $mainConf = $bafs->ConfigDataRead() if ( !defined($mainConf) );

            my $volsetsSave = [];
            my($volsetsNew, $allVolSets, $copyConf);
            foreach my $entry ( @{$newConf->{VolSets}} ) {
                next if ( $entry->{volset} eq "" );
                $allVolSets->{$entry->{volset}} = 1;
                $allVolSets->{$1} = 1 if ( $entry->{volset} =~ /(.+?)\s*=/ );
            }
            foreach my $entry ( @{$newConf->{VolSets}} ) {
                next if ( $entry->{volset} eq ""
                           || defined($volsetsNew->{$entry->{volset}}) );
                if ( $entry->{volset} =~ /(.+?)\s*=\s*(.+)/ ) {
                    if ( defined($allVolSets->{$2}) ) {
                        $entry->{volset} = $1;
                        $copyConf->{$1} = $2;
                    } else {
                        my $fullVolSet = $entry->{volset};
                        my $copyVolSet = $2;
                        $err .= eval("qq($Lang->{CfgEdit_Error_Copy_volset_does_not_exist})");
                    }
                }
                push(@$volsetsSave, $entry);
                $volsetsNew->{$entry->{volset}} = $entry;
            }
            ($mesg, my $volsetChange) = volsetsDiffMesg($volsetsNew);
            $bafs->VolSetInfoWrite($volsetsNew) if ( $volsetChange );
            foreach my $volset ( keys(%$copyConf) ) {
                #
                # Currently volset names are forced to lc when they
                # are read from the volsets file.  Therefore we need
                # to force the from and to volsets to lc.
                #
                my $confData = $bafs->ConfigDataRead(lc($copyConf->{$volset}));
                my $fromVolSet = $copyConf->{$volset};
                $err  .= $bafs->ConfigDataWrite(lc($volset), $confData);
                $mesg .= eval("qq($Lang->{CfgEdit_Log_Copy_volset_config})");
            }

            delete($newConf->{VolSets});
            $mesg .= configDiffMesg(undef, $mainConf, $newConf);
	    $mainConf = { %$mainConf, %$newConf };
	    $err .= $bafs->ConfigDataWrite(undef, $mainConf);
            $newConf->{VolSets} = $volsetsSave;
	}
        if ( defined($err) ) {
            $tblContent .= <<EOF;
<tr><td colspan="2" class="border"><span class="editError">$err</span></td></tr>
EOF
        }
        $bafs->ServerConnect();
        if ( $mesg ne "" ) {
            (my $mesgBR = $mesg) =~ s/\n/<br>\n/g;
             # uncomment this if you want the changes to be displayed
#            $tblContent .= <<EOF;
#<tr><td colspan="2" class="border"><span class="editComment">$mesgBR</span></td></tr>
#EOF
            foreach my $str ( split(/\n/, $mesg) ) {
                $bafs->ServerMesg("log $str") if ( $str ne "" );
            }
        }
        #
        # Tell the server to reload, unless we only changed
        # a client config
        #
        $bafs->ServerMesg("server reload") if ( $volset eq "" );
    }

    my @mask = @{$menuDisable{$menu}{mask} || []};

    foreach my $paramInfo ( @{$ConfigMenu{$menu}{param}} ) {

        my $param    = $paramInfo->{name};
        my $disabled = shift(@mask);

        next if ( $disabled || $menuDisable{$menu}{top} );
        if ( ref($paramInfo->{visible}) eq "CODE"
                        && !&{$paramInfo->{visible}}($newConf, $bafs) ) {
            next;
        }

	if ( defined($paramInfo->{text}) ) {
            my $text = eval("qq($Lang->{$paramInfo->{text}})");
	    $tblContent .= <<EOF;
<tr><td colspan="2" class="editHeader">$text</td></tr>
EOF
	    next;
	}

	#
	# TODO: get parameter documentation
	#
	my $comment = "";
	#$comment =~ s/\'//g;
	#$comment =~ s/\"//g;
        #$comment =~ s/\n/ /g;

        $doneParam->{$param} = 1;

        $tblContent .= fieldEditBuild($ConfigMeta{$param},
                              $param,
                              $newConf->{$param},
                              $errors,
                              0,
                              $comment,
                              $isError,
                              $paramInfo->{onchangeSubmit},
		              defined($override) ? $param : undef,
			      defined($override) ? $override->{$param} : undef
                        );
        if ( defined($paramInfo->{comment}) ) {
            my $topDir = $bafs->TopDir;
            my $text = eval("qq($Lang->{$paramInfo->{comment}})");
	    $tblContent .= <<EOF;
<tr><td colspan="2" class="editComment">$text</td></tr>
EOF
        }
    }

    #
    # Emit a summary of all the errors
    #
    my $errorTxt;

    if ( %$errors ) {
	$errorTxt .= <<EOF;
<tr><td colspan="2" class="border"><span class="editError">$Lang->{CfgEdit_Error_No_Save}</span></td></tr>
EOF
    }

    foreach my $param ( sort(keys(%$errors)) ) {
	$errorTxt .= <<EOF;
<tr><td colspan="2" class="border"><span class="editError">$errors->{$param}</span></td></tr>
EOF
    }

    $content .= <<EOF;
$errorTxt
$tblContent
</table>
EOF

    #
    # Emit all the remaining editable config settings as hidden values
    #
    foreach my $param ( keys(%ConfigMeta) ) {
        next if ( $doneParam->{$param} );
        next if ( $userVolSet
                      && (!defined($bafs->{Conf}{CgiUserConfigEdit}{$param})
                         || (!$PrivAdmin
                             && !$bafs->{Conf}{CgiUserConfigEdit}{$param})) );
        $content .= fieldHiddenBuild($ConfigMeta{$param},
                            $param,
                            $newConf->{$param},
                            "v"
                        );
        if ( defined($override) ) {
            $content .= <<EOF;
<input type="hidden" name="override_$param" value="$override->{$param}">
EOF
        }
        $doneParam->{$param} = 1;
    }

    if ( defined($In{menu}) || $In{saveAction} eq "Save" ) {
        if ( $In{saveAction} eq "Save" && !$userVolSet ) {
            #
            # Emit the new settings as orig_zZ_ parameters
            #
            $doneParam = {};
            foreach my $param ( keys(%ConfigMeta) ) {
                next if ( $doneParam->{$param} );
                next if ( $userVolSet
                          && (!defined($bafs->{Conf}{CgiUserConfigEdit}{$param})
                             || (!$PrivAdmin
                                && !$bafs->{Conf}{CgiUserConfigEdit}{$param})) );
                $contentHidden .= fieldHiddenBuild($ConfigMeta{$param},
                                        $param,
                                        $newConf->{$param},
                                        "orig",
                                    );
                $doneParam->{$param} = 1;
                $In{modified} = 0;
            }
        } else {
            #
            # Just switching menus: copy all the orig_zZ_ input parameters
            #
            foreach my $var ( keys(%In) ) {
                next if ( $var !~ /^orig_zZ_/ );
                my $val = decode_utf8($In{$var});
                $contentHidden .= <<EOF;
<input type="hidden" name="$var" value="${EscHTML($val)}">
EOF
            }
	}
    } else {
	#
	# First time: emit all the original config settings
	#
	$doneParam = {};
        foreach my $param ( keys(%ConfigMeta) ) {
            next if ( $doneParam->{$param} );
            next if ( $userVolSet
                          && (!defined($bafs->{Conf}{CgiUserConfigEdit}{$param})
                             || (!$PrivAdmin
                                && !$bafs->{Conf}{CgiUserConfigEdit}{$param})) );
            $contentHidden .= fieldHiddenBuild($ConfigMeta{$param},
                                    $param,
                                    $mainConf->{$param},
                                    "orig",
                                );
            $doneParam->{$param} = 1;
	}
    }

    $content .= <<EOF;
$contentHidden
</form>
</tr>
</table>
EOF

    Header("Config Edit", $content);
    Trailer();
}

sub fieldHiddenBuild
{
    my($type, $varName, $varValue, $prefix) = @_;
    my $content;

    $type = { type => $type } if ( ref($type) ne "HASH" );

    if ( $type->{type} eq "list" ) {
        $varValue = [] if ( !defined($varValue) );
        $varValue = [$varValue] if ( ref($varValue) ne "ARRAY" );

        for ( my $i = 0 ; $i < @$varValue ; $i++ ) {
            $content .= fieldHiddenBuild($type->{child}, "${varName}_zZ_$i",
                                         $varValue->[$i], $prefix);
        }
    } elsif ( $type->{type} eq "hash" || $type->{type} eq "horizHash" ) {
        $varValue = {} if ( ref($varValue) ne "HASH" );
        my(@order, $childType);

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = sort(keys(%$varValue));
        }

        foreach my $fld ( @order ) {
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
                #
                # emit list of fields since they are user-defined
                # rather than hard-coded
                #
                $content .= <<EOF;
<input type="hidden" name="vflds.$varName" value="${EscHTML($fld)}">
EOF
            }
            $content .= fieldHiddenBuild($childType, "${varName}_zZ_$fld",
                                         $varValue->{$fld}, $prefix);
        }
    } elsif ( $type->{type} eq "VSHash" ) {
        $varValue = {} if ( ref($varValue) ne "HASH" );
        my(@order, $childType);

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = sort(keys(%$varValue));
        }

        foreach my $fld ( @order ) {
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
                #
                # emit list of fields since they are user-defined
                # rather than hard-coded
                #
                $content .= <<EOF;
<input type="hidden" name="vflds.$varName" value="${EscHTML($fld)}">
EOF
            }
            $content .= fieldHiddenBuild($childType, "${varName}_zZ_$fld",
                                         $varValue->{$fld}, $prefix);
	    $content .= "<table><tr><td><br></td></tr></table>\n";
        }
    } elsif ( $type->{type} eq "shortlist" ) {
	$varValue = [$varValue] if ( ref($varValue) ne "ARRAY" );
	$varValue = join(", ", @$varValue);
        $content .= <<EOF;
<input type="hidden" name="${prefix}_zZ_$varName" value="${EscHTML($varValue)}">
EOF
    } else {
        $content .= <<EOF;
<input type="hidden" name="${prefix}_zZ_$varName" value="${EscHTML($varValue)}">
EOF
    }
    return $content;
}

sub fieldEditBuild
{
    my($type, $varName, $varValue, $errors, $level, $comment, $isError,
       $onchangeSubmit, $overrideVar, $overrideSet) = @_;

    my $content;
    my $size = 50 - 10 * $level;
    $type = { type => $type } if ( ref($type) ne "HASH" );

    $size = $type->{size} if ( defined($type->{size}) );

    #
    # These fragments allow inline content to be turned on and off
    #
    # <tr><td colspan="2"><span id="id_$varName" style="display: none" class="editComment">$comment</span></td></tr>
    # <tr><td class="border"><a href="javascript: displayHelp('$varName')">$varName</a>
    #

    if ( $level == 0 ) {
        my $lcVarName = lc($varName);
	$content .= <<EOF;
<tr><td class="border"><a href="?action=view&type=docs#_conf_${lcVarName}_">$varName</a>
EOF
	if ( defined($overrideVar) ) {
	    my $override_checked = "";
	    if ( !$isError && $In{deleteVar}      =~ /^\Q${varName}_zZ_/
		   || !$isError && $In{insertVar} =~ /^\Q${varName}\E(_zZ_|$)/
		   || !$isError && $In{addVar}    =~ /^\Q${varName}\E(_zZ_|$)/ ) {
		$overrideSet = 1;
	    }
	    if ( $overrideSet ) {
		$override_checked = "checked";
	    }
            $content .= <<EOF;
<br><input type="checkbox" name="override_$varName" $override_checked value="1" onClick="checkboxChange('$varName')">\&nbsp;${EscHTML($Lang->{CfgEdit_Button_Override})}
EOF
	}
	$content .= "</td>\n";
    }

    if ( $type->{type} eq "list" ) {
        $content .= "<td class=\"border\">\n";
        $varValue = [] if ( !defined($varValue) );
        $varValue = [$varValue] if ( ref($varValue) ne "ARRAY" );
        if ( !$isError && $In{deleteVar} =~ /^\Q${varName}_zZ_\E(\d+)$/
                && $1 < @$varValue ) {
            #
            # User deleted entry in this array
            #
            splice(@$varValue, $1, 1) if ( @$varValue > 1 || $type->{emptyOk} );
            $In{deleteVar} = "";
        }
        if ( !$isError && $In{insertVar} =~ /^\Q${varName}_zZ_\E(\d+)$/
                && $1 < @$varValue ) {
            #
            # User inserted entry in this array
            #
            splice(@$varValue, $1, 0, "")
                        if ( @$varValue > 1 || $type->{emptyOk} );
            $In{insertVar} = "";
        }
        if ( !$isError && $In{addVar} eq $varName ) {
            #
            # User added entry to this array
            #
            push(@$varValue, undef);
            $In{addVar} = "";
        }
        $content .= "<table border=\"1\" cellspacing=\"0\">\n";
        my $colspan;

        if ( ref($type) eq "HASH" && ref($type->{child}) eq "HASH"
                    && $type->{child}{type} eq "horizHash" ) {
            my @order;
            if ( defined($type->{child}{order}) ) {
                @order = @{$type->{child}{order}};
            } else {
                @order = sort(keys(%{$type->{child}{child}}));
            }
            $content .= "<tr><td class=\"border\"></td>\n";
            for ( my $i = 0 ; $i < @order ; $i++ ) {
                $content .= "<td class=\"tableheader\">$order[$i]</td>\n";
            }
            $colspan = @order + 1;
            $content .= "</tr>\n";
            for ( my $i = 0 ; $i < @$varValue ; $i++ ) {
                if ( @$varValue > 1 || $type->{emptyOk} ) {
                    $content .= <<EOF;
<td class="border">
<input type="button" name="del_${varName}_zZ_$i" value="${EscHTML($Lang->{CfgEdit_Button_Delete})}"
    onClick="deleteSubmit('${varName}_zZ_$i')">
</td>
EOF
                }
                $content .= fieldEditBuild($type->{child}, "${varName}_zZ_$i",
                                  $varValue->[$i], $errors, $level + 1, undef,
                                  $isError, $onchangeSubmit,
                                  $overrideVar, $overrideSet);
                $content .= "</tr>\n";
            }
        } elsif ( ref($type) eq "HASH" && ref($type->{child}) eq "HASH"
                    && $type->{child}{type} eq "VSHash" ) {
	    # my house, my rules.
            my @order;
            if ( defined($type->{child}{order}) ) {
                @order = @{$type->{child}{order}};
            } else {
                @order = sort(keys(%{$type->{child}{child}}));
            }
            # We will emit field names with their boxes FTW.
	    # rowspan is magic number.
	    my $rowspan= 1 + int((@order-1)/3); # 1 + (num elements / 3).... if user adds more Entry fields, this automagically adjusts
            for ( my $i = 0 ; $i < @$varValue ; $i++ ) {
                $content .= <<EOF;
<tr><td class="border" rowspan="$rowspan">
<input type="button" name="ins_${varName}_zZ_$i" value="${EscHTML($Lang->{CfgEdit_Button_Insert})}"
    onClick="insertSubmit('${varName}_zZ_$i')"><br>
EOF
                if ( @$varValue > 1 || $type->{emptyOk} ) {
                    $content .= <<EOF;
<input type="button" name="del_${varName}_zZ_$i" value="${EscHTML($Lang->{CfgEdit_Button_Delete})}"
    onClick="deleteSubmit('${varName}_zZ_$i')">
</td>
EOF
			# The above displays the Delete button for each existing VS.
                }
		# This displays the line of entry boxes, all in a row.
                $content .= fieldEditBuild($type->{child}, "${varName}_zZ_$i",
                                  $varValue->[$i], $errors, $level + 1, undef,
                                  $isError, $onchangeSubmit,
                                  $overrideVar, $overrideSet);
                $content .= "</tr>\n";
            }
        } else {
            for ( my $i = 0 ; $i < @$varValue ; $i++ ) {
                $content .= <<EOF;
<tr><td class="border">
<input type="button" name="ins_${varName}_zZ_$i" value="${EscHTML($Lang->{CfgEdit_Button_Insert})}"
    onClick="insertSubmit('${varName}_zZ_$i')">
EOF
                if ( @$varValue > 1 || $type->{emptyOk} ) {
                    $content .= <<EOF;
<input type="button" name="del_${varName}_zZ_$i" value="${EscHTML($Lang->{CfgEdit_Button_Delete})}"
    onClick="deleteSubmit('${varName}_zZ_$i')">
EOF
                }
                $content .= "</td>\n";
                $content .= fieldEditBuild($type->{child}, "${varName}_zZ_$i",
                                    $varValue->[$i], $errors, $level + 1, undef,
                                    $isError, $onchangeSubmit,
                                    $overrideVar, $overrideSet);
                $content .= "</tr>\n";
            }
            $colspan = 2;
        }
        $content .= <<EOF;
<tr><td class="border" colspan="7"><input type="button" name="add_$varName" value="${EscHTML($Lang->{CfgEdit_Button_Add})}"
    onClick="addSubmit('$varName')"></td></tr>
</table>
EOF
    } elsif ( $type->{type} eq "hash" ) {
        $content .= "<td class=\"border\">\n";
        $content .= "<table border=\"1\" cellspacing=\"0\">\n";
        $varValue = {} if ( ref($varValue) ne "HASH" );

        if ( !$isError && !$type->{noKeyEdit}
                        && $In{deleteVar} !~ /^\Q${varName}_zZ_\E.*_zZ_/
                        && $In{deleteVar} =~ /^\Q${varName}_zZ_\E(.*)$/ ) {
            #
            # User deleted entry in this hash
            #
            delete($varValue->{$1}) if ( keys(%$varValue) > 1
					    || $type->{emptyOk} );
            $In{deleteVar} = "";
        }
        if ( !$isError && !defined($type->{child})
                        && $In{addVar} eq $varName ) {
            #
            # User added entry to this array
            #
            $varValue->{$In{"addVarKey_$varName"}} = ""
                        if ( !defined($varValue->{$In{"addVarKey_$varName"}}) );
            $In{addVar} = "";
        }
        my(@order, $childType);

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = sort(keys(%$varValue));
        }

        foreach my $fld ( @order ) {
            $content .= <<EOF;
<tr><td class="border">$fld
EOF
            if ( !$type->{noKeyEdit}
		    && (keys(%$varValue) > 1 || $type->{emptyOk}) ) {
                $content .= <<EOF;
<input type="submit" name="del_${varName}_zZ_$fld" value="${EscHTML($Lang->{CfgEdit_Button_Delete})}"
        onClick="deleteSubmit('${varName}_zZ_$fld')">
EOF
            }
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
                #
                # emit list of fields since they are user-defined
                # rather than hard-coded
                #
                $content .= <<EOF;
<input type="hidden" name="vflds.$varName" value="${EscHTML($fld)}">
EOF
            }
            $content .= "</td>\n";
            $content .= fieldEditBuild($childType, "${varName}_zZ_$fld",
                            $varValue->{$fld}, $errors, $level + 1, undef,
			    $isError, $onchangeSubmit,
			    $overrideVar, $overrideSet);
            $content .= "</tr>\n";
        }

        if ( !$type->{noKeyEdit} ) {
            $content .= <<EOF;
<tr><td class="border" colspan="2">
$Lang->{CfgEdit_Button_New_Key}: <input type="text" class="editTextInput" name="addVarKey_$varName" size="20" maxlength="256" value="">
<input type="button" name="add_$varName" value="${EscHTML($Lang->{CfgEdit_Button_Add})}" onClick="addSubmit('$varName', 1)">
</td></tr>
EOF
        }
        $content .= "</table>\n";
        $content .= "</td>\n";
    } elsif ( $type->{type} eq "horizHash" ) {
        $varValue = {} if ( ref($varValue) ne "HASH" );
        my(@order, $childType);

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = sort(keys(%$varValue));
        }

        foreach my $fld ( @order ) {
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
                #
                # emit list of fields since they are user-defined
                # rather than hard-coded
                #
                $content .= <<EOF;
<input type="hidden" name="vflds.$varName" value="${EscHTML($fld)}">
EOF
            }
            $content .= fieldEditBuild($childType, "${varName}_zZ_$fld",
                            $varValue->{$fld}, $errors, $level + 1, undef,
			    $isError, $onchangeSubmit,
			    $overrideVar, $overrideSet);
        }
    } elsif ( $type->{type} eq "VSHash" ) {
        $varValue = {} if ( ref($varValue) ne "HASH" );
        my(@order, $childType);

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = sort(keys(%$varValue));
        }

        my $count=0;
        foreach my $fld ( @order ) {
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
                #
                # emit list of fields since they are user-defined
                # rather than hard-coded
                #
                $content .= <<EOF;
<input type="hidden" name="vflds.$varName" value="${EscHTML($fld)}">
EOF
            }
            $content .= "<td class=\"tableheader\">$fld\n";

	    # This displays the entry boxes, one at a time, but all in a row
            $content .= fieldEditBuild($childType, "${varName}_zZ_$fld",
                            $varValue->{$fld}, $errors, $level + 1, undef,
			    $isError, $onchangeSubmit,
			    $overrideVar, $overrideSet);
        $content .= "</td>";
	# added user and moreUsers back. No need for this now.
        #if ($count == 0 ) {
	#  # First row in this VolSet's table. End row after asking name.
        #  $content .= "<td colspan=\"4\" class=\"tableheader\">&nbsp;</td>";
        #}
        #if ($count == 0 || $count == 3 || $count == 6 ) {
	if ( (($count+1)%3)==0 && (int($count) != $#order)) {
          $content .= "</tr><tr>";
        }
        $count++;
        }
	$content .= "<tr><td colspan=\"7\" class=\"volsetheader\">&nbsp;</td></tr>";
    } else {
        $content .= "<td class=\"border\">\n";
        if ( $isError ) {
            #
            # If there was an error, we use the original post values
            # in %In, rather than the parsed values in $varValue.
            # This is so that the user's erroneous input is preserved.
            #
            $varValue = $In{"v_zZ_$varName"} if ( defined($In{"v_zZ_$varName"}) );
        }
        if ( defined($errors->{$varName}) ) {
            $content .= <<EOF;
<span class="editError">$errors->{$varName}</span><br>
EOF
        }
        my $onChange;
	if ( defined($overrideVar) ) {
            $onChange .= "checkboxSet('$overrideVar');";
	} else {
            $onChange .= "varChange('$varName');";
	}
        if ( $onchangeSubmit ) {
            $onChange .= "document.editForm.submit();";
        }
	if ( $onChange ne "" ) {
            $onChange = " onChange=\"$onChange\"";
	}
        if ( $varValue !~ /\n/ &&
		($type->{type} eq "integer"
		    || $type->{type} eq "string"
		    || $type->{type} eq "execPath"
		    || $type->{type} eq "shortlist"
		    || $type->{type} eq "float") ) {
            # simple input box
	    if ( $type->{type} eq "shortlist" ) {
		$varValue = [$varValue] if ( ref($varValue) ne "ARRAY" );
		$varValue = join(", ", @$varValue);
	    }
            my $textType = ($varName =~ /Passwd/) ? "password" : "text";
            $content .= <<EOF;
<input type="$textType" class="editTextInput" name="v_zZ_$varName" size="$size" maxlength="256" value="${EscHTML($varValue)}"$onChange>
EOF
        } elsif ( $type->{type} eq "boolean" ) {
            # checkbox
            my $checked = "checked" if ( $varValue );
            $content .= <<EOF;
<input type="checkbox" name="v_zZ_$varName" $checked value="1"$onChange>
EOF
        } elsif ( $type->{type} eq "select" ) {
            $content .= <<EOF;
<select name="v_zZ_$varName"$onChange>
EOF
            foreach my $option ( @{$type->{values}} ) {
                my $sel = " selected" if ( $varValue eq $option );
                $content .= "<option$sel>$option</option>\n";
            }
            $content .= "</select>\n";
        } else {
            # multi-line text area - count number of lines
	    my $rowCnt = $varValue =~ tr/\n//;
	    $rowCnt = 7 if ( $rowCnt < 1 );
            $content .= <<EOF;
<textarea name="v_zZ_$varName" class="editTextArea" cols="$size" rows="$rowCnt"$onChange>${EscHTML($varValue)}</textarea>
EOF
        }
        $content .= "</td>\n";
    }
    return $content;
}

sub errorCheck
{
    my $errors = {};

    foreach my $param ( keys(%ConfigMeta) ) {
        fieldErrorCheck($ConfigMeta{$param}, $param, $errors);
    }
    return $errors;
}

sub fieldErrorCheck
{
    my($type, $varName, $errors) = @_;

    $type = { type => $type } if ( ref($type) ne "HASH" );

    if ( $type->{type} eq "list" ) {
        for ( my $i = 0 ; ; $i++ ) {
            last if ( fieldErrorCheck($type->{child}, "${varName}_zZ_$i", $errors) );
        }
    } elsif ( $type->{type} eq "hash" || $type->{type} eq "horizHash" ) {
        my(@order, $childType);
        my $ret;

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = split(/\0/, $In{"vflds.$varName"});
        }
        foreach my $fld ( @order ) {
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
            }
            $ret ||= fieldErrorCheck($childType, "${varName}_zZ_$fld", $errors);
        }
        return $ret;
    } elsif ( $type->{type} eq "VSHash" ) {
        my(@order, $childType);
        my $ret;

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = split(/\0/, $In{"vflds.$varName"});
        }
        foreach my $fld ( @order ) {
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
            }
            $ret ||= fieldErrorCheck($childType, "${varName}_zZ_$fld", $errors);
        }
        return $ret;
    } else {
        $In{"v_zZ_$varName"} = "0" if ( $type->{type} eq "boolean"
                                        && $In{"v_zZ_$varName"} eq "" );

        return 1 if ( !exists($In{"v_zZ_$varName"}) );

        (my $var = $varName) =~ s/_zZ_/./g;

        if ( $type->{type} eq "integer"
                || $type->{type} eq "boolean" ) {
            if ( $In{"v_zZ_$varName"} !~ /^-?\d+\s*$/s
			    && $In{"v_zZ_$varName"} ne "" ) {
                $errors->{$varName} = eval("qq{$Lang->{CfgEdit_Error__must_be_an_integer}}");
            }
        } elsif ( $type->{type} eq "float" ) {
            if ( $In{"v_zZ_$varName"} !~ /^-?\d*(\.\d*)?\s*$/s
			    && $In{"v_zZ_$varName"} ne "" ) {
                $errors->{$varName}
                        = eval("qq{$Lang->{CfgEdit_Error__must_be_real_valued_number}}");
            }
        } elsif ( $type->{type} eq "shortlist" ) {
	    my @vals = split(/[,\s]+/, $In{"v_zZ_$varName"});
	    for ( my $i = 0 ; $i < @vals ; $i++ ) {
		if ( $type->{child} eq "integer"
			&& $vals[$i] !~ /^-?\d+\s*$/s
			&& $vals[$i] ne "" ) {
		    my $k = $i + 1;
		    $errors->{$varName} = eval("qq{$Lang->{CfgEdit_Error__entry__must_be_an_integer}}");
		} elsif ( $type->{child} eq "float"
			&& $vals[$i] !~ /^-?\d*(\.\d*)?\s*$/s
			&& $vals[$i] ne "" ) {
		    my $k = $i + 1;
		    $errors->{$varName} = eval("qq{$Lang->{CfgEdit_Error__entry__must_be_real_valued_number}}");
		}
	    }
        } elsif ( $type->{type} eq "select" ) {
            my $match = 0;
            foreach my $option ( @{$type->{values}} ) {
                if ( $In{"v_zZ_$varName"} eq $option ) {
                    $match = 1;
                    last;
                }
            }
            $errors->{$varName} = eval("qq{$Lang->{CfgEdit_Error__must_be_valid_option}}")
                            if ( !$match );
        } elsif ( $type->{type} eq "execPath" ) {
            if ( $In{"v_zZ_$varName"} ne "" && !-x $In{"v_zZ_$varName"} ) {
                $errors->{$varName} = eval("qq{$Lang->{CfgEdit_Error__must_be_executable_program}}");
            }
        } else {
            #
            # $type->{type} eq "string": no error checking
            #
        }
    }
    return 0;
}

sub inputParse
{
    my($bafs, $userVolSet) = @_;
    my $conf     = {};
    my $override = {};

    foreach my $param ( keys(%ConfigMeta) ) {
        my $value;
        next if ( $userVolSet
                      && (!defined($bafs->{Conf}{CgiUserConfigEdit}{$param})
                         || (!$PrivAdmin
                            && !$bafs->{Conf}{CgiUserConfigEdit}{$param})) );
        fieldInputParse($ConfigMeta{$param}, $param, \$value);
        $conf->{$param}     = $value;
        $override->{$param} = $In{"override_$param"};
    }
    return ($conf, $override);
}

sub fieldInputParse
{
    my($type, $varName, $value) = @_;

    $type = { type => $type } if ( ref($type) ne "HASH" );

    if ( $type->{type} eq "list" ) {
        $$value = [];
        for ( my $i = 0 ; ; $i++ ) {
            my $val;
            last if ( fieldInputParse($type->{child}, "${varName}_zZ_$i", \$val) );
            push(@$$value, $val);
        }
        $$value = undef if ( $type->{undefIfEmpty} && @$$value == 0 );
    } elsif ( $type->{type} eq "hash" || $type->{type} eq "horizHash" ) {
        my(@order, $childType);
        my $ret;
        $$value = {};

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = split(/\0/, $In{"vflds.$varName"});
        }

        foreach my $fld ( @order ) {
            my $val;
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
            }
            $ret ||= fieldInputParse($childType, "${varName}_zZ_$fld", \$val);
            last if ( $ret );
            $$value->{$fld} = $val;
        }
        return $ret;
    } elsif ( $type->{type} eq "VSHash" ) {
        my(@order, $childType);
        my $ret;
        $$value = {};

        if ( defined($type->{order}) ) {
            @order = @{$type->{order}};
        } elsif ( defined($type->{child}) ) {
            @order = sort(keys(%{$type->{child}}));
        } else {
            @order = split(/\0/, $In{"vflds.$varName"});
        }

        foreach my $fld ( @order ) {
            my $val;
            if ( defined($type->{child}) ) {
                $childType = $type->{child}{$fld};
            } else {
                $childType = $type->{childType};
            }
            $ret ||= fieldInputParse($childType, "${varName}_zZ_$fld", \$val);
            last if ( $ret );
            $$value->{$fld} = $val;
        }
        return $ret;
    } else {
        if ( $type->{type} eq "boolean" ) {
            $$value = 0 + $In{"v_zZ_$varName"};
        } elsif ( !exists($In{"v_zZ_$varName"}) ) {
            return 1;
        }

        my $v = $In{"v_zZ_$varName"};

        if ( $type->{type} eq "integer" ) {
            if ( $v =~ /^-?\d+\s*$/s || $v eq "" ) {
                $$value = 0 + $v;
            } else {
                # error value - keep in string form
                $$value = $v;
            }
        } elsif ( $type->{type} eq "float" ) {
            if ( $v =~ /^-?\d*(\.\d*)?\s*$/s || $v eq "" ) {
                $$value = 0 + $v;
            } else {
                # error value - keep in string form
                $$value = $v;
            }
        } elsif ( $type->{type} eq "shortlist" ) {
            $$value = [split(/[,\s]+/, $v)];
            if ( $type->{child} eq "float" ) {
                foreach ( @$$value ) {
                    if ( /^-?\d*(\.\d*)?\s*$/s || $v eq "" ) {
                        $_ += 0;
                    }
                }
            } elsif ( $type->{child} eq "integer"
                        || $type->{child} eq "boolean" ) {
                foreach ( @$$value ) {
                    if ( /^-?\d+\s*$/s || $v eq "" ) {
                        $_ += 0;
                    }
                }
            }
        } else {
            $$value = decode_utf8($In{"v_zZ_$varName"});
            $$value =~ s/\r\n/\n/g;
            # remove leading space from exec paths
            $$value =~ s/^\s+// if ( $type->{type} eq "execPath" );
        }
        $$value = undef if ( $type->{undefIfEmpty} && $$value eq "" );
    }
    return 0;
}

sub configDiffMesg
{
    my($volset, $oldConf, $newConf) = @_;
    my $mesg;
    my $conf;

    if ( $volset ne "" ) {
        $conf = "volset $volset config";
    } else {
        $conf = "main config";
    }

    foreach my $p ( keys(%ConfigMeta) ) {
        if ( !exists($oldConf->{$p}) && !exists($newConf->{$p}) ) {
            next;
        } elsif ( exists($oldConf->{$p}) && !exists($newConf->{$p}) ) {
            $mesg .= eval("qq($Lang->{CfgEdit_Log_Delete_param})");
        } elsif ( !exists($oldConf->{$p}) && exists($newConf->{$p}) ) {
            my $dump = Data::Dumper->new([$newConf->{$p}]);
            $dump->Indent(0);
            $dump->Sortkeys(1);
            $dump->Terse(1);
            my $value = $dump->Dump;
            $value =~ s/\n/\\n/g;
            $value =~ s/\r/\\r/g;
            if ( $p =~ /Passwd/ || $p =~ /Secret/ ) {
                $value = "'*'";
            }

            $mesg .= eval("qq($Lang->{CfgEdit_Log_Add_param_value})");
        } else {
            my $dump = Data::Dumper->new([$newConf->{$p}]);
            $dump->Indent(0);
            $dump->Sortkeys(1);
            $dump->Terse(1);
            my $valueNew = $dump->Dump;

            my $v = $oldConf->{$p};
            if ( ref($newConf->{$p}) eq "ARRAY" && ref($v) eq "" ) {
                $v = [$v];
            }
            $dump = Data::Dumper->new([$v]);
            $dump->Indent(0);
            $dump->Sortkeys(1);
            $dump->Terse(1);
            my $valueOld = $dump->Dump;

            (my $valueNew2 = $valueNew) =~ s/['\n\r]//g;
            (my $valueOld2 = $valueOld) =~ s/['\n\r]//g;

            next if ( $valueOld2 eq $valueNew2 );

            $valueNew =~ s/\n/\\n/g;
            $valueOld =~ s/\n/\\n/g;
            $valueNew =~ s/\r/\\r/g;
            $valueOld =~ s/\r/\\r/g;
            if ( $p =~ /Passwd/ || $p =~ /Secret/ ) {
                $valueNew = "'*'";
                $valueOld = "'*'";
            }

            $mesg .= eval("qq($Lang->{CfgEdit_Log_Change_param_value})");
        }
    }
    return $mesg;
}

sub volsetsDiffMesg
{
    my($volsetsNew) = @_;
    my $volsetsOld = $bafs->VolSetInfoRead();
    my($mesg, $volsetChange);

    foreach my $volset ( keys(%$volsetsOld) ) {
        if ( !defined($volsetsNew->{$volset}) ) {
            $mesg .= eval("qq($Lang->{CfgEdit_Log_VolSet_Delete})");
            $volsetChange++;
            next;
        }
        foreach my $key ( keys(%{$volsetsNew->{$volset}}) ) {
            next if ( $volsetsNew->{$volset}{$key} eq $volsetsOld->{$volset}{$key} );
            my $valueOld = $volsetsOld->{$volset}{$key};
            my $valueNew = $volsetsNew->{$volset}{$key};
            $mesg .= eval("qq($Lang->{CfgEdit_Log_VolSet_Change})");
            $volsetChange++;
        }
    }

    foreach my $volset ( keys(%$volsetsNew) ) {
        next if ( defined($volsetsOld->{$volset}) );
        my $dump = Data::Dumper->new([$volsetsNew->{$volset}]);
        $dump->Indent(0);
        $dump->Sortkeys(1);
        $dump->Terse(1);
        my $value = $dump->Dump;
        $value =~ s/\n/\\n/g;
        $value =~ s/\r/\\r/g;
        $mesg .= eval("qq($Lang->{CfgEdit_Log_VolSet_Add})");
        $volsetChange++;
    }
    return ($mesg, $volsetChange);
}

1;
