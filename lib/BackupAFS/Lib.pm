#============================================================= -*-perl-*-
#
# BackupAFS::Lib package
#
# DESCRIPTION
#
#   This library defines a BackupAFS::Lib class and a variety of utility
#   functions used by BackupAFS.
#
# AUTHORS
#   Stephen Joyce <stephen@physics.unc.edu>
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2010 Stephen Joyce
#   Copyright (C) 2001-2009 Craig Barratt
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

package BackupAFS::Lib;

use strict;

use vars qw(%Conf %Lang);
use BackupAFS::Storage;
use Fcntl ':mode';
use Carp;
use File::Path;
use File::Compare;
use Socket;
use Cwd;
use Digest::MD5;
use Config;
use Encode qw/from_to encode_utf8/;

use vars qw( $IODirentOk $IODirentLoaded );
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw( BPC_DT_UNKNOWN
                 BPC_DT_FIFO
                 BPC_DT_CHR
                 BPC_DT_DIR
                 BPC_DT_BLK
                 BPC_DT_REG
                 BPC_DT_LNK
                 BPC_DT_SOCK
               );
@EXPORT = qw( );
%EXPORT_TAGS = ('BPC_DT_ALL' => [@EXPORT, @EXPORT_OK]);

BEGIN {
    eval "use IO::Dirent qw( readdirent DT_DIR );";
    $IODirentLoaded = 1 if ( !$@ );
};

#
# The need to match the constants in IO::Dirent
#
use constant BPC_DT_UNKNOWN =>   0;
use constant BPC_DT_FIFO    =>   1;    ## named pipe (fifo)
use constant BPC_DT_CHR     =>   2;    ## character special
use constant BPC_DT_DIR     =>   4;    ## directory
use constant BPC_DT_BLK     =>   6;    ## block special
use constant BPC_DT_REG     =>   8;    ## regular
use constant BPC_DT_LNK     =>  10;    ## symbolic link
use constant BPC_DT_SOCK    =>  12;    ## socket

sub new
{
    my $class = shift;
    my($topDir, $installDir, $confDir, $noUserCheck) = @_;

    #
    # Whether to use filesystem hierarchy standard for file layout.
    # If set, text config files are below /etc/BackupAFS.
    #
    my $useFHS = 0;
    my $paths;

    #
    # Set defaults for $topDir and $installDir.
    #
    $topDir     = '__TOPDIR__' if ( $topDir eq "" );
    $installDir = '__INSTALLDIR__'    if ( $installDir eq "" );

    #
    # Pick some initial defaults.  For FHS the only critical
    # path is the ConfDir, since we get everything else out
    # of the main config file.
    #
    if ( $useFHS ) {
        $paths = {
            useFHS     => $useFHS,
            TopDir     => $topDir,
            InstallDir => $installDir,
            ConfDir    => $confDir eq "" ? '__CONFDIR__' : $confDir,
            LogDir     => '/var/log/BackupAFS',
        };
    } else {
        $paths = {
            useFHS     => $useFHS,
            TopDir     => $topDir,
            InstallDir => $installDir,
            ConfDir    => $confDir eq "" ? "$topDir/conf" : $confDir,
            LogDir     => "$topDir/log",
        };
    }

    my $bafs = bless {
	%$paths,
        Version => '1.0.0',
    }, $class;

    $bafs->{storage} = BackupAFS::Storage->new($paths);

    #
    # Clean up %ENV and setup other variables.
    #
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
    if ( defined(my $error = $bafs->ConfigRead()) ) {
        print(STDERR $error, "\n");
        return;
    }

    #
    # Update the paths based on the config file
    #
    foreach my $dir ( qw(TopDir ConfDir InstallDir LogDir) ) {
        next if ( $bafs->{Conf}{$dir} eq "" );
        $paths->{$dir} = $bafs->{$dir} = $bafs->{Conf}{$dir};
    }
    $bafs->{storage}->setPaths($paths);

    #
    # Verify we are running as the correct user
    #
    if ( !$noUserCheck
	    && $bafs->{Conf}{BackupAFSUserVerify}
	    && $> != (my $uid = (getpwnam($bafs->{Conf}{BackupAFSUser}))[2]) ) {
	print(STDERR "$0: Wrong user: my userid is $>, instead of $uid"
	    . " ($bafs->{Conf}{BackupAFSUser})\n");
	print(STDERR "Please su $bafs->{Conf}{BackupAFSUser} first\n");
	return;
    }
    return $bafs;
}

sub TopDir
{
    my($bafs) = @_;
    return $bafs->{TopDir};
}

sub BinDir
{
    my($bafs) = @_;
    return "$bafs->{InstallDir}/bin";
}

sub LogDir
{
    my($bafs) = @_;
    return $bafs->{LogDir};
}

sub ConfDir
{
    my($bafs) = @_;
    return $bafs->{ConfDir};
}

sub LibDir
{
    my($bafs) = @_;
    return "$bafs->{InstallDir}/lib";
}

sub InstallDir
{
    my($bafs) = @_;
    return $bafs->{InstallDir};
}

sub useFHS
{
    my($bafs) = @_;
    return $bafs->{useFHS};
}

sub Version
{
    my($bafs) = @_;
    return $bafs->{Version};
}

sub Conf
{
    my($bafs) = @_;
    return %{$bafs->{Conf}};
}

sub Lang
{
    my($bafs) = @_;
    return $bafs->{Lang};
}

sub adminJob
{
    my($bafs, $num) = @_;
    return " admin " if ( !$num );
    return " admin$num ";
}

sub isAdminJob
{
    my($bafs, $str) = @_;
    return $str =~ /^ admin/;
}

sub trashJob
{
    return " trashClean ";
}

sub ConfValue
{
    my($bafs, $param) = @_;

    return $bafs->{Conf}{$param};
}

sub verbose
{
    my($bafs, $param) = @_;

    $bafs->{verbose} = $param if ( defined($param) );
    # XXX
    return 1;
    return $bafs->{verbose};
}

sub sigName2num
{
    my($bafs, $sig) = @_;

    if ( !defined($bafs->{SigName2Num}) ) {
	my $i = 0;
	foreach my $name ( split(' ', $Config{sig_name}) ) {
	    $bafs->{SigName2Num}{$name} = $i;
	    $i++;
	}
    }
    return $bafs->{SigName2Num}{$sig};
}

#
# Generate an ISO 8601 format timeStamp (but without the "T").
# See http://www.w3.org/TR/NOTE-datetime and
# http://www.cl.cam.ac.uk/~mgk25/iso-time.html
#
sub timeStamp
{
    my($bafs, $t, $noPad) = @_;
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
              = localtime($t || time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
		    $year + 1900, $mon + 1, $mday, $hour, $min, $sec)
	     . ($noPad ? "" : " ");
}

sub BackupInfoRead
{
    my($bafs, $volset) = @_;

    return $bafs->{storage}->BackupInfoRead($volset);
}

sub BackupInfoWrite
{
    my($bafs, $volset, @Backups) = @_;

    return $bafs->{storage}->BackupInfoWrite($volset, @Backups);
}

sub RestoreInfoRead
{
    my($bafs, $volset) = @_;

    return $bafs->{storage}->RestoreInfoRead($volset);
}

sub RestoreInfoWrite
{
    my($bafs, $volset, @Restores) = @_;

    return $bafs->{storage}->RestoreInfoWrite($volset, @Restores);
}

sub ArchiveInfoRead
{
    my($bafs, $volset) = @_;

    return $bafs->{storage}->ArchiveInfoRead($volset);
}

sub ArchiveInfoWrite
{
    my($bafs, $volset, @Archives) = @_;

    return $bafs->{storage}->ArchiveInfoWrite($volset, @Archives);
}

sub ConfigDataRead
{
    my($bafs, $volset) = @_;

    return $bafs->{storage}->ConfigDataRead($volset);
}

sub ConfigDataWrite
{
    my($bafs, $volset, $conf) = @_;

    return $bafs->{storage}->ConfigDataWrite($volset, $conf);
}

sub ConfigRead
{
    my($bafs, $volset) = @_;
    my($ret);

    #
    # Read main config file
    #
    my($mesg, $config) = $bafs->{storage}->ConfigDataRead();
    return $mesg if ( defined($mesg) );

    $bafs->{Conf} = $config;

    #
    # Read volset config file
    #
    if ( $volset ne "" ) {
	($mesg, $config) = $bafs->{storage}->ConfigDataRead($volset, $config);
	return $mesg if ( defined($mesg) );
	$bafs->{Conf} = $config;
    }

    #
    # Load optional perl modules
    #
    if ( defined($bafs->{Conf}{PerlModuleLoad}) ) {
        #
        # Load any user-specified perl modules.  This is for
        # optional user-defined extensions.
        #
        $bafs->{Conf}{PerlModuleLoad} = [$bafs->{Conf}{PerlModuleLoad}]
                    if ( ref($bafs->{Conf}{PerlModuleLoad}) ne "ARRAY" );
        foreach my $module ( @{$bafs->{Conf}{PerlModuleLoad}} ) {
            eval("use $module;");
        }
    }

    #
    # Load language file
    #
    return "No language setting" if ( !defined($bafs->{Conf}{Language}) );
    my $langFile = "$bafs->{InstallDir}/lib/BackupAFS/Lang/$bafs->{Conf}{Language}.pm";
    if ( !defined($ret = do $langFile) && ($! || $@) ) {
	$mesg = "Couldn't open language file $langFile: $!" if ( $! );
	$mesg = "Couldn't execute language file $langFile: $@" if ( $@ );
	$mesg =~ s/[\n\r]+//;
	return $mesg;
    }
    $bafs->{Lang} = \%Lang;

    #
    # Make sure IncrLevels is defined
    #
    $bafs->{Conf}{IncrLevels} = [1] if ( !defined($bafs->{Conf}{IncrLevels}) );

    return;
}

#
# Return the mtime of the config file
#
sub ConfigMTime
{
    my($bafs) = @_;

    return $bafs->{storage}->ConfigMTime();
}

#
# Returns information from the volset file in $bafs->{TopDir}/conf/volsets.
# With no argument a ref to a hash of volsets is returned.  Each
# hash contains fields as specified in the volsets file.  With an
# argument a ref to a single hash is returned with information
# for just that volset.
#
sub VolSetInfoRead
{
    my($bafs, $volset) = @_;

    return $bafs->{storage}->VolSetInfoRead($volset);
}

sub VolSetInfoWrite
{
    my($bafs, $volset) = @_;

    return $bafs->{storage}->VolSetInfoWrite($volset);
}

#
# Return the mtime of the volsets file
#
sub VolSetsMTime
{
    my($bafs) = @_;

    return $bafs->{storage}->VolSetsMTime();
}

#
# Read a directory and return the entries in sorted inode order.
# This relies on the IO::Dirent module being installed.  If not,
# the inode data is empty and the default directory order is
# returned.
#
# The returned data is a list of hashes with entries {name, type, inode, nlink}.
# The returned data includes "." and "..".
#
# $need is a hash of file attributes we need: type, inode, or nlink.
# If set, these parameters are added to the returned hash.
#
# To support browsing pre-3.0.0 backups where the charset encoding
# is typically iso-8859-1, the charsetLegacy option can be set in
# $need to convert the path from utf8 and convert the names to utf8.
#
# If IO::Dirent is successful if will get type and inode for free.
# Otherwise, a stat is done on each file, which is more expensive.
#
sub dirRead
{
    my($bafs, $path, $need) = @_;
    my(@entries, $addInode);

    from_to($path, "utf8", $need->{charsetLegacy})
                        if ( $need->{charsetLegacy} ne "" );
    return if ( !opendir(my $fh, $path) );
    if ( $IODirentLoaded && !$IODirentOk ) {
        #
        # Make sure the IO::Dirent really works - some installs
        # on certain file systems (eg: XFS) don't return a valid type.
        #
        if ( opendir(my $fh, $bafs->{TopDir}) ) {
            my $dt_dir = eval("DT_DIR");
            foreach my $e ( readdirent($fh) ) {
                if ( $e->{name} eq "." && $e->{type} == $dt_dir ) {
                    $IODirentOk = 1;
                    last;
                }
            }
            closedir($fh);
        }
        #
        # if it isn't ok then don't check again.
        #
        $IODirentLoaded = 0 if ( !$IODirentOk );
    }
    if ( $IODirentOk ) {
        @entries = sort({ $a->{inode} <=> $b->{inode} } readdirent($fh));
        #map { $_->{type} = 0 + $_->{type} } @entries;   # make type numeric
	map { $_->{type} = 0 + $_->{type}; $_->{type} = undef if ($_->{type} eq BPC_DT_UNKNOWN); } @entries;   # make type numeric, unset unknown types
    } else {
        @entries = map { { name => $_} } readdir($fh);
    }
    closedir($fh);
    if ( defined($need) ) {
        for ( my $i = 0 ; $i < @entries ; $i++ ) {
            next if ( (!$need->{inode} || defined($entries[$i]{inode}))
                   && (!$need->{type}  || defined($entries[$i]{type}))
                   && (!$need->{nlink} || defined($entries[$i]{nlink})) );
            my @s = stat("$path/$entries[$i]{name}");
            $entries[$i]{nlink} = $s[3] if ( $need->{nlink} );
            if ( $need->{inode} && !defined($entries[$i]{inode}) ) {
                $addInode = 1;
                $entries[$i]{inode} = $s[1];
            }
            if ( $need->{type} && !defined($entries[$i]{type}) ) {
                my $mode = S_IFMT($s[2]);
                $entries[$i]{type} = BPC_DT_FIFO if ( S_ISFIFO($mode) );
                $entries[$i]{type} = BPC_DT_CHR  if ( S_ISCHR($mode) );
                $entries[$i]{type} = BPC_DT_DIR  if ( S_ISDIR($mode) );
                $entries[$i]{type} = BPC_DT_BLK  if ( S_ISBLK($mode) );
                $entries[$i]{type} = BPC_DT_REG  if ( S_ISREG($mode) );
                $entries[$i]{type} = BPC_DT_LNK  if ( S_ISLNK($mode) );
                $entries[$i]{type} = BPC_DT_SOCK if ( S_ISSOCK($mode) );
            }
        }
    }
    #
    # Sort the entries if inodes were added (the IO::Dirent case already
    # sorted above)
    #
    @entries = sort({ $a->{inode} <=> $b->{inode} } @entries) if ( $addInode );
    #
    # for browing pre-3.0.0 backups, map iso-8859-1 to utf8 if requested
    #
    if ( $need->{charsetLegacy} ne "" ) {
        for ( my $i = 0 ; $i < @entries ; $i++ ) {
            from_to($entries[$i]{name}, $need->{charsetLegacy}, "utf8");
        }
    }
    return \@entries;
}

#
# Same as dirRead, but only returns the names (which will be sorted in
# inode order if IO::Dirent is installed)
#
sub dirReadNames
{
    my($bafs, $path, $need) = @_;

    my $entries = $bafs->dirRead($path, $need);
    return if ( !defined($entries) );
    my @names = map { $_->{name} } @$entries;
    return \@names;
}

sub find
{
    my($bafs, $param, $dir, $dontDoCwd) = @_;

    return if ( !chdir($dir) );
    my $entries = $bafs->dirRead(".", {inode => 1, type => 1});
    #print Dumper($entries);
    foreach my $f ( @$entries ) {
        next if ( $f->{name} eq ".." || $f->{name} eq "." && $dontDoCwd );
        $param->{wanted}($f->{name}, "$dir/$f->{name}");
        next if ( $f->{type} != BPC_DT_DIR || $f->{name} eq "." );
        chdir($f->{name});
        $bafs->find($param, "$dir/$f->{name}", 1);
        return if ( !chdir("..") );
    }
}

#
# Stripped down from File::Path.  In particular we don't print
# many warnings and we try three times to delete each directory
# and file -- for some reason the original File::Path rmtree
# didn't always completely remove a directory tree on a NetApp.
#
# Warning: this routine changes the cwd.
#
sub RmTreeQuiet
{
    my($bafs, $pwd, $roots) = @_;
    my(@files, $root);

    if ( defined($roots) && length($roots) ) {
      $roots = [$roots] unless ref $roots;
    } else {
      print(STDERR "RmTreeQuiet: No root path(s) specified\n");
    }
    chdir($pwd);
    foreach $root (@{$roots}) {
	$root = $1 if ( $root =~ m{(.*?)/*$} );
	#
	# Try first to simply unlink the file: this avoids an
	# extra stat for every file.  If it fails (which it
	# will for directories), check if it is a directory and
	# then recurse.
	#
	if ( !unlink($root) ) {
            if ( -d $root ) {
                my $d = $bafs->dirReadNames($root);
		if ( !defined($d) ) {
		    print(STDERR "Can't read $pwd/$root: $!\n");
		} else {
		    @files = grep $_ !~ /^\.{1,2}$/, @$d;
		    $bafs->RmTreeQuiet("$pwd/$root", \@files);
		    chdir($pwd);
		    rmdir($root) || rmdir($root);
		}
            } else {
                unlink($root) || unlink($root);
            }
        }
    }
}

#
# Move a directory or file away for later deletion
#
sub RmTreeDefer
{
    my($bafs, $trashDir, $file) = @_;
    my($i, $f);

    return if ( !-e $file );
    if ( !-d $trashDir ) {
        eval { mkpath($trashDir, 0, 0777) };
        if ( $@ ) {
            #
            # There's no good place to send this error - use stderr
            #
            print(STDERR "RmTreeDefer: can't create directory $trashDir");
        }
    }
    for ( $i = 0 ; $i < 1000 ; $i++ ) {
        $f = sprintf("%s/%d_%d_%d", $trashDir, time, $$, $i);
        next if ( -e $f );
        return if ( rename($file, $f) );
    }
    # shouldn't get here, but might if you tried to call this
    # across file systems.... just remove the tree right now.
    if ( $file =~ /(.*)\/([^\/]*)/ ) {
        my($d) = $1;
        my($f) = $2;
        my($cwd) = Cwd::fastcwd();
        $cwd = $1 if ( $cwd =~ /(.*)/ );
        $bafs->RmTreeQuiet($d, $f);
        chdir($cwd) if ( $cwd );
    }
}

#
# Empty the trash directory.  Returns 0 if it did nothing, 1 if it
# did something, -1 if it failed to remove all the files.
#
sub RmTreeTrashEmpty
{
    my($bafs, $trashDir) = @_;
    my(@files);
    my($cwd) = Cwd::fastcwd();

    $cwd = $1 if ( $cwd =~ /(.*)/ );
    return if ( !-d $trashDir );
    my $d = $bafs->dirReadNames($trashDir) or carp "Can't read $trashDir: $!";
    @files = grep $_ !~ /^\.{1,2}$/, @$d;
    return 0 if ( !@files );
    $bafs->RmTreeQuiet($trashDir, \@files);
    foreach my $f ( @files ) {
	return -1 if ( -e $f );
    }
    chdir($cwd) if ( $cwd );
    return 1;
}

#
# Open a connection to the server.  Returns an error string on failure.
# Returns undef on success.
#
sub ServerConnect
{
    my($bafs, $volset, $port, $justConnect) = @_;
    local(*FH);

    return if ( defined($bafs->{ServerFD}) );
    #
    # First try the unix-domain socket
    #
    my $sockFile = "$bafs->{LogDir}/BackupAFS.sock";
    socket(*FH, PF_UNIX, SOCK_STREAM, 0)     || return "unix socket: $!";
    if ( !connect(*FH, sockaddr_un($sockFile)) ) {
        my $err = "unix connect: $!";
        close(*FH);
        if ( $port > 0 ) {
            my $proto = getprotobyname('tcp');
            my $iaddr = inet_aton($volset)     || return "unknown volset $volset";
            my $paddr = sockaddr_in($port, $iaddr);

            socket(*FH, PF_INET, SOCK_STREAM, $proto)
                                             || return "inet socket: $!";
            connect(*FH, $paddr)             || return "inet connect: $!";
        } else {
            return $err;
        }
    }
    my($oldFH) = select(*FH); $| = 1; select($oldFH);
    $bafs->{ServerFD} = *FH;
    return if ( $justConnect );
    #
    # Read the seed that we need for our MD5 message digest.  See
    # ServerMesg below.
    #
    sysread($bafs->{ServerFD}, $bafs->{ServerSeed}, 1024);
    $bafs->{ServerMesgCnt} = 0;
    return;
}

#
# Check that the server connection is still ok
#
sub ServerOK
{
    my($bafs) = @_;

    return 0 if ( !defined($bafs->{ServerFD}) );
    vec(my $FDread, fileno($bafs->{ServerFD}), 1) = 1;
    my $ein = $FDread;
    return 0 if ( select(my $rout = $FDread, undef, $ein, 0.0) < 0 );
    return 1 if ( !vec($rout, fileno($bafs->{ServerFD}), 1) );
}

#
# Disconnect from the server
#
sub ServerDisconnect
{
    my($bafs) = @_;
    return if ( !defined($bafs->{ServerFD}) );
    close($bafs->{ServerFD});
    delete($bafs->{ServerFD});
}

#
# Sends a message to the server and returns with the reply.
#
# To avoid possible attacks via the TCP socket interface, every client
# message is protected by an MD5 digest. The MD5 digest includes four
# items:
#   - a seed that is sent to us when we first connect
#   - a sequence number that increments for each message
#   - a shared secret that is stored in $Conf{ServerMesgSecret}
#   - the message itself.
# The message is sent in plain text preceded by the MD5 digest. A
# snooper can see the plain-text seed sent by BackupAFS and plain-text
# message, but cannot construct a valid MD5 digest since the secret in
# $Conf{ServerMesgSecret} is unknown. A replay attack is not possible
# since the seed changes on a per-connection and per-message basis.
#
sub ServerMesg
{
    my($bafs, $mesg) = @_;
    return if ( !defined(my $fh = $bafs->{ServerFD}) );
    $mesg =~ s/\n/\\n/g;
    $mesg =~ s/\r/\\r/g;
    my $md5 = Digest::MD5->new;
    $mesg = encode_utf8($mesg);
    $md5->add($bafs->{ServerSeed} . $bafs->{ServerMesgCnt}
            . $bafs->{Conf}{ServerMesgSecret} . $mesg);
    print($fh $md5->b64digest . " $mesg\n");
    $bafs->{ServerMesgCnt}++;
    return <$fh>;
}

#
# Do initialization for child processes
#
sub ChildInit
{
    my($bafs) = @_;
    close(STDERR);
    open(STDERR, ">&STDOUT");
    select(STDERR); $| = 1;
    select(STDOUT); $| = 1;
    $ENV{PATH} = $bafs->{Conf}{MyPath};
}

#
# Compute the MD5 digest of a file.  For efficiency we don't
# use the whole file for big files:
#   - for files <= 256K we use the file size and the whole file.
#   - for files <= 1M we use the file size, the first 128K and
#     the last 128K.
#   - for files > 1M, we use the file size, the first 128K and
#     the 8th 128K (ie: the 128K up to 1MB).
# See the documentation for a discussion of the tradeoffs in
# how much data we use and how many collisions we get.
#
# Returns the MD5 digest (a hex string) and the file size.
#
sub File2MD5
{
    my($bafs, $md5, $name) = @_;
    my($data, $fileSize);
    local(*N);

    $fileSize = (stat($name))[7];
    return ("", -1) if ( !-f _ );
    $name = $1 if ( $name =~ /(.*)/ );
    return ("", 0) if ( $fileSize == 0 );
    return ("", -1) if ( !open(N, $name) );
    binmode(N);
    $md5->reset();
    $md5->add($fileSize);
    if ( $fileSize > 262144 ) {
        #
        # read the first and last 131072 bytes of the file,
        # up to 1MB.
        #
        my $seekPosn = ($fileSize > 1048576 ? 1048576 : $fileSize) - 131072;
        $md5->add($data) if ( sysread(N, $data, 131072) );
        $md5->add($data) if ( sysseek(N, $seekPosn, 0)
                                && sysread(N, $data, 131072) );
    } else {
        #
        # read the whole file
        #
        $md5->add($data) if ( sysread(N, $data, $fileSize) );
    }
    close(N);
    return ($md5->hexdigest, $fileSize);
}

#
# Compute the MD5 digest of a buffer (string).  For efficiency we don't
# use the whole string for big strings:
#   - for files <= 256K we use the file size and the whole file.
#   - for files <= 1M we use the file size, the first 128K and
#     the last 128K.
#   - for files > 1M, we use the file size, the first 128K and
#     the 8th 128K (ie: the 128K up to 1MB).
# See the documentation for a discussion of the tradeoffs in
# how much data we use and how many collisions we get.
#
# Returns the MD5 digest (a hex string).
#
sub Buffer2MD5
{
    my($bafs, $md5, $fileSize, $dataRef) = @_;

    $md5->reset();
    $md5->add($fileSize);
    if ( $fileSize > 262144 ) {
        #
        # add the first and last 131072 bytes of the string,
        # up to 1MB.
        #
        my $seekPosn = ($fileSize > 1048576 ? 1048576 : $fileSize) - 131072;
        $md5->add(substr($$dataRef, 0, 131072));
        $md5->add(substr($$dataRef, $seekPosn, 131072));
    } else {
        #
        # add the whole string
        #
        $md5->add($$dataRef);
    }
    return $md5->hexdigest;
}

#
# Given an MD5 digest $d and a compress flag, return the full
# path in the pool.
#
sub MD52Path
{
    my($bafs, $d, $compress, $poolDir) = @_;

    return if ( $d !~ m{(.)(.)(.)(.*)} );
    $poolDir = ($compress ? $bafs->{CPoolDir} : $bafs->{PoolDir})
		    if ( !defined($poolDir) );
    return "$poolDir/$1/$2/$3/$1$2$3$4";
}

#
# Tests if we can create a hardlink from a file in directory
# $newDir to a file in directory $targetDir.  A temporary
# file in $targetDir is created and an attempt to create a
# hardlink of the same name in $newDir is made.  The temporary
# files are removed.
#
# Like link(), returns true on success and false on failure.
#
sub HardlinkTest
{
    my($bafs, $targetDir, $newDir) = @_;

    my($targetFile, $newFile, $fd);
    for ( my $i = 0 ; ; $i++ ) {
        $targetFile = "$targetDir/.TestFileLink.$$.$i";
        $newFile    = "$newDir/.TestFileLink.$$.$i";
        last if ( !-e $targetFile && !-e $newFile );
    }
    return 0 if ( !open($fd, ">", $targetFile) );
    close($fd);
    my $ret = link($targetFile, $newFile);
    unlink($targetFile);
    unlink($newFile);
    return $ret;
}

sub CheckVolSetAlive
{
    my($bafs, $volset) = @_;
    my($s, $pingCmd, $ret);

    #
    # Return success if the ping cmd is undefined or empty.
    #
    if ( $bafs->{Conf}{PingCmd} eq "" ) {
	print(STDERR "CheckVolSetAlive: return ok because \$Conf{PingCmd}"
	           . " is empty\n") if ( $bafs->{verbose} );
	return 0;
    }

    my $args = {
	pingPath => $bafs->{Conf}{PingPath},
	volset     => $volset,
    };
    $pingCmd = $bafs->cmdVarSubstitute($bafs->{Conf}{PingCmd}, $args);

    #
    # Do a first ping in case the PC needs to wakeup
    #
    $s = $bafs->cmdSystemOrEval($pingCmd, undef, $args);
    if ( $? ) {
	print(STDERR "CheckVolSetAlive: first ping failed ($?, $!)\n")
			if ( $bafs->{verbose} );
	return -1;
    }

    #
    # Do a second ping and get the round-trip time in msec
    #
    $s = $bafs->cmdSystemOrEval($pingCmd, undef, $args);
    if ( $? ) {
	print(STDERR "CheckVolSetAlive: second ping failed ($?, $!)\n")
			if ( $bafs->{verbose} );
	return -1;
    }
    if ( $s =~ /rtt\s*min\/avg\/max\/mdev\s*=\s*[\d.]+\/([\d.]+)\/[\d.]+\/[\d.]+\s*(ms|usec)/i ) {
        $ret = $1;
        $ret /= 1000 if ( lc($2) eq "usec" );
    } elsif ( $s =~ /time=([\d.]+)\s*(ms|usec)/i ) {
	$ret = $1;
        $ret /= 1000 if ( lc($2) eq "usec" );
    } else {
	print(STDERR "CheckVolSetAlive: can't extract round-trip time"
	           . " (not fatal)\n") if ( $bafs->{verbose} );
	$ret = 0;
    }
    print(STDERR "CheckVolSetAlive: returning $ret\n") if ( $bafs->{verbose} );
    return $ret;
}

sub CheckFileSystemUsage
{
    my($bafs) = @_;
    my($topDir) = $bafs->{TopDir};
    my($s, $dfCmd);

    return 0 if ( $bafs->{Conf}{DfCmd} eq "" );
    my $args = {
	dfPath   => $bafs->{Conf}{DfPath},
	topDir   => $bafs->{TopDir},
    };
    $dfCmd = $bafs->cmdVarSubstitute($bafs->{Conf}{DfCmd}, $args);
    $s = $bafs->cmdSystemOrEval($dfCmd, undef, $args);
    return 0 if ( $? || $s !~ /(\d+)%/s );
    return $1;
}

#
# Given an IP address, return the volset name and user name via
# NetBios.
#
sub NetBiosInfoGet
{
    my($bafs, $volset) = @_;
    my($netBiosVolSetName, $netBiosUserName);
    my($s, $nmbCmd);
    return ($volset, undef);
}

sub fileNameEltMangle
{
    my($bafs, $name) = @_;

    return "" if ( $name eq "" );
    $name =~ s{([%/\n\r])}{sprintf("%%%02x", ord($1))}eg;
    return "f$name";
}

#
# We store files with every name preceded by "f".  This
# avoids possible name conflicts with other information
# we store in the same directories (eg: attribute info).
# The process of turning a normal path into one with each
# node prefixed with "f" is called mangling.
#
sub fileNameMangle
{
    my($bafs, $name) = @_;

    $name =~ s{/([^/]+)}{"/" . $bafs->fileNameEltMangle($1)}eg;
    $name =~ s{^([^/]+)}{$bafs->fileNameEltMangle($1)}eg;
    return $name;
}

#
# This undoes FileNameMangle
#
sub fileNameUnmangle
{
    my($bafs, $name) = @_;

    $name =~ s{/f}{/}g;
    $name =~ s{^f}{};
    $name =~ s{%(..)}{chr(hex($1))}eg;
    return $name;
}

#
# Escape shell meta-characters with backslashes.
# This should be applied to each argument seperately, not an
# entire shell command.
#
sub shellEscape
{
    my($bafs, $cmd) = @_;

    $cmd =~ s/([][;&()<>{}|^\n\r\t *\$\\'"`?])/\\$1/g;
    return $cmd;
}

#
# For printing exec commands (which don't use a shell) so they look like
# a valid shell command this function should be called with the exec
# args.  The shell command string is returned.
#
sub execCmd2ShellCmd
{
    my($bafs, @args) = @_;
    my $str;

    foreach my $a ( @args ) {
	$str .= " " if ( $str ne "" );
	$str .= $bafs->shellEscape($a);
    }
    return $str;
}

#
# Do a URI-style escape to protect/encode special characters
#
sub uriEsc
{
    my($bafs, $s) = @_;
    $s =~ s{([^\w.\/-])}{sprintf("%%%02X", ord($1));}eg;
    return $s;
}

#
# Do a URI-style unescape to restore special characters
#
sub uriUnesc
{
    my($bafs, $s) = @_;
    $s =~ s{%(..)}{chr(hex($1))}eg;
    return $s;
}

#
# Do variable substitution prior to execution of a command.
#
sub cmdVarSubstitute
{
    my($bafs, $template, $vars) = @_;
    my(@cmd);

    #
    # Return without any substitution if the first entry starts with "&",
    # indicating this is perl code.
    #
    if ( (ref($template) eq "ARRAY" ? $template->[0] : $template) =~ /^\&/ ) {
        return $template;
    }
    if ( ref($template) ne "ARRAY" ) {
	#
	# Split at white space, except if escaped by \
	#
	$template = [split(/(?<!\\)\s+/, $template)];
	#
	# Remove the \ that escaped white space.
	#
        foreach ( @$template ) {
            s{\\(\s)}{$1}g;
        }
    }
    #
    # Merge variables into @cmd
    #
    foreach my $arg ( @$template ) {
        #
        # Replace $VAR with ${VAR} so that both types of variable
        # substitution are supported
        #
        $arg =~ s[\$(\w+)]{\${$1}}g;
        #
        # Replace scalar variables first
        #
        $arg =~ s[\${(\w+)}(\+?)]{
            exists($vars->{$1}) && ref($vars->{$1}) ne "ARRAY"
                ? ($2 eq "+" ? $bafs->shellEscape($vars->{$1}) : $vars->{$1})
                : "\${$1}$2"
        }eg;
        #
        # Now replicate any array arguments; this just works for just one
        # array var in each argument.
        #
        if ( $arg =~ m[(.*)\${(\w+)}(\+?)(.*)] && ref($vars->{$2}) eq "ARRAY" ) {
            my $pre  = $1;
            my $var  = $2;
            my $esc  = $3;
            my $post = $4;
            foreach my $v ( @{$vars->{$var}} ) {
                $v = $bafs->shellEscape($v) if ( $esc eq "+" );
                push(@cmd, "$pre$v$post");
            }
        } else {
            push(@cmd, $arg);
        }
    }
    return \@cmd;
}

#
# Exec or eval a command.  $cmd is either a string on an array ref.
#
# @args are optional arguments for the eval() case; they are not used
# for exec().
#
sub cmdExecOrEval
{
    my($bafs, $cmd, @args) = @_;
    
    if ( (ref($cmd) eq "ARRAY" ? $cmd->[0] : $cmd) =~ /^\&/ ) {
        $cmd = join(" ", $cmd) if ( ref($cmd) eq "ARRAY" );
	print(STDERR "cmdExecOrEval: about to eval perl code $cmd\n")
			if ( $bafs->{verbose} );
        eval($cmd);
        print(STDERR "Perl code fragment for exec shouldn't return!!\n");
        exit(1);
    } else {
        $cmd = [split(/\s+/, $cmd)] if ( ref($cmd) ne "ARRAY" );
	print(STDERR "cmdExecOrEval: about to exec ",
	      $bafs->execCmd2ShellCmd(@$cmd), "\n")
			if ( $bafs->{verbose} );
	alarm(0);
	$cmd = [map { m/(.*)/ } @$cmd];		# untaint
	#
	# force list-form of exec(), ie: no shell even for 1 arg
	#
        exec { $cmd->[0] } @$cmd;
        print(STDERR "Exec failed for @$cmd\n");
        exit(1);
    }
}

#
# System or eval a command.  $cmd is either a string on an array ref.
# $stdoutCB is a callback for output generated by the command.  If it
# is undef then output is returned.  If it is a code ref then the function
# is called with each piece of output as an argument.  If it is a scalar
# ref the output is appended to this variable.
#
# @args are optional arguments for the eval() case; they are not used
# for system().
#
# Also, $? should be set when the CHILD pipe is closed.
#
sub cmdSystemOrEvalLong
{
    my($bafs, $cmd, $stdoutCB, $ignoreStderr, $pidHandlerCB, @args) = @_;
    my($pid, $out, $allOut);
    local(*CHILD);
    
    $? = 0;
    if ( (ref($cmd) eq "ARRAY" ? $cmd->[0] : $cmd) =~ /^\&/ ) {
        $cmd = join(" ", $cmd) if ( ref($cmd) eq "ARRAY" );
	print(STDERR "cmdSystemOrEval: about to eval perl code $cmd\n")
			if ( $bafs->{verbose} );
        $out = eval($cmd);
	$$stdoutCB .= $out if ( ref($stdoutCB) eq 'SCALAR' );
	&$stdoutCB($out)   if ( ref($stdoutCB) eq 'CODE' );
	print(STDERR "cmdSystemOrEval: finished: got output $out\n")
			if ( $bafs->{verbose} );
	return $out        if ( !defined($stdoutCB) );
	return;
    } else {
        $cmd = [split(/\s+/, $cmd)] if ( ref($cmd) ne "ARRAY" );
	print(STDERR "cmdSystemOrEval: about to system ",
	      $bafs->execCmd2ShellCmd(@$cmd), "\n")
			if ( $bafs->{verbose} );
        if ( !defined($pid = open(CHILD, "-|")) ) {
	    my $err = "Can't fork to run @$cmd\n";
	    $? = 1;
	    $$stdoutCB .= $err if ( ref($stdoutCB) eq 'SCALAR' );
	    &$stdoutCB($err)   if ( ref($stdoutCB) eq 'CODE' );
	    return $err        if ( !defined($stdoutCB) );
	    return;
	}
	binmode(CHILD);
	if ( !$pid ) {
	    #
	    # This is the child
	    #
            close(STDERR);
	    if ( $ignoreStderr ) {
		open(STDERR, ">", "/dev/null");
	    } else {
		open(STDERR, ">&STDOUT");
	    }
	    alarm(0);
	    $cmd = [map { m/(.*)/ } @$cmd];		# untaint
	    #
	    # force list-form of exec(), ie: no shell even for 1 arg
	    #
	    exec { $cmd->[0] } @$cmd;
            print(STDERR "Exec of @$cmd failed\n");
            exit(1);
	}

	#
	# Notify caller of child's pid
	#
	&$pidHandlerCB($pid) if ( ref($pidHandlerCB) eq "CODE" );

	#
	# The parent gathers the output from the child
	#
	while ( <CHILD> ) {
	    $$stdoutCB .= $_ if ( ref($stdoutCB) eq 'SCALAR' );
	    &$stdoutCB($_)   if ( ref($stdoutCB) eq 'CODE' );
	    $out .= $_ 	     if ( !defined($stdoutCB) );
	    $allOut .= $_    if ( $bafs->{verbose} );
	}
	$? = 0;
	close(CHILD);
    }
    print(STDERR "cmdSystemOrEval: finished: got output $allOut\n")
			if ( $bafs->{verbose} );
    return $out;
}

#
# The shorter version that sets $ignoreStderr = 0, ie: merges stdout
# and stderr together.
#
sub cmdSystemOrEval
{
    my($bafs, $cmd, $stdoutCB, @args) = @_;

    return $bafs->cmdSystemOrEvalLong($cmd, $stdoutCB, 0, undef, @args);
}

#
# This is sort() compare function, used below.
#
# New client LOG names are LOG.MMYYYY.  Old style names are
# LOG, LOG.0, LOG.1 etc.  Sort them so new names are
# first, and newest to oldest.
#
sub compareLOGName
{
    my $na = $1 if ( $a =~ /LOG\.(\d+)(\.z)?$/ );
    my $nb = $1 if ( $b =~ /LOG\.(\d+)(\.z)?$/ );

    $na = -1 if ( !defined($na) );
    $nb = -1 if ( !defined($nb) );

    if ( length($na) >= 5 && length($nb) >= 5 ) {
        #
        # Both new style: format is MMYYYY.  Bigger dates are
        # more recent.
        #
        my $ma = $2 * 12 + $1 if ( $na =~ /(\d+)(\d{4})/ );
        my $mb = $2 * 12 + $1 if ( $nb =~ /(\d+)(\d{4})/ );
        return $mb - $ma;
    } elsif ( length($na) >= 5 && length($nb) < 5 ) {
        return -1;
    } elsif ( length($na) < 5 && length($nb) >= 5 ) {
        return 1;
    } else {
        #
        # Both old style.  Smaller numbers are more recent.
        #
        return $na - $nb;
    }
}

#
# Returns list of paths to a clients's (or main) LOG files,
# most recent first.
#
sub sortedPCLogFiles
{
    my($bafs, $volset) = @_;

    my(@files, $dir);

    if ( $volset ne "" ) {
        $dir = "$bafs->{TopDir}/volsets/$volset";
    } else {
        $dir = "$bafs->{LogDir}";
    }
    if ( opendir(DIR, $dir) ) {
        foreach my $file ( readdir(DIR) ) {
            next if ( !-f "$dir/$file" );
            next if ( $file ne "LOG" && $file !~ /^LOG\.\d/ );
            push(@files, "$dir/$file");
        }
        closedir(DIR);
    }
    return sort compareLOGName @files;
}

#
# converts a glob-style pattern into a perl regular expression.
#
sub glob2re
{
    my ( $bafs, $glob ) = @_;
    my ( $char, $subst );

    # $escapeChars escapes characters with no special glob meaning but
    # have meaning in regexps.
    my $escapeChars = [ '.', '/', ];

    # $charMap is where we implement the special meaning of glob
    # patterns and translate them to regexps.
    my $charMap = {
                    '?' => '[^/]',
                    '*' => '[^/]*', };

    # multiple forward slashes are equivalent to one slash.  We should
    # never have to use this.
    $glob =~ s/\/+/\//;

    foreach $char (@$escapeChars) {
        $glob =~ s/\Q$char\E/\\$char/g;
    }

    while ( ( $char, $subst ) = each(%$charMap) ) {
        $glob =~ s/(?<!\\)\Q$char\E/$subst/g;
    }

    return $glob;
}

1;
