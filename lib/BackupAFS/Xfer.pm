#============================================================= -*-perl-*-
#
# BackupAFS::Xfer package
#
# DESCRIPTION
#
#   This library defines a Factory for invoking transfer protocols in
#   a polymorphic manner.  This libary allows for easier expansion of
#   supported protocols.
#
# AUTHOR
#   Paul Mantz  <pcmantz@zmanda.com>
#
# COPYRIGHT
#   Copyright (C) 2001-2009  Craig Barratt
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


package BackupAFS::Xfer;

use strict;
use Encode qw/from_to encode/;

#use BackupAFS::Xfer::Archive;
#use BackupAFS::Xfer::Ftp;
#use BackupAFS::Xfer::Protocol;
#use BackupAFS::Xfer::Rsync;
#use BackupAFS::Xfer::Smb;
#use BackupAFS::Xfer::Tar;
use BackupAFS::Xfer::Vos;


use vars qw( $errStr );

sub create
{
    my($protocol, $bafs, $args) = @_;
    my $xfer;

    $errStr = undef;

    if ( $protocol eq 'vos') {

        $xfer = BackupAFS::Xfer::Vos->new($bafs);
        $errStr = BackupAFS::Xfer::Vos::errStr;
        return $xfer;

    } else {

	$xfer = undef;
        $errStr = "$protocol is not a supported protocol.";
	return $xfer;
    }
}

#
# getShareNames() loads the correct shares dependent on the
# transfer type.
#
sub getShareNames
{
    my($conf) = @_;
    for my $foo( sort keys %$conf ) { 
      print "$foo $conf->{$foo}\n";
    }
    #print "client: $client\n";

    my $ShareNames;

    if ( $conf->{XferMethod} eq "vos" ) {
	# moved to BackupAFS_dump
    } else {
        #
        # default to smb shares
        #
	$ShareNames = "";
    }

    $ShareNames = [$ShareNames] unless ref($ShareNames) eq "ARRAY";
    return $ShareNames;
}


sub getRestoreCmd
{
    my($conf) = @_;
    my $restoreCmd;

        #
        # protocol unrecognized
        #
        $restoreCmd = undef;
    return $restoreCmd;
}


#sub restoreEnabled
#{
#    my($conf) = @_;
#    my $restoreCmd;

    #if ( $conf->{XferMethod} eq "archive" ) {
    #    return;

    #} elsif ( $conf->{XferMethod} eq "ftp" ) {
    #    return;

    #} elsif ( $conf->{XferMethod} eq "rsync"
    #       || $conf->{XferMethod} eq "rsyncd"
    #       || $conf->{XferMethod} eq "tar"
    #       || $conf->{XferMethod} eq "smb" ) {
    #    $restoreCmd = getRestoreCmd( $conf );
    #    return !!(
    #        ref $restoreCmd eq "ARRAY"
    #        ? @$restoreCmd
    #        : $restoreCmd ne ""
    #    );
#
#    } else {
#        return;
#    }
#}


sub errStr
{
    return $errStr;
}

1;
