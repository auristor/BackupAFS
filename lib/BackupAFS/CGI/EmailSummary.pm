#============================================================= -*-perl-*-
#
# BackupAFS::CGI::EmailSummary package
#
# DESCRIPTION
#
#   This module implements the EmailSummary action for the CGI interface.
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

package BackupAFS::CGI::EmailSummary;

use strict;
use BackupAFS::CGI::Lib qw(:all);

sub action
{
    my $Privileged = CheckPermission();

    if ( !$Privileged ) {
        ErrorExit($Lang->{Only_privileged_users_can_view_email_summaries});
    }
    GetStatusInfo("volsets");
    ReadUserEmailInfo();
    my(%EmailStr, $str);
    foreach my $u ( keys(%UserEmailInfo) ) {
        my $info;
        if ( defined($UserEmailInfo{$u}{lastTime})
                && ref($UserEmailInfo{$u}{lastTime}) ne 'HASH' ) {
            #
            # old format $UserEmailInfo
            #
            my $volset = $UserEmailInfo{$u}{lastVolSet};
            $info = {
                $volset => {
                    lastTime => $UserEmailInfo{$u}{lastTime},
                    lastSubj => $UserEmailInfo{$u}{lastSubj},
                },
            };
        } else {
            $info = $UserEmailInfo{$u};
        }
        foreach my $volset ( keys(%$info) ) {
            next if ( !defined($info->{$volset}{lastTime}) );
            my $emailTimeStr = timeStamp2($info->{$volset}{lastTime});
            $EmailStr{$info->{$volset}{lastTime}} .= <<EOF;
<tr><td>${UserLink($u)} </td>
    <td>${VolSetLink($volset)} </td>
    <td>$emailTimeStr </td>
    <td>$info->{$volset}{lastSubj} </td></tr>
EOF
        }
    }
    foreach my $t ( sort({$b <=> $a} keys(%EmailStr)) ) {
        $str .= $EmailStr{$t};
    }
    my $content = eval("qq{$Lang->{Recent_Email_Summary}}");
    Header($Lang->{Email_Summary}, $content);
    Trailer();
}

1;
