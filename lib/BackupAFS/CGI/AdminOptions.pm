#============================================================= -*-perl-*-
#
# BackupAFS::CGI::AdminOptions package
#
# DESCRIPTION
#
#   This module implements the AdminOptions action for the CGI interface.
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
# Version 1.0.8, released 15 Sep 2015.
#
# See http://backupafs.sourceforge.net.
#
#========================================================================

package BackupAFS::CGI::AdminOptions;

use strict;
use BackupAFS::CGI::Lib qw(:all);

sub action
{
    unless ( CheckPermission() ) {
        ErrorExit($Lang->{Only_privileged_users_can_view_admin_options});
    }
    my $content = eval("qq{$Lang->{Admin_Options_Page}}");
    Header(eval("qq{$Lang->{H_Admin_Options}}"), $content);
    Trailer();
}

1;
