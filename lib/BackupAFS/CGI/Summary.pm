#============================================================= -*-perl-*-
#
# BackupAFS::CGI::Summary package
#
# DESCRIPTION
#
#   This module implements the Summary action for the CGI interface.
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

package BackupAFS::CGI::Summary;

use strict;
use BackupAFS::CGI::Lib qw(:all);

sub action
{
    my($fullTot, $fullSizeTot, $fullSizeCompTot, $incrTot, $incrSizeTot, $incrSizeCompTot, $str,
       $strNone, $strGood, $volsetCntGood, $volsetCntNone);

    $volsetCntGood = $volsetCntNone = 0;
    GetStatusInfo("volsets info");
    my $Privileged = CheckPermission();

    foreach my $volset ( GetUserVolSets(1) ) {
        my($fullDur, $incrCnt, $incrAge, $fullSize, $incrSize, $fullSizeComp, $incrSizeComp, $fullRate, $reasonHilite,
           $lastAge, $tempState, $tempReason, $lastXferErrors);
	my($shortErr);
        my @Backups = $bafs->BackupInfoRead($volset);
        my $fullCnt = $incrCnt = 0;
        my $fullAge = $incrAge = $lastAge = -1;

        $bafs->ConfigRead($volset);
        %Conf = $bafs->Conf();

        next if ( $Conf{XferMethod} eq "archive" );
        next if ( !$Privileged && !CheckPermission($volset) );

        for ( my $i = 0 ; $i < @Backups ; $i++ ) {
            if ( $Backups[$i]{type} eq "full" ) {
                $fullCnt++;
                if ( $fullAge < 0 || $Backups[$i]{startTime} > $fullAge ) {
                    $fullAge  = $Backups[$i]{startTime};
                    $fullSize = $Backups[$i]{size} / (1024 * 1024);
                    $fullSizeComp = $Backups[$i]{sizeNewComp} / (1024 * 1024);
                    $fullDur  = $Backups[$i]{endTime} - $Backups[$i]{startTime};
                }
                $fullSizeTot += $Backups[$i]{size} / (1024 * 1024);
                #$fullSizeCompTot += $Backups[$i]{sizeNewComp} / (1024 * 1024);
        	$fullSizeComp=$fullSize if ($fullSizeComp == 0 );
                $fullSizeCompTot += $fullSizeComp;
            } else {
                $incrCnt++;
                if ( $incrAge < 0 || $Backups[$i]{startTime} > $incrAge ) {
                    $incrAge = $Backups[$i]{startTime};
                }
                $incrSize = $Backups[$i]{size} / (1024 * 1024);
                $incrSizeComp = $Backups[$i]{sizeNewComp} / (1024 * 1024);
                $incrSizeTot += $Backups[$i]{size} / (1024 * 1024);
                #$incrSizeCompTot += $Backups[$i]{sizeNewComp} / (1024 * 1024);
        	$incrSizeComp=$incrSize if ($incrSizeComp == 0 );
                $incrSizeCompTot += $incrSizeComp;
            }
        }
        if ( $fullAge > $incrAge && $fullAge >= 0 )  {
            $lastAge = $fullAge;
        } else {
            $lastAge = $incrAge;
        }
        if ( $lastAge < 0 ) {
            $lastAge = "";
        } else {
            $lastAge = sprintf("%.1f", (time - $lastAge) / (24 * 3600));
        }
        if ( $fullAge < 0 ) {
            $fullAge = "";
            $fullRate = "";
        } else {
            $fullAge = sprintf("%.1f", (time - $fullAge) / (24 * 3600));
            $fullRate = sprintf("%.2f",
                                $fullSize / ($fullDur <= 0 ? 1 : $fullDur));
        }
        if ( $incrAge < 0 ) {
            $incrAge = "";
        } else {
            $incrAge = sprintf("%.1f", (time - $incrAge) / (24 * 3600));
        }
        $fullTot += $fullCnt;
        $incrTot += $incrCnt;
        $fullSize = sprintf("%.2f", $fullSize / 1000);
        $fullSizeComp = sprintf("%.2f", $fullSizeComp / 1000);
	$incrAge = "&nbsp;" if ( $incrAge eq "" );
        $lastXferErrors = $Backups[@Backups-1]{xferErrs} if ( @Backups );
	$reasonHilite = $Conf{CgiStatusHilightColor}{$Status{$volset}{reason}}
		      || $Conf{CgiStatusHilightColor}{$Status{$volset}{state}};
	if ( $Conf{BackupsDisable} == 1 ) {
            if ( $Status{$volset}{state} ne "Status_backup_in_progress"
                    && $Status{$volset}{state} ne "Status_restore_in_progress" ) {
                $reasonHilite = $Conf{CgiStatusHilightColor}{Disabled_OnlyManualBackups};
                $tempState = "Disabled_OnlyManualBackups";
                $tempReason = "";
            } else {
                $tempState = $Status{$volset}{state};
                $tempReason = $Status{$volset}{reason};
            }
	} elsif ($Conf{BackupsDisable} == 2 ) {
	    $reasonHilite = $Conf{CgiStatusHilightColor}{Disabled_AllBackupsDisabled};
	    $tempState = "Disabled_AllBackupsDisabled";
	    $tempReason = "";
	} else {
	    $tempState = $Status{$volset}{state};
	    $tempReason = $Status{$volset}{reason};
	}
	$reasonHilite = " bgcolor=\"$reasonHilite\"" if ( $reasonHilite ne "" );
        if ( $tempState ne "Status_backup_in_progress"
		&& $tempState ne "Status_restore_in_progress"
		&& $Conf{BackupsDisable} == 0
		&& $Status{$volset}{error} ne "" ) {
	    ($shortErr = $Status{$volset}{error}) =~ s/(.{48}).*/$1.../;
	    $shortErr = " ($shortErr)";
	}

        $str = <<EOF;
<tr$reasonHilite><td class="border">${VolSetLink($volset)}</td>
    <td align="center" class="border"> ${UserLink(defined($VolSets->{$volset})
				    ? $VolSets->{$volset}{user} : "")} </td>
    <td align="center" class="border">$fullCnt</td>
    <td align="center" class="border">$fullAge</td>
    <td align="center" class="border">$fullSize</td>
    <td align="center" class="border">$fullRate</td>
    <td align="center" class="border">$incrCnt</td>
    <td align="center" class="border">$incrAge</td>
    <td align="center" class="border">$lastAge</td> 
    <td align="center" class="border">$Lang->{$tempState}</td>
    <td align="center" class="border">$lastXferErrors</td> 
    <td class="border">$Lang->{$tempReason}$shortErr</td></tr>
EOF
        if ( @Backups == 0 ) {
            $volsetCntNone++;
            $strNone .= $str;
        } else {
            $volsetCntGood++;
            $strGood .= $str;
        }
    }
    $fullSizeTot = sprintf("%.2f", $fullSizeTot / 1000);
    $incrSizeTot = sprintf("%.2f", $incrSizeTot / 1000);
    $fullSizeCompTot = sprintf("%.2f", $fullSizeCompTot / 1000);
    $incrSizeCompTot = sprintf("%.2f", $incrSizeCompTot / 1000);
    my $percentsaved;
    if ($fullSizeTot != 0 || $incrSizeTot != 0 ) {
	$percentsaved = sprintf("%.2f",100-(($fullSizeCompTot + $incrSizeCompTot ) / ($fullSizeTot + $incrSizeTot )*100));
    } else {
	$percentsaved=0;
    }
    my $GBsaved = sprintf("%.2f",($fullSizeTot + $incrSizeTot ) - ($fullSizeCompTot + $incrSizeCompTot ));
    my $sizeTot = $fullSizeTot + $incrSizeTot;
    my $sizeCompTot = $fullSizeCompTot + $incrSizeCompTot;
    my $now      = timeStamp2(time);
    my $DUlastTime   = timeStamp2($Info{DUlastValueTime});
    my $DUmaxTime    = timeStamp2($Info{DUDailyMaxTime});

    my $content = eval ("qq{$Lang->{BackupAFS_Summary}}");
    Header($Lang->{BackupAFS__Server_Summary}, $content);
    Trailer();
}

1;
