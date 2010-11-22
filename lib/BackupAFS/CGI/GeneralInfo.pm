#============================================================= -*-perl-*-
#
# BackupAFS::CGI::GeneralInfo package
#
# DESCRIPTION
#
#   This module implements the GeneralInfo action for the CGI interface.
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

package BackupAFS::CGI::GeneralInfo;

use strict;
use BackupAFS::CGI::Lib qw(:all);

sub action
{
    GetStatusInfo("info jobs volsets queueLen");
    my $Privileged = CheckPermission();
    my($jobStr, $statusStr);
    foreach my $volset ( sort(keys(%Jobs)) ) {
        my $startTime = timeStamp2($Jobs{$volset}{startTime});
        next if ( $volset eq $bafs->trashJob
                    && $Jobs{$volset}{processState} ne "running" );
        next if ( !$Privileged && !CheckPermission($volset) );
        $Jobs{$volset}{type} = $Status{$volset}{type}
                    if ( $Jobs{$volset}{type} eq "" && defined($Status{$volset}));
        (my $cmd = $Jobs{$volset}{cmd}) =~ s/$BinDir\///g;
        (my $xferPid = $Jobs{$volset}{xferPid}) =~ s/,/, /g;
        $jobStr .= <<EOF;
<tr><td class="border"> ${VolSetLink($volset)} </td>
    <td align="center" class="border"> $Jobs{$volset}{type} </td>
    <td align="center" class="border"> ${UserLink(defined($VolSets->{$volset})
					? $VolSets->{$volset}{user} : "")} </td>
    <td class="border"> $startTime </td>
    <td class="border"> $cmd </td>
    <td align="center" class="border"> $Jobs{$volset}{pid} </td>
    <td align="center" class="border"> $xferPid </td>
EOF
        $jobStr .= "</tr>\n";
    }
    foreach my $volset ( sort(keys(%Status)) ) {
        next if ( $Status{$volset}{reason} ne "Reason_backup_failed"
		    && $Status{$volset}{reason} ne "Reason_restore_failed"
		    && (!$Status{$volset}{userReq}
			|| $Status{$volset}{reason} ne "Reason_no_ping") );
        next if ( !$Privileged && !CheckPermission($volset) );
        my $startTime = timeStamp2($Status{$volset}{startTime});
        my($errorTime, $XferViewStr);
        if ( $Status{$volset}{errorTime} > 0 ) {
            $errorTime = timeStamp2($Status{$volset}{errorTime});
        }
        if ( -f "$TopDir/volsets/$volset/SmbLOG.bad"
                || -f "$TopDir/volsets/$volset/SmbLOG.bad.z"
                || -f "$TopDir/volsets/$volset/XferLOG.bad"
                || -f "$TopDir/volsets/$volset/XferLOG.bad.z"
                ) {
            $XferViewStr = <<EOF;
<a href="$MyURL?action=view&type=XferLOGbad&volset=${EscURI($volset)}">$Lang->{XferLOG}</a>,
<a href="$MyURL?action=view&type=XferErrbad&volset=${EscURI($volset)}">$Lang->{Errors}</a>
EOF
        } else {
            $XferViewStr = "";
        }
        (my $shortErr = $Status{$volset}{error}) =~ s/(.{48}).*/$1.../;   
        $statusStr .= <<EOF;
<tr><td class="border"> ${VolSetLink($volset)} </td>
    <td align="center" class="border"> $Status{$volset}{type} </td>
    <td align="center" class="border"> ${UserLink(defined($VolSets->{$volset})
					? $VolSets->{$volset}{user} : "")} </td>
    <td align="right" class="border"> $startTime </td>
    <td class="border"> $XferViewStr </td>
    <td align="right" class="border"> $errorTime </td>
    <td class="border"> ${EscHTML($shortErr)} </td></tr>
EOF
    }
    my $now          = timeStamp2(time);
    my $nextWakeupTime = timeStamp2($Info{nextWakeup});
    my $DUlastTime   = timeStamp2($Info{DUlastValueTime});
    my $DUmaxTime    = timeStamp2($Info{DUDailyMaxTime});
    my $numBgQueue   = $QueueLen{BgQueue};
    my $numUserQueue = $QueueLen{UserQueue};
    my $numCmdQueue  = $QueueLen{CmdQueue};
    my $serverStartTime = timeStamp2($Info{startTime});
    my $configLoadTime  = timeStamp2($Info{ConfigLTime});
    my $generalInfo = eval("qq{$Lang->{BackupAFS_Server_Status_General_Info}}")
                                if ( $Privileged );
    my $content = eval("qq{$Lang->{BackupAFS_Server_Status}}");

    Header($Lang->{H_BackupAFS_Server_Status}, $content);
    Trailer();
}

1;
