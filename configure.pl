#!/usr/bin/env perl
#============================================================= -*-perl-*-
#
# configure.pl: Configuration and installation program for BackupAFS
#
# DESCRIPTION
#
#   This script should be run as root:
#
#        perl configure.pl
#
#   To read about the command-line options for this configure script:
#
#        perldoc configure.pl
#
#   The installation steps are described as the script runs.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2001-2009  Craig Barratt
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

use strict;
no  utf8;
use vars qw(%Conf %OrigConf);
use lib "./lib";
use Encode;

my $EncodeVersion = eval($Encode::VERSION);
if ( $EncodeVersion < 1.99 ) {
    print("Error: you need to upgrade perl's Encode package.\n"
        . "I found $EncodeVersion and BackupAFS needs >= 1.99\n"
        . "Please go to www.cpan.org or use the cpan command.\n");
    exit(1);
}

my @Packages = qw(File::Path File::Spec File::Copy DirHandle Digest::MD5
                  Data::Dumper Getopt::Std Getopt::Long Pod::Usage
                  BackupAFS::Lib BackupAFS::FileZIO);

foreach my $pkg ( @Packages ) {
    eval "use $pkg";
    next if ( !$@ );
    if ( $pkg =~ /BackupAFS/ ) {
        die <<EOF;

Error loading $pkg: $@
BackupAFS cannot load the package $pkg, which is included in the
BackupAFS distribution.  This probably means you did not cd to the
unpacked BackupAFS distribution before running configure.pl, eg:

    cd BackupAFS-1.0.0
    ./configure.pl

Please try again.

EOF
    }
    die <<EOF;

BackupAFS needs the package $pkg.  Please install $pkg
before installing BackupAFS.

EOF
}

my %opts;
$opts{"set-perms"} = 1;
if ( !GetOptions(
            \%opts,
            "batch",
            "backupafs-user=s",
            "bin-path=s%",
            "cgi-dir=s",
            "compress-level=i",
            "config-path=s",
            "config-override=s%",
            "config-dir=s",
            "data-dir=s",
            "dest-dir=s",
            "fhs!",
            "help|?",
            "hostname=s",
            "html-dir=s",
            "html-dir-url=s",
            "install-dir=s",
            "log-dir=s",
            "man",
            "set-perms!",
            "uid-ignore!",
        ) || @ARGV ) {
    pod2usage(2);
}
pod2usage(1) if ( $opts{help} );
pod2usage(-exitstatus => 0, -verbose => 2) if $opts{man};

my $DestDir = $opts{"dest-dir"};
$DestDir = "" if ( $DestDir eq "/" );

if ( !$opts{"uid-ignore"} && $< != 0 ) {
    print <<EOF;

This configure script should be run as root, rather than uid $<.
Provided uid $< has sufficient permissions to create the data and
install directories, then it should be ok to proceed.  Otherwise,
please quit and restart as root.

EOF
    exit(1) if ( prompt("--> Do you want to continue?",
                       "y") !~ /y/i );
    exit(1) if ( $opts{batch} && !$opts{"uid-ignore"} );
}

#
# Check if this is an upgrade, in which case read the existing
# config file to get all the defaults.
#
my $ConfigPath = "";
my $ConfigFileOK = 1;
while ( 1 ) {
    if ( $ConfigFileOK && -f "/etc/BackupAFS/config.pl" ) {
        $ConfigPath = "/etc/BackupAFS/config.pl";
        $opts{fhs} = 1 if ( !defined($opts{fhs}) );
        print <<EOF;

Found /etc/BackupAFS/config.pl, so this is an upgrade of an
existing BackupAFS installation.  We will verify some existing
information, but you will probably not need to make any
changes - just hit ENTER to each question.
EOF
    } else {
        print <<EOF;

Is this a new installation or upgrade for BackupAFS?  If this is
an upgrade please tell me the full path of the existing BackupAFS
configuration file (eg: /etc/BackupAFS/config.pl).  Otherwise, just
hit return.

EOF
        $ConfigPath = prompt("--> Full path to existing main config.pl",
                             $ConfigPath,
                             "config-path");
    }
    last if ( $ConfigPath eq ""
            || ($ConfigPath =~ /^\// && -f $ConfigPath && -w $ConfigPath) );
    my $problem = "is not an absolute path";
    $problem = "is not writable"        if ( !-w $ConfigPath );
    $problem = "is not readable"        if ( !-r $ConfigPath );
    $problem = "is not a regular file"  if ( !-f $ConfigPath );
    $problem = "doesn't exist"          if ( !-e $ConfigPath );
    print("The file '$ConfigPath' $problem.\n");
    if ( $opts{batch} ) {
        print("Need to specify a valid --config-path for upgrade\n");
        exit(1);
    }
    $ConfigFileOK = 0;
}
$opts{fhs} = 1 if ( !defined($opts{fhs}) && $ConfigPath eq "" );
$opts{fhs} = 0 if ( !defined($opts{fhs}) );

my $bpc;
if ( $ConfigPath ne "" && -r $ConfigPath ) {
    (my $confDir = $ConfigPath) =~ s{/[^/]+$}{};
    die("BackupAFS::Lib->new failed\n")
            if ( !($bpc = BackupAFS::Lib->new(".", ".", $confDir, 1)) );
    %Conf = $bpc->Conf();
    %OrigConf = %Conf;
    if ( !$opts{fhs} ) {
        ($Conf{TopDir} = $ConfigPath) =~ s{/[^/]+/[^/]+$}{}
                    if ( $Conf{TopDir} eq '' );
        $bpc->{LogDir} = $Conf{LogDir}  = "$Conf{TopDir}/log"
                    if ( $Conf{LogDir} eq '' );
    }
    $bpc->{ConfDir} = $Conf{ConfDir} = $confDir;
    my $err = $bpc->ServerConnect($Conf{ServerHost}, $Conf{ServerPort}, 1);
    if ( $err eq "" ) {
        print <<EOF;

BackupAFS is running on $Conf{ServerHost}.  You need to stop BackupAFS
before you can upgrade the code.  Depending upon your installation,
you could run "/etc/init.d/backupafs stop".

EOF
        exit(1);
    }
}

#
# Create defaults for FHS setup
#
if ( $opts{fhs} ) {
    $Conf{TopDir}       ||= $opts{"data-dir"}    || "/srv/BackupAFS";
    $Conf{ConfDir}      ||= $opts{"config-dir"}  || "/etc/BackupAFS";
    $Conf{InstallDir}   ||= $opts{"install-dir"} || "/opt/BackupAFS";
    $Conf{LogDir}       ||= $opts{"log-dir"}     || "/var/log/BackupAFS";
} else {
    $Conf{TopDir}       ||= $opts{"data-dir"}    || "/srv/BackupAFS";
    $Conf{ConfDir}      ||= $opts{"config-dir"}  || "$Conf{TopDir}/conf";
    $Conf{InstallDir}   ||= $opts{"install-dir"} || "/opt/BackupAFS";
    $Conf{LogDir}       ||= $opts{"log-dir"}     || "$Conf{TopDir}/log";
}

#
# These are the programs whose paths we need to find
#
my %Programs = (
    perl           => "PerlPath",
    ping           => "PingPath",
    df             => "DfPath",
    'ssh/ssh2'     => "SshPath",
    sendmail       => "SendmailPath",
    hostname       => "HostnamePath",
    cat            => "CatPath",
    gzip           => "GzipPath",
    pigz           => "PigzPath",
    vos            => "AfsVosPath",
);

foreach my $prog ( sort(keys(%Programs)) ) {
    my $path;
    foreach my $subProg ( split(/\//, $prog) ) {
        $path = FindProgram("$ENV{PATH}:/usr/bin:/bin:/sbin:/usr/sbin",
                            $subProg) if ( !length($path) );
    }
    $Conf{$Programs{$prog}} = $path if ( !length($Conf{$Programs{$prog}}) );
}

while ( 1 ) {
    print <<EOF;

I found the following locations for these programs:

EOF
    foreach my $prog ( sort(keys(%Programs)) ) {
        printf("    %-12s => %s\n", $prog, $Conf{$Programs{$prog}});
    }
    print "\n";
    last if (prompt('--> Are these paths correct?', 'y') =~ /^y/i);
    foreach my $prog ( sort(keys(%Programs)) ) {
        $Conf{$Programs{$prog}} = prompt("--> $prog path",
                                         $Conf{$Programs{$prog}});
    }
}

my $Perl58 = system($Conf{PerlPath}
                        . q{ -e 'exit($^V && $^V ge v5.8.0 ? 1 : 0);'});

if ( !$Perl58 ) {
    print <<EOF;

BackupAFS needs perl version 5.8.0 or later.  $Conf{PerlPath} appears
to be an older version.  Please upgrade to a newer version of perl
and re-run this configure script.

EOF
    exit(1);
}

print <<EOF;

Please tell me the hostname of the machine that BackupAFS will run on.

EOF
chomp($Conf{ServerHost} = `$Conf{HostnamePath}`)
        if ( defined($Conf{HostnamePath}) && !defined($Conf{ServerHost}) );
$Conf{ServerHost} = prompt("--> BackupAFS will run on host",
                           $Conf{ServerHost},
                           "hostname");

print <<EOF;

BackupAFS should run as a dedicated user with limited privileges.  You
need to create a user.  This user will need read/write permission on
the main data directory and read/execute permission on the install
directory (these directories will be setup shortly).

The primary group for this user should also be chosen carefully.
The data directories and files will have group read permission,
so group members can access backup files.

EOF
my($name, $passwd, $Uid, $Gid);
while ( 1 ) {
    $Conf{BackupAFSUser} = prompt("--> BackupAFS should run as user",
                                 $Conf{BackupAFSUser} || "backupafs",
                                 "backupafs-user");
    if ( $opts{"set-perms"} ) {
        ($name, $passwd, $Uid, $Gid) = getpwnam($Conf{BackupAFSUser});
        last if ( $name ne "" );
        print <<EOF;

getpwnam() says that user $Conf{BackupAFSUser} doesn't exist.  Please
check the name and verify that this user is in the passwd file.

EOF
        exit(1) if ( $opts{batch} );
    } else {
        last;
    }
}

print <<EOF;

Please specify an install directory for BackupAFS.  This is where the
BackupAFS scripts, library and documentation will be installed.

EOF

while ( 1 ) {
    $Conf{InstallDir} = prompt("--> Install directory (full path)",
                               $Conf{InstallDir},
                               "install-dir");
    last if ( $Conf{InstallDir} =~ /^\// );
    if ( $opts{batch} ) {
        print("Need to specify --install-dir for new installation\n");
        exit(1);
    }
}

print <<EOF;

Please specify a data directory for BackupAFS.  This is where all the
PC backup data is stored.  This file system needs to be big enough to
accommodate all the PCs you expect to backup (eg: at least several GB
per machine).

EOF

while ( 1 ) {
    $Conf{TopDir} = prompt("--> Data directory (full path)",
                           $Conf{TopDir},
                           "data-dir");
    last if ( $Conf{TopDir} =~ /^\// );
    if ( $opts{batch} ) {
        print("Need to specify --data-dir for new installation\n");
        exit(1);
    }
}

$Conf{CompressLevel} = $opts{"compress-level"}
                            if ( defined($opts{"compress-level"}) );

if ( !defined($Conf{CompressLevel}) ) {
    $Conf{CompressLevel} = ($Conf{PigzPath} || $Conf{GzipPath} ) ? 3 : 0;
    if ( $ConfigPath eq "" && $Conf{CompressLevel} ) {
        print <<EOF;

BackupAFS can compress files, providing around a 40% reduction in backup
size (your mileage may vary). Specify the compression level (0 turns
off compression, and 1 to 9 represent good/fastest to best/slowest).
The recommended values are 0 (off) or 3 (reasonable compression and speed).
Increasing the compression level to 5 will use around 20% more cpu time
and give perhaps 2-3% more compression.

EOF
    } elsif ( $ConfigPath eq "" ) {
        print <<EOF;

BackupAFS can compress files, but it needs the either the 'gzip' or 'pigz'
package installed (see your OS docs). Compression will provide around a
40% reduction in backup size, at the expense of cpu time.  You can leave
compression off and run BackupAFS without compression, in which case you
should leave the compression level at 0 (which means off).  Or the better
choice is to quit, install 'gzip' or 'pigz', and re-run configure.pl. For
multi-core systems, pigz (parallelized gzip algorithm) is strongly suggested.

EOF
    } elsif ( $Conf{CompressLevel} ) {
        $Conf{CompressLevel} = 0;
        print <<EOF;

BackupAFS now supports file compression.  Since you are upgrading
BackupAFS you probably have existing uncompressed backups.  You could
turn on compression, so that new backups will be compressed. Eventually
the old uncompressed backups will expire, recovering the storage.  Please
see the documentation for more details.

If you are not sure what to do, leave the Compression Level at 0,
which disables compression.  You can always read the documentation
and turn it on later.

EOF
    } else {
        $Conf{CompressLevel} = 0;
        print <<EOF;

BackupAFS now supports pool file compression, but it needs either
the 'gzip' or 'pigz' package installed (see your OS docs). Compression
will provide around a 40% reduction in backup size, at the expense of
cpu time.  For now, leave the compression level set at 0 to disable
compression.  If you want you can install 'gzip' or 'pigz' and turn
compression on. For multi-core systems, pigz (parallelized gzip
algorithm) is strongly suggested.

EOF
    }
    while ( 1 ) {
        $Conf{CompressLevel}
                    = prompt("--> Compression level", $Conf{CompressLevel});
        last if ( $Conf{CompressLevel} =~ /^\d+$/ );
    }
}

if ($Conf{CompressLevel} && (! $Conf{PigzPath} )) {
	print <<EOF;

***
    You have requested compression, but the 'pigz' binary was not found.
    Gzip is single-threaded. Pigz is a multi-threaded implementation of
    the gzip algorithm. If you have a multi-core or multi-processor system,
    it is strongly recommended that you install pigz update the PigzPath
    configuration variable via the CGI.
***

EOF
}

print <<EOF;

BackupAFS has a powerful CGI perl interface that runs under Apache.
A single executable needs to be installed in a cgi-bin directory.
This executable needs to run as set-uid $Conf{BackupAFSUser}, or
it can be run under mod_perl with Apache running as user $Conf{BackupAFSUser}.

Leave this path empty if you don't want to install the CGI interface.

EOF

while ( 1 ) {
    $Conf{CgiDir} = prompt("--> CGI bin directory (full path)",
                           $Conf{CgiDir},
                           "cgi-dir");
    last if ( $Conf{CgiDir} =~ /^\// || $Conf{CgiDir} eq "" );
    if ( $opts{batch} ) {
        print("Need to specify --cgi-dir for new installation\n");
        exit(1);
    }
}

if ( $Conf{CgiDir} ne "" ) {

    print <<EOF;

BackupAFS's CGI script needs to display various PNG/GIF images that
should be stored where Apache can serve them.  They should be placed
somewhere under Apache's DocumentRoot.  BackupAFS also needs to know
the URL to access these images.  Example:

    Apache image directory:  /var/www/htdocs/BackupAFS
    URL for image directory: /BackupAFS

The URL for the image directory should start with a slash.

EOF
    while ( 1 ) {
	$Conf{CgiImageDir} = prompt("--> Apache image directory (full path)",
                                    $Conf{CgiImageDir},
                                    "html-dir");
	last if ( $Conf{CgiImageDir} =~ /^\// );
        if ( $opts{batch} ) {
            print("Need to specify --html-dir for new installation\n");
            exit(1);
        }
    }
    while ( 1 ) {
	$Conf{CgiImageDirURL} = prompt("--> URL for image directory (omit http://host; starts with '/')",
					$Conf{CgiImageDirURL},
                                        "html-dir-url");
	last if ( $Conf{CgiImageDirURL} =~ /^\// );
        if ( $opts{batch} ) {
            print("Need to specify --html-dir-url for new installation\n");
            exit(1);
        }
    }
}

print <<EOF;

Ok, we're about to:

  - install the binaries, lib and docs in $Conf{InstallDir},
  - create the data directory $Conf{TopDir},
  - create/update the config.pl file $Conf{ConfDir}/config.pl,
  - optionally install the cgi-bin interface.

EOF

exit unless prompt("--> Do you want to continue?", "y") =~ /y/i;

#
# Create install directories
#
foreach my $dir ( qw(bin doc
		     lib/BackupAFS/CGI
		     lib/BackupAFS/Config
		     lib/BackupAFS/Lang
		     lib/BackupAFS/Storage
		     lib/BackupAFS/Xfer
		     lib/BackupAFS/Zip
                     lib/Net/FTP
		 ) ) {
    next if ( -d "$DestDir$Conf{InstallDir}/$dir" );
    mkpath("$DestDir$Conf{InstallDir}/$dir", 0, 0755);
    if ( !-d "$DestDir$Conf{InstallDir}/$dir"
            || !my_chown($Uid, $Gid, "$DestDir$Conf{InstallDir}/$dir") ) {
        die("Failed to create or chown $DestDir$Conf{InstallDir}/$dir\n");
    } else {
        print("Created $DestDir$Conf{InstallDir}/$dir\n");
    }
}

#
# Create CGI image directory
#
foreach my $dir ( ($Conf{CgiImageDir}) ) {
    next if ( $dir eq "" || -d "$DestDir$dir" );
    mkpath("$DestDir$dir", 0, 0755);
    if ( !-d "$DestDir$dir" || !my_chown($Uid, $Gid, "$DestDir$dir") ) {
        die("Failed to create or chown $DestDir$dir");
    } else {
        print("Created $DestDir$dir\n");
    }
}

#
# Create other directories
#
foreach my $dir ( (
            "$Conf{TopDir}",
            "$Conf{TopDir}/volsets",
            "$Conf{TopDir}/trash",
            "$Conf{ConfDir}",
            "$Conf{LogDir}",
        ) ) {
    mkpath("$DestDir$dir", 0, 0750) if ( !-d "$DestDir$dir" );
    if ( !-d "$DestDir$dir"
            || !my_chown($Uid, $Gid, "$DestDir$dir") ) {
        die("Failed to create or chown $DestDir$dir\n");
    } else {
        print("Created $DestDir$dir\n");
    }
}

printf("Installing binaries in $DestDir$Conf{InstallDir}/bin\n");
foreach my $prog ( qw(
	bin/BackupAFS
	bin/BackupAFS_compress
	bin/BackupAFS_distributeFulls
	bin/BackupAFS_dump
	bin/BackupAFS_fixupBackupSummary
	bin/BackupAFS_getVols
	bin/BackupAFS_migrate_compress_volsets
	bin/BackupAFS_migrate_populate_VolSet-List
	bin/BackupAFS_migrate_unmangle_datadir
	bin/BackupAFS_nightly
	bin/BackupAFS_restore
	bin/BackupAFS_sendEmail
	bin/BackupAFS_serverMesg
	bin/BackupAFS_tarCreate
	bin/BackupAFS_trashClean
	bin/BackupAFS_vosWrapper
	bin/BackupAFS_zcat
    ) ) {
    InstallFile($prog, "$DestDir$Conf{InstallDir}/$prog", 0555);
}

printf("Installing library in $DestDir$Conf{InstallDir}/lib\n");
foreach my $lib ( qw(
	lib/BackupAFS/Attrib.pm
	lib/BackupAFS/CGI/AdminOptions.pm
	lib/BackupAFS/CGI/Browse.pm
	lib/BackupAFS/CGI/DirHistory.pm
	lib/BackupAFS/CGI/EditConfig.pm
	lib/BackupAFS/CGI/EmailSummary.pm
	lib/BackupAFS/CGI/GeneralInfo.pm
	lib/BackupAFS/CGI/Lib.pm
	lib/BackupAFS/CGI/LOGlist.pm
	lib/BackupAFS/CGI/Queue.pm
	lib/BackupAFS/CGI/ReloadServer.pm
	lib/BackupAFS/CGI/RestoreFile.pm
	lib/BackupAFS/CGI/RestoreInfo.pm
	lib/BackupAFS/CGI/Restore.pm
	lib/BackupAFS/CGI/RSS.pm
	lib/BackupAFS/CGI/StartServer.pm
	lib/BackupAFS/CGI/StartStopBackup.pm
	lib/BackupAFS/CGI/StopServer.pm
	lib/BackupAFS/CGI/Summary.pm
	lib/BackupAFS/CGI/View.pm
	lib/BackupAFS/CGI/VolSetInfo.pm
	lib/BackupAFS/Config/Meta.pm
	lib/BackupAFS/Config.pm
	lib/BackupAFS/FileZIO.pm
	lib/BackupAFS/Lang/en.pm
	lib/BackupAFS/Lib.pm
	lib/BackupAFS/Storage.pm
	lib/BackupAFS/Storage/Text.pm
	lib/BackupAFS/View.pm
	lib/BackupAFS/Xfer.pm
	lib/BackupAFS/Xfer/Vos.pm
	lib/Net/FTP/AutoReconnect.pm
	lib/Net/FTP/RetrHandle.pm
    ) ) {
    InstallFile($lib, "$DestDir$Conf{InstallDir}/$lib", 0444);
}

if ( $Conf{CgiImageDir} ne "" ) {
    printf("Installing images in $DestDir$Conf{CgiImageDir}\n");
    foreach my $img ( <images/*> ) {
	(my $destImg = $img) =~ s{^images/}{};
	InstallFile($img, "$DestDir$Conf{CgiImageDir}/$destImg", 0444, 1);
    }

    #
    # Install new CSS file, making a backup copy if necessary
    #
    my $cssBackup = "$DestDir$Conf{CgiImageDir}/BackupAFS_stnd.css.pre-1.0.0";
    if ( -f "$DestDir$Conf{CgiImageDir}/BackupAFS_stnd.css" && !-f $cssBackup ) {
	rename("$DestDir$Conf{CgiImageDir}/BackupAFS_stnd.css", $cssBackup);
    }
    InstallFile("conf/BackupAFS_stnd.css",
	        "$DestDir$Conf{CgiImageDir}/BackupAFS_stnd.css", 0444, 0);
    InstallFile("conf/BackupAFS_stnd_orig.css",
	        "$DestDir$Conf{CgiImageDir}/BackupAFS_stnd_orig.css", 0444, 0);
    InstallFile("conf/sorttable.js",
                "$DestDir$Conf{CgiImageDir}/sorttable.js", 0444, 0);
}

printf("Making init.d scripts\n");
foreach my $init ( qw(gentoo-backupafs gentoo-backupafs.conf linux-backupafs
		      solaris-backupafs debian-backupafs freebsd-backupafs
                      suse-backupafs slackware-backupafs ) ) {
    InstallFile("init.d/src/$init", "init.d/$init", 0444);
}

printf("Making Apache configuration file for suid-perl\n");
InstallFile("httpd/src/BackupAFS.conf", "httpd/BackupAFS.conf", 0644);

printf("Installing docs in $DestDir$Conf{InstallDir}/doc\n");
foreach my $doc ( qw(BackupAFS.pod BackupAFS.html) ) {
    InstallFile("doc/$doc", "$DestDir$Conf{InstallDir}/doc/$doc", 0444);
}

printf("Installing config.pl and VolumeSet-List in $DestDir$Conf{ConfDir}\n");
InstallFile("conf/VolumeSet-List", "$DestDir$Conf{ConfDir}/VolumeSet-List", 0644)
                    if ( !-f "$DestDir$Conf{ConfDir}/VolumeSet-List" );

#
# Now do the config file.  If there is an existing config file we
# merge in the new config file, adding any new configuration
# parameters and deleting ones that are no longer needed.
#
my $dest = "$DestDir$Conf{ConfDir}/config.pl";
my ($distConf, $distVars) = ConfigParse("conf/config.pl");
my ($oldConf, $oldVars);
my ($newConf, $newVars) = ($distConf, $distVars);
if ( -f $dest ) {
    ($oldConf, $oldVars) = ConfigParse($dest);
    ($newConf, $newVars) = ConfigMerge($oldConf, $oldVars, $distConf, $distVars);
}

#
# Update various config parameters.  The old config is in Conf{}
# and the new config is an array in text form in $newConf->[].
#
$Conf{EMailFromUserName}  ||= $Conf{BackupAFSUser};
$Conf{EMailAdminUserName} ||= $Conf{BackupAFSUser};

#
# Guess $Conf{CgiURL}
#
if ( !defined($Conf{CgiURL}) ) {
    if ( $Conf{CgiDir} =~ m{cgi-bin(/.*)} ) {
	$Conf{CgiURL} = "'http://$Conf{ServerHost}/cgi-bin$1/BackupAFS_Admin'";
    } else {
	$Conf{CgiURL} = "'http://$Conf{ServerHost}/cgi-bin/BackupAFS_Admin'";
    }
}

#
# CSS is now stored in a file rather than a big config variable.
#
delete($Conf{CSSstylesheet});

#
# The blackout timing settings are now stored in a list of hashes, rather
# than three scalar parameters.
#
if ( defined($Conf{BlackoutHourBegin}) ) {
    $Conf{BlackoutPeriods} = [
	 {
	     hourBegin => $Conf{BlackoutHourBegin},
	     hourEnd   => $Conf{BlackoutHourEnd},
	     weekDays  => $Conf{BlackoutWeekDays},
	 } 
    ];
    delete($Conf{BlackoutHourBegin});
    delete($Conf{BlackoutHourEnd});
    delete($Conf{BlackoutWeekDays});
}

#
# $Conf{RsyncLogLevel} has been replaced by $Conf{XferLogLevel}
#
if ( defined($Conf{RsyncLogLevel}) ) {
    $Conf{XferLogLevel} = $Conf{RsyncLogLevel};
    delete($Conf{RsyncLogLevel});
}

#
# Figure out sensible arguments for the ping command
#
if ( defined($Conf{PingArgs}) ) {
    $Conf{PingCmd} = '$pingPath ' . $Conf{PingArgs};
} elsif ( !defined($Conf{PingCmd}) ) {
    if ( $^O eq "solaris" || $^O eq "sunos" ) {
	$Conf{PingCmd} = '$pingPath -s $volset 56 1';
    } elsif ( ($^O eq "linux" || $^O eq "openbsd" || $^O eq "netbsd")
	    && !system("$Conf{PingPath} -c 1 -w 3 localhost") ) {
	$Conf{PingCmd} = '$pingPath -c 1 -w 3 $volset';
    } else {
	$Conf{PingCmd} = '$pingPath -c 1 $volset';
    }
    delete($Conf{PingArgs});
}

#
# Figure out sensible arguments for the df command
#
if ( !defined($Conf{DfCmd}) ) {
    if ( $^O eq "solaris" || $^O eq "sunos" ) {
	$Conf{DfCmd} = '$dfPath -k $topDir';
    }
}

#
# $Conf{SmbClientTimeout} is now $Conf{ClientTimeout}
#
if ( defined($Conf{SmbClientTimeout}) ) {
    $Conf{ClientTimeout} = $Conf{SmbClientTimeout};
    delete($Conf{SmbClientTimeout});
}

#
# Merge any new user-editable parameters into CgiUserConfigEdit
# by copying the old settings forward.
#
if ( defined($Conf{CgiUserConfigEdit}) ) {
    #
    # This is a real hack.  The config file merging is done in text
    # form without actually instantiating the new conf structure.
    # So we need to extract the new hash of settings, update it,
    # and merge the text.  Ugh...
    #
    my $new;
    my $str = $distConf->[$distVars->{CgiUserConfigEdit}]{text};

    $str =~ s/^\s*\$Conf\{.*?\}\s*=\s*/\$new = /m;
    eval($str);
    foreach my $p ( keys(%$new) ) {
        $new->{$p} = $Conf{CgiUserConfigEdit}{$p}
                if ( defined($Conf{CgiUserConfigEdit}{$p}) );
    }
    $Conf{CgiUserConfigEdit} = $new;
    my $d = Data::Dumper->new([$new], [*value]);
    $d->Indent(1);
    $d->Terse(1);
    my $value = $d->Dump;
    $value =~ s/(.*)\n/$1;\n/s;
    $newConf->[$newVars->{CgiUserConfigEdit}]{text}
            =~ s/(\s*\$Conf\{.*?\}\s*=\s*).*/$1$value/s;
}

#
# Apply any command-line configuration parameter settings
#
foreach my $param ( keys(%{$opts{"config-override"}}) ) {
    my $val = eval { $opts{"config-override"}{$param} };
    if ( @$ ) {
        printf("Can't eval --config-override setting %s=%s\n",
                        $param, $opts{"config-override"}{$param});
        exit(1);
    }
    if ( !defined($newVars->{$param}) ) {
        printf("Unkown config parameter %s in --config-override\n", $param);
        exit(1);
    }
    $newConf->[$newVars->{$param}]{text} = $opts{"config-override"}{$param};
}

#
# Now backup and write the config file
#
my $confCopy = "$dest.pre-1.0.0";
if ( -f $dest && !-f $confCopy ) {
    #
    # Make copy of config file, preserving ownership and modes
    #
    printf("Making backup copy of $dest -> $confCopy\n");
    my @stat = stat($dest);
    my $mode = $stat[2];
    my $uid  = $stat[4];
    my $gid  = $stat[5];
    die("can't copy($dest, $confCopy)\n")
                                unless copy($dest, $confCopy);
    die("can't chown $uid, $gid $confCopy\n")
                                unless my_chown($uid, $gid, $confCopy);
    die("can't chmod $mode $confCopy\n")
                                unless my_chmod($mode, $confCopy);
}
open(OUT, ">", $dest) || die("can't open $dest for writing\n");
binmode(OUT);
my $blockComment;
foreach my $var ( @$newConf ) {
    if ( length($blockComment)
          && substr($var->{text}, 0, length($blockComment)) eq $blockComment ) {
        $var->{text} = substr($var->{text}, length($blockComment));
        $blockComment = undef;
    }
    $blockComment = $1 if ( $var->{text} =~ /^([\s\n]*#{70}.*#{70}[\s\n]+)/s );
    $var->{text} =~ s/^\s*\$Conf\{(.*?)\}(\s*=\s*['"]?)(.*?)(['"]?\s*;)/
                defined($Conf{$1}) && ref($Conf{$1}) eq ""
                                   && $Conf{$1} ne $OrigConf{$1}
                                   ? "\$Conf{$1}$2$Conf{$1}$4"
                                   : "\$Conf{$1}$2$3$4"/emg;
    print OUT $var->{text};
}
close(OUT);
if ( !defined($oldConf) ) {
    die("can't chmod 0640 mode $dest\n")  unless my_chmod(0640, $dest);
    die("can't chown $Uid, $Gid $dest\n") unless my_chown($Uid, $Gid, $dest);
}

if ( $Conf{CgiDir} ne "" ) {
    printf("Installing cgi script BackupAFS_Admin in $DestDir$Conf{CgiDir}\n");
    mkpath("$DestDir$Conf{CgiDir}", 0, 0755);
    InstallFile("cgi-bin/BackupAFS_Admin", "$DestDir$Conf{CgiDir}/BackupAFS_Admin",
                04554);
}

print <<EOF;

Ok, it looks like we are finished.  There are several more things you
will need to do:

  - Browse through the config file, $Conf{ConfDir}/config.pl,
    and make sure all the settings are correct.  In particular,
    you will need to set \$Conf{CgiAdminUsers} so you have
    administration privileges in the CGI interface.

  - Edit the list of VolumeSets to backup in $Conf{ConfDir}/VolumeSet-List.
    The easiest way to do this is via the CGI once you're logged in as
    an admin user.

  - Read the documentation in $Conf{InstallDir}/doc/BackupAFS.html.
    Please pay special attention to the security section.

  - Verify that the CGI script BackupAFS_Admin runs correctly.  You might
    need to change the permissions or group ownership of BackupAFS_Admin.
    If this is an upgrade and you are using mod_perl, you will need
    to restart Apache.  Otherwise it will have stale code.

  - BackupAFS should be ready to start.  Don't forget to run it
    as user $Conf{BackupAFSUser}!  The installation also contains an
    init.d/backupafs script that can be copied to /etc/init.d
    so that BackupAFS can auto-start on boot.  This will also enable
    administrative users to start the server from the CGI interface.
    See init.d/README.

Enjoy!
EOF

if ( `$Conf{PerlPath} -V` =~ /uselargefiles=undef/ ) {
    print <<EOF;

Warning: your perl, $Conf{PerlPath}, does not support large files.
This means BackupAFS won't be able to backup files larger than 2GB.
To solve this problem you should build/install a new version of perl
with large file support enabled.  Use

    $Conf{PerlPath} -V | egrep uselargefiles

to check if perl has large file support (undef means no support).
EOF
}

eval "use File::RsyncP;";
if ( !$@ && $File::RsyncP::VERSION < 0.68 ) {
    print("\nWarning: you need to upgrade File::RsyncP;"
        . " I found $File::RsyncP::VERSION and BackupAFS needs 0.68\n");
}

exit(0);

###########################################################################
# Subroutines
###########################################################################

sub InstallFile
{
    my($prog, $dest, $mode, $binary) = @_;
    my $first = 1;
    my($uid, $gid) = ($Uid, $Gid);

    if ( -f $dest ) {
        #
        # preserve ownership and modes of files that already exist
        #
        my @stat = stat($dest);
        $mode = $stat[2];
        $uid  = $stat[4];
        $gid  = $stat[5];
    }
    unlink($dest) if ( -f $dest );
    if ( $binary ) {
	die("can't copy($prog, $dest)\n") unless copy($prog, $dest);
    } else {
	open(PROG, $prog)     || die("can't open $prog for reading\n");
	open(OUT, ">", $dest) || die("can't open $dest for writing\n");
	binmode(PROG);
	binmode(OUT);
	while ( <PROG> ) {
	    s/__INSTALLDIR__/$Conf{InstallDir}/g;
	    s/__LOGDIR__/$Conf{LogDir}/g;
	    s/__CONFDIR__/$Conf{ConfDir}/g;
	    s/__TOPDIR__/$Conf{TopDir}/g;
            s/^(\s*my \$useFHS\s*=\s*)\d;/${1}$opts{fhs};/
                                    if ( $prog =~ /Lib.pm/ );
	    s/__BACKUPAFSUSER__/$Conf{BackupAFSUser}/g;
	    s/__CGIDIR__/$Conf{CgiDir}/g;
            s/__IMAGEDIR__/$Conf{CgiImageDir}/g;
            s/__IMAGEDIRURL__/$Conf{CgiImageDirURL}/g;
	    if ( $first && /^#.*bin\/perl/ ) {
		#
		# Fill in correct path to perl (no taint for >= 2.0.1).
		#
		print OUT "#!$Conf{PerlPath}\n";
	    } else {
		print OUT;
	    }
	    $first = 0;
	}
	close(PROG);
	close(OUT);
    }
    die("can't chown $uid, $gid $dest") unless my_chown($uid, $gid, $dest);
    die("can't chmod $mode $dest")      unless my_chmod($mode, $dest);
}

sub FindProgram
{
    my($path, $prog) = @_;

    if ( defined($opts{"bin-path"}{$prog}) ) {
        return $opts{"bin-path"}{$prog};
    }
    foreach my $dir ( split(/:/, $path) ) {
        my $file = File::Spec->catfile($dir, $prog);
        return $file if ( -x $file );
    }
    return;
}

sub ConfigParse
{
    my($file) = @_;
    open(C, $file) || die("can't open $file");
    binmode(C);
    my($out, @conf, $var);
    my $comment = 1;
    my $allVars = {};
    my $endLine = undef;
    while ( <C> ) {
        if ( /^#/ && !defined($endLine) ) {
            if ( $comment ) {
                $out .= $_;
            } else {
                if ( $out ne "" ) {
                    $allVars->{$var} = @conf if ( defined($var) );
                    push(@conf, {
                        text => $out,
                        var => $var,
                    });
                }
                $var = undef;
                $comment = 1;
                $out = $_;
            }
        } elsif ( /^\s*\$Conf\{([^}]*)/ ) {
            $comment = 0;
            if ( defined($var) ) {
                $allVars->{$var} = @conf if ( defined($var) );
                push(@conf, {
                    text => $out,
                    var => $var,
                });
                $out = $_;
            } else {
                $out .= $_;
            }
            $var = $1;
	    $endLine = $1 if ( /^\s*\$Conf\{[^}]*} *= *<<(.*);/ );
	    $endLine = $1 if ( /^\s*\$Conf\{[^}]*} *= *<<'(.*)';/ );
        } else {
	    $endLine = undef if ( defined($endLine) && /^\Q$endLine[\n\r]*$/ );
            $out .= $_;
        }
    }
    if ( $out ne "" ) {
        $allVars->{$var} = @conf if ( defined($var) );
        push(@conf, {
            text => $out,
            var  => $var,
        });
    }
    close(C);
    return (\@conf, $allVars);
}

sub ConfigMerge
{
    my($old, $oldVars, $new, $newVars) = @_;
    my $posn = 0;
    my($res, $resVars);

    #
    # Find which config parameters are not needed any longer
    #
    foreach my $var ( @$old ) {
        next if ( !defined($var->{var}) || defined($newVars->{$var->{var}}) );
        #print(STDERR "Deleting old config parameter $var->{var}\n");
        $var->{delete} = 1;
    }
    #
    # Find which config parameters are new
    #
    foreach my $var ( @$new ) {
        next if ( !defined($var->{var}) );
        if ( defined($oldVars->{$var->{var}}) ) {
            $posn = $oldVars->{$var->{var}};
        } else {
            #print(STDERR "New config parameter $var->{var}: $var->{text}\n");
            push(@{$old->[$posn]{new}}, $var);
        }
    }
    #
    # Create merged config file
    #
    foreach my $var ( @$old ) {
        next if ( $var->{delete} );
        push(@$res, $var);
        foreach my $new ( @{$var->{new}} ) {
            push(@$res, $new);
        }
    }
    for ( my $i = 0 ; $i < @$res ; $i++ ) {
        $resVars->{$res->[$i]{var}} = $i;
    }
    return ($res, $resVars);
}

sub my_chown
{
    my($uid, $gid, $file) = @_;

    return 1 if ( !$opts{"set-perms"} );
    return chown($uid, $gid, $file);
}

sub my_chmod
{
    my ($mode, $file) = @_;

    return 1 if ( !$opts{"set-perms"} );
    return chmod($mode, $file);
}

sub prompt
{
    my($question, $default, $option) = @_;

    $default = $opts{$option} if ( defined($opts{$option}) );
    if ( $opts{batch} ) {
        print("$question [$default]\n");
        return $default;
    }
    print("$question [$default]? ");
    my $reply = <STDIN>;
    $reply =~ s/[\n\r]*//g;
    return $reply if ( $reply !~ /^$/ );
    return $default;
}

__END__

=head1 SYNOPSIS

configure.pl [options]

=head1 DESCRIPTION

configure.pl is a script that is used to install or upgrade a BackupAFS
installation.  It is usually run interactively without arguments.  It
also supports a batch mode where all the options can be specified
via the command-line.

For upgrading BackupAFS you need to make sure that BackupAFS is not
running prior to running BackupAFS.

Typically configure.pl needs to run as the super user (root).

=head1 OPTIONS

=over 8

=item B<--batch>

Run configure.pl in batch mode.  configure.pl will run without
prompting the user.  The other command-line options are used
to specify the settings that the user is usually prompted for.

=item B<--backupafs-user=USER>

Specify the BackupAFS user name that owns all the BackupAFS
files and runs the BackupAFS programs.  Default is backupafs.

=item B<--bin-path PROG=PATH>

Specify the path for various external programs that BackupAFS
uses.  Several --bin-path options may be specified.  configure.pl
usually finds sensible defaults based on searching the PATH.
The format is:

    --bin-path PROG=PATH

where PROG is one of perl, tar, smbclient, nmblookup, rsync, ping,
df, ssh, sendmail, hostname, split, par2, cat, gzip, bzip2 and
PATH is that full path to that program.

Examples

    --bin-path cat=/bin/cat --bin-path bzip2=/home/user/bzip2

=item B<--compress-level=N>

Set the configuration compression level to N.  Default is 3
if Compress::Zlib is installed.

=item B<--config-dir CONFIG_DIR>

Configuration directory for new installations.  Defaults
to /etc/BackupAFS with FHS.  Automatically extracted
from --config-path for existing installations.

=item B<--config-path CONFIG_PATH>

Path to the existing config.pl configuration file for BackupAFS.
This option should be specified for batch upgrades to an
existing installation.  The option should be omitted when
doing a batch new install.

=item B<--cgi-dir CGI_DIR>

Path to Apache's cgi-bin directory where the BackupAFS_Admin
script will be installed.  This option only needs to be
specified for a batch new install.

=item B<--data-dir DATA_DIR>

Path to the BackupAFS data directory.  This is where all the backup
data is stored, and it should be on a large file system. This option
only needs to be specified for a batch new install.

Example:

    --data-dir /data/BackupAFS

=item B<--dest-dir DEST_DIR>

An optional prefix to apply to all installation directories.
Usually this is not needed, but certain auto-installers like
to stage an install in a temporary directory, and then copy
the files to their real destination.  This option can be used
to specify the temporary directory prefix.  Note that if you
specify this option, BackupAFS won't run correctly if you try
to run it from below the --dest-dir directory, since all the
paths are set assuming BackupAFS is installed in the intended
final locations.

=item B<--fhs>

Use locations specified by the Filesystem Hierarchy Standard
for installing BackupAFS.  This is enabled by default for new
installations.  To use the pre-3.0 installation locations,
specify --no-fhs.

=item B<--help|?>

Print a brief help message and exits.

=item B<--hostname HOSTNAME>

Host name (this machine's name) on which BackupAFS is being installed.
This option only needs to be specified for a batch new install.

=item B<--html-dir HTML_DIR>

Path to an Apache html directory where various BackupAFS image files
and the CSS files will be installed.  This is typically a directory
below Apache's DocumentRoot directory.  This option only needs to be
specified for a batch new install.

Example:

    --html-dir /var/www/htdocs/BackupAFS

=item B<--html-dir-url URL>

The URL (without http://hostname) required to access the BackupAFS html
directory specified with the --html-dir option.  This option only needs
to be specified for a batch new install.

Example:

    --html-dir-url /BackupAFS

=item B<--install-dir INSTALL_DIR>

Installation directory for BackupAFS scripts, libraries, and
documentation.  This option only needs to be specified for a
batch new install.

Example:

    --install-dir /usr/local/BackupAFS

=item B<--log-dir LOG_DIR>

Log directory.  Defaults to /var/log/BackupAFS with FHS.

=item B<--man>

Prints the manual page and exits.

=item B<--set-perms>

When installing files and creating directories, chown them to
the BackupAFS user and chmod them too.  This is enabled by default.
To disable (for example, if staging a destination directory)
then specify --no-set-perms.

=item B<--uid-ignore>

configure.pl verifies that the script is being run as the super user
(root).  Without the --uid-ignore option, in batch mode the script will
exit with an error if not run as the super user, and in interactive mode
the user will be prompted.  Specifying this option will cause the script
to continue even if the user id is not root.

=head1 EXAMPLES

For a standard interactive install, run without arguments:

    configure.pl

For a batch new install you need to specify answers to all the
questions that are normally prompted:

    configure.pl                                   \
        --batch                                    \
        --cgi-dir /var/www/cgi-bin/BackupAFS        \
        --data-dir /data/BackupAFS                  \
        --hostname myHost                          \
        --html-dir /var/www/html/BackupAFS          \
        --html-dir-url /BackupAFS                   \
        --install-dir /usr/local/BackupAFS

For a batch upgrade, you only need to specify the path to the
configuration file:
        
    configure.pl --batch --config-path /data/BackupAFS/conf/config.pl

=head1 AUTHOR

Craig Barratt  <cbarratt@users.sourceforge.net>

=head1 COPYRIGHT

Copyright (C) 2001-2009  Craig Barratt.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 3 ONLY.


=cut
