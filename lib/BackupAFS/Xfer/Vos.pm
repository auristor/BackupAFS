#============================================================= -*-perl-*-
#
# BackupAFS::Xfer::Vos package
#
# DESCRIPTION
#
#   This library defines a BackupAFS::Xfer::Vos class for managing
#   the voswrap-based transport of backup data from the client.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce  <stephen@physics.unc.edu>
#    - AFS support based on Craig's existing beta backupafsd method
#
# COPYRIGHT
#   Copyright (C) 2006,2007 Craig Barratt
#   Copyright (C) 2007,2010 Stephen Joyce
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
# See http://backupafs.sourceforge.net and
#     http://www.physics.unc.edu/~stephen/backupafs
#
#========================================================================

package BackupAFS::Xfer::Vos;

use strict;

sub new
{
    my($class, $bafs, $args) = @_;

    $args ||= {};
    my $t = bless {
        bafs       => $bafs,
        conf      => { $bafs->Conf },
        volset      => "",
        volsetIP    => "",
        shareName => "",
        badFiles  => [],

	#
	# Various stats
	#
        byteCnt         => 0,
	fileCnt         => 0,
	xferErrCnt      => 0,
	xferBadShareCnt => 0,
	xferBadFileCnt  => 0,
	xferOK          => 0,

	#
	# User's args
	#
        %$args,
    }, $class;

    return $t;
}

sub args
{
    my($t, $args) = @_;

    foreach my $arg ( keys(%$args) ) {
	$t->{$arg} = $args->{$arg};
    }
}

sub useTar
{
    return 0;
}

sub start
{
    my($t) = @_;
    my $bafs = $t->{bafs};
    my $conf = $t->{conf};
    my(@fileList, $voswrapCmd, $voswrapArgs, $logMsg, $incrDate, $incrLevel, 
        $incrFlag, $restoreDir);

    #
    # We add a slash to the share name we pass to voswrap
    #
    ($t->{shareNameSlash} = "$t->{shareName}/") =~ s{//+$}{/};

    if ( $t->{type} eq "restore" ) {
	$voswrapCmd = "$conf->{InstallDir}/bin/BackupAFS_vosWrapper $conf->{AfsVosRestoreArgs}";
	$restoreDir = "$t->{shareName}/$t->{pathHdrDest}";
	$restoreDir    =~ s{//+}{/}g;
        $logMsg = "restore started of volume $t->{shareName}";
    } else {
        if ( $t->{type} eq "full" ) {
	    if ( $t->{partialNum} ) {
		$logMsg = "full backup started for volume $t->{shareName};"
		        . " updating partial $t->{partialNum}";
	    } else {
		$logMsg = "Level 0 full backup started for volume $t->{shareName}";
	    }
            $incrFlag = 0;
        } else {
            $incrDate = $bafs->timeStamp($t->{incrBaseTime} - 300, 1);
		# 300 is the value (in seconds) of acceptable clock-
		# drift. It's better to back up a small amount of data
		# twice than miss some due to drifting clocks.
	    $incrLevel = $t->{incrLevel};
            #$logMsg = "incr backup started back to $incrDate"
            #        . " (backup #$t->{incrBaseBkupNum}) for volume "
            #        . " $t->{shareName} (level $incrLevel).";
            $logMsg = "Level $incrLevel incr backup started for volume $t->{shareName}.\n"
                    . " Will backup all changes since $incrDate (backup #$t->{incrBaseBkupNum}).";
            $incrFlag = 1;
        }
	$voswrapCmd = "$conf->{InstallDir}/bin/BackupAFS_vosWrapper $conf->{AfsVosBackupArgs}";
    }

    #
    # Merge variables into $voswrapCmd
    #
    my $args = {
	volset           => $t->{volset},
	volsetIP         => $t->{volsetIP},
	client         => $t->{client},
	type           => $t->{type},
	incrDate       => $bafs->timeStamp($t->{incrBaseTime} - 3600, 1),
	incrLevel      => $incrLevel,
	shareName      => $t->{shareName},
	shareNameSlash => $t->{shareNameSlash},
	restoreDir     => $restoreDir,
	topDir         => $bafs->TopDir(),
        poolDir        => $t->{compress} ? $bafs->{CPoolDir} : $bafs->{PoolDir},
        poolCompress   => $t->{compress} + 0,
	incrFlag       => $incrFlag,
	bkupSrcNum     => $t->{bkupSrcNum},
	bkupSrcVolSet    => $t->{bkupSrcVolSet},
        fileList       => $t->{fileList},
    };
    $voswrapCmd = $bafs->cmdVarSubstitute($voswrapCmd, $args);

    $t->{voswrapCmd} = $voswrapCmd;

    delete($t->{_errStr});

    return $logMsg;
}

sub run
{
    my($t) = @_;
    my $bafs = $t->{bafs};
    my $conf = $t->{conf};
    my($remoteSend, $remoteDir, $remoteDirDaemon);
    my $error;
    my $errStr;
    my $stats;

    # NO: alarm($conf->{ClientTimeout});

    #
    # Run backupcd command
    #
    my $str = "Running: "
            . $t->{bafs}->execCmd2ShellCmd(@{$t->{voswrapCmd}})
            . "\n";
    $t->{XferLOG}->write(\$str);

    #
    #
    #
    
    $bafs->cmdSystemOrEvalLong($t->{voswrapCmd},
        sub {
            # write stdout to the XferLOG
            my($str) = @_;
            $t->{XferLOG}->write(\$str);
		if ($str =~/Total files:/) {
			$str=~s/Total files://g;
			$stats->{TotalFileCnt}=$stats->{TotalFileCnt}+$str;
		}
		if ($str =~/Total bytes:/) {
			$str=~s/Total bytes://g;
			$stats->{TotalFileSize}=$stats->{TotalFileSize}+$str;
		}
		if ($str =~/rror/) {
			$stats->{errorCnt}++;
		}
        }, 
        0,                  # also catch stderr
        $t->{pidHandler} 
    );
    if ( $? ) {
    	($t->{_errStr} = $errStr) =~ s/[\n\r]+//;
        return;
    }

    #
    # TODO: generate sensible stats by parsing the output of
    # voswrap.  Get error and fail status.
    #
    if ( !defined($error) && defined($stats) ) {
	$t->{xferOK} = 1;
    } else {
	$t->{xferOK} = 0;
    }
    $t->{xferErrCnt} = $stats->{errorCnt};
    $t->{byteCnt}    = $stats->{TotalFileSize};
    $t->{fileCnt}    = $stats->{TotalFileCnt};
    my $str = "Done: $t->{fileCnt} files, $t->{byteCnt} bytes\n\n";
    $t->{XferLOG}->write(\$str);

    $t->{volsetError} = $error if ( defined($error) );

    if ( $t->{type} eq "restore" ) {
	return (
	    $t->{fileCnt},
	    $t->{byteCnt},
	    0,
	    0
	);
    } else {
	return (
	    0,
	    0,
	    0,
	    0,
	    $stats->{TotalFileCnt},
	    $stats->{TotalFileSize}
	);
    }
}

sub abort
{
    my($t, $reason) = @_;

    # TODO
    return 1;
}

sub errStr
{
    my($t) = @_;

    return $t->{_errStr};
}

sub xferPid
{
    my($t) = @_;

    return ();
}

#
# Returns a hash ref giving various status information about
# the transfer.
#
sub getStats
{
    my($t) = @_;

    return { map { $_ => $t->{$_} }
            qw(byteCnt fileCnt xferErrCnt xferBadShareCnt xferBadFileCnt
               xferOK volsetAbort volsetError lastOutputLine)
    };
}

sub getBadFiles
{
    my($t) = @_;

    return @{$t->{badFiles}};
}

1;
