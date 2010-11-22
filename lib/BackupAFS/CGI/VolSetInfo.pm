#============================================================= -*-perl-*-
#
# BackupAFS::CGI::VolSetInfo package
#
# DESCRIPTION
#
#   This module implements the VolSetInfo action for the CGI interface.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2003-2009  Craig Barratt
#   Copyright (C) 2010 Stephen Joyce
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; version 3 ONLY.
#   
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

package BackupAFS::CGI::VolSetInfo;

use strict;
use BackupAFS::CGI::Lib qw(:all);

sub action
{
    my $volset = $1 if ( $In{volset} =~ /(.*)/ );
    my($statusStr, $startIncrStr);

    $volset =~ s/^\s+//;
    $volset =~ s/\s+$//;
    if ( $volset eq "" ) {
	ErrorExit(eval("qq{$Lang->{Unknown_volset_or_user}}"));
    }
    $volset = lc($volset)
               if ( !-d "$TopDir/volsets/$volset" && -d "$TopDir/volsets/" . lc($volset) );
    if ( $volset =~ /\.\./ || !-d "$TopDir/volsets/$volset" ) {
        #
        # try to lookup by user name
        #
        if ( $volset eq "" || !defined($VolSets->{$volset}) ) {
            foreach my $h ( keys(%$VolSets) ) {
                if ( $VolSets->{$h}{user} eq $volset
                        || lc($VolSets->{$h}{user}) eq lc($volset) ) {
                    $volset = $h;
                    last;
                }
            }
            CheckPermission();
            ErrorExit(eval("qq{$Lang->{Unknown_volset_or_user}}"))
                               if ( !defined($VolSets->{$volset}) );
        }
        $In{volset} = $volset;
    }
    GetStatusInfo("volset(${EscURI($volset)})");
    $bafs->ConfigRead($volset);
    %Conf = $bafs->Conf();
    my $Privileged = CheckPermission($volset);
    if ( !$Privileged ) {
        ErrorExit(eval("qq{$Lang->{Only_privileged_users_can_view_information_about}}"));
    }
    ReadUserEmailInfo();

    if ( $Conf{XferMethod} eq "archive" ) {
        my @Archives = $bafs->ArchiveInfoRead($volset);
        my ($ArchiveStr,$warnStr);

        for ( my $i = 0 ; $i < @Archives ; $i++ ) {
            my $startTime = timeStamp2($Archives[$i]{startTime});
            my $dur       = $Archives[$i]{endTime} - $Archives[$i]{startTime};
            $dur          = 1 if ( $dur <= 0 );
            my $duration  = sprintf("%.1f", $dur / 60);
            my $Archives_Result = $Lang->{failed};
            if ($Archives[$i]{result} ne "failed") { $Archives_Result = $Lang->{success}; }
            $ArchiveStr  .= <<EOF;
<tr><td align="center"><a href="$MyURL?action=archiveInfo&num=$Archives[$i]{num}&volset=${EscURI($volset)}">$Archives[$i]{num}</a> </td>
    <td align="center"> $Archives_Result </td>
    <td align="right"> $startTime </td>
    <td align="right"> $duration </td>
</tr>
EOF
        }
        if ( $ArchiveStr ne "" ) {
            $ArchiveStr = eval("qq{$Lang->{Archive_Summary}}");
        }
        if ( @Archives == 0 ) {
            $warnStr = $Lang->{There_have_been_no_archives};
        }
        if ( $StatusVolSet{BgQueueOn} ) {
            $statusStr .= eval("qq{$Lang->{VolSet_volset_is_queued_on_the_background_queue_will_be_backed_up_soon}}");
        }
        if ( $StatusVolSet{UserQueueOn} ) {
            $statusStr .= eval("qq{$Lang->{VolSet_volset_is_queued_on_the_user_queue__will_be_backed_up_soon}}");
        }
        if ( $StatusVolSet{CmdQueueOn} ) {
            $statusStr .= eval("qq{$Lang->{A_command_for_volset_is_on_the_command_queue_will_run_soon}}");
        }

        my $content = eval("qq{$Lang->{VolSet__volset_Archive_Summary2}}");
        Header(eval("qq{$Lang->{VolSet__volset_Archive_Summary}}"), $content, 1);
        Trailer();
        return;
    }

    #
    # Normal, non-archive case
    #
    my @Backups = $bafs->BackupInfoRead($volset);
    my($str, $sizeStr, $compStr, $errStr, $warnStr);
    for ( my $i = 0 ; $i < @Backups ; $i++ ) {
        my $startTime = timeStamp2($Backups[$i]{startTime});
        my $dur       = $Backups[$i]{endTime} - $Backups[$i]{startTime};
        $dur          = 1 if ( $dur <= 0 );
        my $duration  = sprintf("%.1f", $dur / 60);
        my $GB        = sprintf("%.3f", $Backups[$i]{size} / (1000*1000*1000));
        my $MBperSec  = sprintf("%.2f", $Backups[$i]{size} / (1000*1000*$dur));
        my $GBExist   = sprintf("%.3f", $Backups[$i]{sizeExist} / (1000*1000*1000));
        my $GBNew     = sprintf("%.3f", $Backups[$i]{sizeNew} / (1000*1000*1000));
        my($GBExistComp, $ExistComp, $GBNewComp, $NewComp);
        if ( $Backups[$i]{sizeExist} && $Backups[$i]{sizeExistComp} ) {
            $GBExistComp = sprintf("%.3f", $Backups[$i]{sizeExistComp}
                                                / (1000*1000*1000));
            $ExistComp = sprintf("%.2f%%", 100 *
                  (1 - $Backups[$i]{sizeExistComp} / $Backups[$i]{sizeExist}));
        }
        if ( $Backups[$i]{sizeNew} && $Backups[$i]{sizeNewComp} ) {
            $GBNewComp = sprintf("%.3f", $Backups[$i]{sizeNewComp}
                                                / (1000*1000*1000));
            $NewComp = sprintf("%.2f%%", 100 *
                  (1 - $Backups[$i]{sizeNewComp} / $Backups[$i]{sizeNew}));
        }
        my $age = sprintf("%.1f", (time - $Backups[$i]{startTime}) / (24*3600));
        my $browseURL = "$MyURL?action=browse&volset=${EscURI($volset)}&num=$Backups[$i]{num}";
        my $level  = $Backups[$i]{level};
        my $filled = $Backups[$i]{noFill} ? $Lang->{No} : $Lang->{Yes};
        $filled .= " ($Backups[$i]{fillFromNum}) "
                            if ( $Backups[$i]{fillFromNum} ne "" );
        my $ltype = $Lang->{"backupType_$Backups[$i]{type}"};
        $str .= <<EOF;
<tr><td align="center" class="border"> <a href="$browseURL">$Backups[$i]{num}</a> </td>
    <td align="center" class="border"> $ltype </td>
    <td align="center" class="border"> $level </td>
    <td align="right" class="border">  $startTime </td>
    <td align="right" class="border">  $duration </td>
    <td align="right" class="border">  $age </td>
    <td align="left" class="border">   <tt>$TopDir/volsets/$volset/$Backups[$i]{num}</tt> </td></tr>
EOF
        my $is_compress = $Backups[$i]{compress} || $Lang->{off};
        $sizeStr .= <<EOF;
<tr><td align="center" class="border"> <a href="$browseURL">$Backups[$i]{num}</a> </td>
    <td align="center" class="border"> $ltype </td>
    <td align="right" class="border">  $Backups[$i]{nFiles} </td>
    <td align="right" class="border">  $MBperSec </td>
    <td align="center" class="border"> $is_compress </td>
    <td align="right" class="border">  $GB </td>
    <td align="right" class="border">  $GBNewComp </td>
    <td align="right" class="border">  $NewComp </td>
</tr>
EOF
        if (! $ExistComp) { $ExistComp = "&nbsp;"; }
        if (! $GBExistComp) { $GBExistComp = "&nbsp;"; }
        #$compStr .= <<EOF;
#<tr><td align="center" class="border"> <a href="$browseURL">$Backups[$i]{num}</a> </td>
#    <td align="center" class="border"> $ltype </td>
#    <td align="center" class="border"> $is_compress </td>
#    <td align="right" class="border">  $GBNew </td>
#    <td align="right" class="border">  $GBNewComp </td>
#    <td align="right" class="border">  $NewComp </td>
#</tr>
#EOF
        $errStr .= <<EOF;
<tr><td align="center" class="border"> <a href="$browseURL">$Backups[$i]{num}</a> </td>
    <td align="center" class="border"> $ltype </td>
    <td align="center" class="border"> <a href="$MyURL?action=view&type=XferLOG&num=$Backups[$i]{num}&volset=${EscURI($volset)}">$Lang->{XferLOG}</a>,
                      <a href="$MyURL?action=view&type=XferErr&num=$Backups[$i]{num}&volset=${EscURI($volset)}">$Lang->{Errors}</a> </td>
    <td align="right" class="border">  $Backups[$i]{xferErrs} </td>
    <td align="right" class="border">  $Backups[$i]{xferBadFile} </td>
    <td align="right" class="border">  $Backups[$i]{xferBadShare} </td>
EOF
    }

    my @Restores = $bafs->RestoreInfoRead($volset);
    my $restoreStr;

    for ( my $i = 0 ; $i < @Restores ; $i++ ) {
        my $startTime = timeStamp2($Restores[$i]{startTime});
        my $dur       = $Restores[$i]{endTime} - $Restores[$i]{startTime};
        $dur          = 1 if ( $dur <= 0 );
        my $duration  = sprintf("%.1f", $dur / 60);
        my $GB        = sprintf("%.3f", $Restores[$i]{size} / (1000*1000*1000));
        my $MBperSec  = sprintf("%.2f", $Restores[$i]{size} / (1000*1000*$dur));
        my $Restores_Result = $Lang->{failed};
        if ($Restores[$i]{result} ne "failed") { $Restores_Result = $Lang->{success}; }
        $restoreStr  .= <<EOF;
<tr><td align="center" class="border"><a href="$MyURL?action=restoreInfo&num=$Restores[$i]{num}&volset=${EscURI($volset)}">$Restores[$i]{num}</a> </td>
    <td align="center" class="border"> $Restores_Result </td>
    <td align="right" class="border"> $startTime </td>
    <td align="right" class="border"> $duration </td>
    <td align="right" class="border"> $Restores[$i]{nFiles} </td>
    <td align="right" class="border"> $GB </td>
    <td align="right" class="border"> $Restores[$i]{tarCreateErrs} </td>
    <td align="right" class="border"> $Restores[$i]{xferErrs} </td>
</tr>
EOF
    }
    if ( $restoreStr ne "" ) {
        $restoreStr = eval("qq{$Lang->{Restore_Summary}}");
    }
    if ( @Backups == 0 ) {
        $warnStr = $Lang->{This_PC_has_never_been_backed_up};
    }
    if ( defined($VolSets->{$volset}) ) {
        my $user = $VolSets->{$volset}{user};
        my @moreUsers = sort(keys(%{$VolSets->{$volset}{moreUsers}}));
        my $moreUserStr;
        foreach my $u ( sort(keys(%{$VolSets->{$volset}{moreUsers}})) ) {
            $moreUserStr .= ", " if ( $moreUserStr ne "" );
            $moreUserStr .= "${UserLink($u)}";
        }
        if ( $moreUserStr ne "" ) {
            $moreUserStr = " ($Lang->{and} $moreUserStr).\n";
        } else {
            $moreUserStr = ".\n";
        }
        if ( $user ne "" ) {
            $statusStr .= eval("qq{$Lang->{This_PC_is_used_by}$moreUserStr}");
        }
        if ( defined($UserEmailInfo{$user}) && defined($UserEmailInfo{$user}{$volset}) ) {
            my $mailTime = timeStamp2($UserEmailInfo{$user}{$volset}{lastTime});
            my $subj     = $UserEmailInfo{$user}{$volset}{lastSubj};
            $statusStr  .= eval("qq{$Lang->{Last_email_sent_to__was_at___subject}}");
        } elsif ( defined($UserEmailInfo{$user})
                && $UserEmailInfo{$user}{lastVolSet} eq $volset ) {
            #
            # Old format %UserEmailInfo
            #
            my $mailTime = timeStamp2($UserEmailInfo{$user}{lastTime});
            my $subj     = $UserEmailInfo{$user}{lastSubj};
            $statusStr  .= eval("qq{$Lang->{Last_email_sent_to__was_at___subject}}");
        }
    }
    if ( defined($Jobs{$volset}) ) {
        my $startTime = timeStamp2($Jobs{$volset}{startTime});
        (my $cmd = $Jobs{$volset}{cmd}) =~ s/$BinDir\///g;
        $statusStr .= eval("qq{$Lang->{The_command_cmd_is_currently_running_for_started}}");
    }
    if ( $StatusVolSet{BgQueueOn} ) {
        $statusStr .= eval("qq{$Lang->{VolSet_volset_is_queued_on_the_background_queue_will_be_backed_up_soon}}");
    }
    if ( $StatusVolSet{UserQueueOn} ) {
        $statusStr .= eval("qq{$Lang->{VolSet_volset_is_queued_on_the_user_queue__will_be_backed_up_soon}}");
    }
    if ( $StatusVolSet{CmdQueueOn} ) {
        $statusStr .= eval("qq{$Lang->{A_command_for_volset_is_on_the_command_queue_will_run_soon}}");
    }
    my $startTime = timeStamp2($StatusVolSet{endTime} == 0 ?
                $StatusVolSet{startTime} : $StatusVolSet{endTime});
    my $reason = "";
    if ( $StatusVolSet{reason} ne "" ) {
        $reason = " ($Lang->{$StatusVolSet{reason}})";
    }
    $statusStr .= eval("qq{$Lang->{Last_status_is_state_StatusVolSet_state_reason_as_of_startTime}}");

    if ( $StatusVolSet{state} ne "Status_backup_in_progress"
            && $StatusVolSet{state} ne "Status_restore_in_progress"
            && $StatusVolSet{error} ne "" ) {
        $statusStr .= eval("qq{$Lang->{Last_error_is____EscHTML_StatusVolSet_error}}");
    }
    #my $priorStr = "Pings";
    #if ( $StatusVolSet{deadCnt} > 0 ) {
    #    $statusStr .= eval("qq{$Lang->{Pings_to_volset_have_failed_StatusVolSet_deadCnt__consecutive_times}}");
    #    $priorStr = $Lang->{Prior_to_that__pings};
    #}

        if (@{$Conf{BlackoutPeriods}} || defined($Conf{BlackoutHourBegin})) {
            #
            # Handle backward compatibility with original separate scalar
            # blackout parameters.
            #
            if ( defined($Conf{BlackoutHourBegin}) ) {
                push(@{$Conf{BlackoutPeriods}},
                     {
                         hourBegin => $Conf{BlackoutHourBegin},
                         hourEnd   => $Conf{BlackoutHourEnd},
                         weekDays  => $Conf{BlackoutWeekDays},
                     }
                );
            }

            #
            # TODO: this string needs i18n.  Also, comma-separated
            # list with "and" for the last element might not translate
            # correctly.
            #
            my(@days) = qw(Sun Mon Tue Wed Thu Fri Sat);
            my $blackoutStr;
            my $periodCnt = 0;
            foreach my $p ( @{$Conf{BlackoutPeriods}} ) {
                next if ( ref($p->{weekDays}) ne "ARRAY"
                            || !defined($p->{hourBegin})
                            || !defined($p->{hourEnd})
                        );
                my $days = join(", ", @days[@{$p->{weekDays}}]);
                my $t0   = sprintf("%d:%02d", $p->{hourBegin},
                              60 * ($p->{hourBegin} - int($p->{hourBegin})));
                my $t1   = sprintf("%d:%02d", $p->{hourEnd},
                              60 * ($p->{hourEnd} - int($p->{hourEnd})));
                if ( $periodCnt ) {
                    $blackoutStr .= ", ";
                    if ( $periodCnt == @{$Conf{BlackoutPeriods}} - 1 ) {
                        $blackoutStr .= eval("qq{$Lang->{and}}");
                        $blackoutStr .= " ";
                    }
                }
                $blackoutStr
                        .= eval("qq{$Lang->{__time0_to__time1_on__days}}");
                $periodCnt++;
            }
            $statusStr .= eval("qq{$Lang->{Because__volset_has_been}}");
        }
    if ( $StatusVolSet{backoffTime} > time ) {
        my $hours = sprintf("%.1f", ($StatusVolSet{backoffTime} - time) / 3600);
        $statusStr .= eval("qq{$Lang->{Backups_are_deferred_for_hours_hours_change_this_number}}");

    }
    if ( @Backups ) {
        # only allow incremental if there are already some backups
        $startIncrStr = <<EOF;
<input type="button" value="$Lang->{Start_Incr_Backup}"
 onClick="document.StartStopForm.action.value='Start_Incr_Backup';
          document.StartStopForm.submit();">
EOF
    }

    $startIncrStr = eval("qq{$startIncrStr}");
    my $content = eval("qq{$Lang->{VolSet__volset_Backup_Summary2}}");
    Header(eval("qq{$Lang->{VolSet__volset_Backup_Summary}}"), $content);
    Trailer();
}

1;
