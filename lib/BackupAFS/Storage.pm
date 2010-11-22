#============================================================= -*-perl-*-
#
# BackupAFS::Storage package
#
# DESCRIPTION
#
#   This library defines a BackupAFS::Storage class for reading/writing
#   data like config, volset info, backup and restore info.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2004-2009  Craig Barratt
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

package BackupAFS::Storage;

use strict;
use BackupAFS::Storage::Text;
use Data::Dumper;

sub new
{
    my $class = shift;
    my($paths) = @_;
    my $flds = {
        BackupFields => [qw(
                    num type startTime endTime
                    nFiles size nFilesExist sizeExist nFilesNew sizeNew
                    xferErrs xferBadFile xferBadShare tarErrs
                    compress sizeExistComp sizeNewComp
                    noFill fillFromNum mangle xferMethod level
                    charset version
                )],
        RestoreFields => [qw(
                    num startTime endTime result errorMsg nFiles size
                    tarCreateErrs xferErrs
                )],
        ArchiveFields => [qw(
                    num startTime endTime result errorMsg
                )],
    };

    return BackupAFS::Storage::Text->new($flds, $paths, @_);
}

#
# Writes per-backup information into the pc/nnn/backupInfo
# file to allow later recovery of the pc/backups file in
# cases when it is corrupted.
#
sub backupInfoWrite
{
    my($class, $pcDir, $bkupNum, $bkupInfo, $force) = @_;

    return if ( !$force && -f "$pcDir/$bkupNum/backupInfo" );
    my($dump) = Data::Dumper->new(
             [   $bkupInfo],
             [qw(*backupInfo)]);
    $dump->Indent(1);
    if ( open(BKUPINFO, ">", "$pcDir/$bkupNum/backupInfo") ) {
        print(BKUPINFO $dump->Dump);
        close(BKUPINFO);
    }
}

1;
