#=============================================================
#
# BackupAFS::CGI::RSS package
#
# DESCRIPTION
#
#   This module implements an RSS page for the CGI interface.
#
# AUTHOR
#   Rich Duzenbury (rduz at theduz dot com)
#
# COPYRIGHT
#   Copyright (C) 2005-2009  Rich Duzenbury and Craig Barratt
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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
#========================================================================
#
# Version 1.0.0, released 22 Nov 2010.
#
# See http://backupafs.sourceforge.net.
#
#========================================================================

package BackupAFS::CGI::RSS;

use strict;
use BackupAFS::CGI::Lib qw(:all);
use XML::RSS;

sub action
{
    my $base_url = 'https://' . $ENV{'SERVER_NAME'} . $ENV{SCRIPT_NAME};

    my($fullTot, $fullSizeTot, $incrTot, $incrSizeTot, $str,
       $strNone, $strGood, $volsetCntGood, $volsetCntNone);

    binmode(STDOUT, ":utf8");

    my $rss = new XML::RSS (version => '1.0',
                            encoding => 'utf-8');

    $rss->channel( title => eval("qq{$Lang->{RSS_Doc_Title}}"),
                   link => $base_url,
                   language => $Conf{Language},
                   description => eval("qq{$Lang->{RSS_Doc_Description}}"),
               );

    $volsetCntGood = $volsetCntNone = 0;
    GetStatusInfo("volsets");
    my $Privileged = CheckPermission();

    foreach my $volset ( GetUserVolSets(1) ) {
        my($fullDur, $incrCnt, $incrAge, $fullSize, $fullRate, $reasonHilite);
	my($shortErr);
        my @Backups = $bafs->BackupInfoRead($volset);
        my $fullCnt = $incrCnt = 0;
        my $fullAge = $incrAge = -1;

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
                    $fullDur  = $Backups[$i]{endTime} - $Backups[$i]{startTime};
                }
                $fullSizeTot += $Backups[$i]{size} / (1024 * 1024);
            } else {
                $incrCnt++;
                if ( $incrAge < 0 || $Backups[$i]{startTime} > $incrAge ) {
                    $incrAge = $Backups[$i]{startTime};
                }
                $incrSizeTot += $Backups[$i]{size} / (1024 * 1024);
            }
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
	$incrAge = "&nbsp;" if ( $incrAge eq "" );
	$reasonHilite = $Conf{CgiStatusHilightColor}{$Status{$volset}{reason}}
		      || $Conf{CgiStatusHilightColor}{$Status{$volset}{state}};
	$reasonHilite = " bgcolor=\"$reasonHilite\"" if ( $reasonHilite ne "" );
        if ( $Status{$volset}{state} ne "Status_backup_in_progress"
		&& $Status{$volset}{state} ne "Status_restore_in_progress"
		&& $Status{$volset}{error} ne "" ) {
	    ($shortErr = $Status{$volset}{error}) =~ s/(.{48}).*/$1.../;
	    $shortErr = " ($shortErr)";
	}

        my $volset_state = $Lang->{$Status{$volset}{state}};
        my $volset_last_attempt =  $Lang->{$Status{$volset}{reason}} . $shortErr;

        $str = eval("qq{$Lang->{RSS_VolSet_Summary}}");

        $rss->add_item(title => $volset . ', ' . 
                                $volset_state . ', ' . 
                                $volset_last_attempt,
                       link => $base_url . '?volset=' . $volset,
                       description => $str);
    }

    $fullSizeTot = sprintf("%.2f", $fullSizeTot / 1000);
    $incrSizeTot = sprintf("%.2f", $incrSizeTot / 1000);
    my $now      = timeStamp2(time);

    print 'Content-type: text/xml', "\r\n\r\n",
          $rss->as_string;

}

1;
