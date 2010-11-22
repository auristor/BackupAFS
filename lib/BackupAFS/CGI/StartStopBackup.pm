#============================================================= -*-perl-*-
#
# BackupAFS::CGI::StartStopBackup package
#
# DESCRIPTION
#
#   This module implements the StartStopBackup action for the CGI interface.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2003-2009  Craig Barratt
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

package BackupAFS::CGI::StartStopBackup;

use strict;
use BackupAFS::CGI::Lib qw(:all);

sub action
{
    my($str, $reply);

    my $start = 1 if ( $In{action} eq "Start_Incr_Backup"
                       || $In{action} eq "Start_Full_Backup" );
    my $doFull = $In{action} eq "Start_Full_Backup" ? 1 : 0;
    my $type = $doFull ? $Lang->{Type_full} : $Lang->{Type_incr};
    my $volset = $In{volset};
    my $Privileged = CheckPermission($volset);

    if ( !$Privileged ) {
        ErrorExit(eval("qq{$Lang->{Only_privileged_users_can_stop_or_start_backups}}"));
    }
    ServerConnect();

    if ( $In{doit} ) {
        if ( $start ) {
	    if ( $VolSets->{$volset}{dhcp} ) {
		$reply = $bafs->ServerMesg("backup $In{volsetIP} ${EscURI($volset)}"
				    . " $User $doFull");
		$str = eval("qq{$Lang->{Backup_requested_on_DHCP__volset}}");
	    } else {
		$reply = $bafs->ServerMesg("backup ${EscURI($volset)}"
				    . " ${EscURI($volset)} $User $doFull");
		$str = eval("qq{$Lang->{Backup_requested_on__volset_by__User}}");
	    }
        } else {
            $reply = $bafs->ServerMesg("stop ${EscURI($volset)} $User $In{backoff}");
            $str = eval("qq{$Lang->{Backup_stopped_dequeued_on__volset_by__User}}");
        }
    my $content = eval ("qq{$Lang->{REPLY_FROM_SERVER}}");
        Header(eval ("qq{$Lang->{BackupAFS__Backup_Requested_on__volset}}"),$content);

        Trailer();
    } else {
        if ( $start ) {
            $bafs->ConfigRead($volset);
            %Conf = $bafs->Conf();

            my $checkVolSet = $volset;
            $checkVolSet = $Conf{ClientNameAlias}
                                if ( $Conf{ClientNameAlias} ne "" );
	    my $ipAddr     = ConfirmIPAddress($checkVolSet);
            my $buttonText = $Lang->{$In{action}};
	    my $content = eval("qq{$Lang->{Are_you_sure_start}}");
            Header(eval("qq{$Lang->{BackupAFS__Start_Backup_Confirm_on__volset}}"),$content);
        } else {
            my $backoff = "";
            GetStatusInfo("volset(${EscURI($volset)})");
            if ( $StatusVolSet{backoffTime} > time ) {
                $backoff = sprintf("%.1f",
                                  ($StatusVolSet{backoffTime} - time) / 3600);
            }
            my $buttonText = $Lang->{$In{action}};
            my $content = eval ("qq{$Lang->{Are_you_sure_stop}}");
            Header(eval("qq{$Lang->{BackupAFS__Stop_Backup_Confirm_on__volset}}"),
                        $content);
        }
        Trailer();
    }
}

1;
