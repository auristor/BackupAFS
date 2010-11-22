#============================================================= -*-perl-*-
#
# Configuration file for BackupAFS.
#
# DESCRIPTION
#
#   This is the main configuration file for BackupAFS.
#
#   This file must be valid perl source, so make sure the punctuation,
#   quotes, and other syntax are valid.
#
#   This file is read by BackupAFS at startup, when a HUP (-1) signal
#   is sent to BackupAFS and also at each wakeup time whenever the
#   modification time of this file changes.
#
#   The configuration parameters are divided into four general groups.
#   The first group (general server configuration) provides general
#   configuration for BackupAFS.  The next two groups describe what
#   to backup, when to do it, and how long to keep it.  The fourth
#   group are settings for the CGI http interface.
#
#   Configuration settings can also be specified on a per-VolumeSet basis.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2001-2009  Craig Barratt
#   Copyright (C) 2010 Stephen Joyce
#
#   See http://backupafs.sourceforge.net.
#
#========================================================================

###########################################################################
# General server configuration
###########################################################################
#
# Host name on which the BackupAFS server is running.
#
$Conf{ServerHost} = '';

#
# TCP port number on which the BackupAFS server listens for and accepts
# connections.  Normally this should be disabled (set to -1).  The TCP
# port is only needed if apache runs on a different machine from BackupAFS.
# In that case, set this to any spare port number over 1024 (eg: 2359).
# If you enable the TCP port, make sure you set $Conf{ServerMesgSecret}
# too!
#
$Conf{ServerPort} = -1;

#
# Shared secret to make the TCP port secure.  Set this to a hard to guess
# string if you enable the TCP port (ie: $Conf{ServerPort} > 0).
#
# To avoid possible attacks via the TCP socket interface, every client
# message is protected by an MD5 digest. The MD5 digest includes four
# items:
#   - a seed that is sent to the client when the connection opens
#   - a sequence number that increments for each message
#   - a shared secret that is stored in $Conf{ServerMesgSecret}
#   - the message itself.
#
# The message is sent in plain text preceded by the MD5 digest.  A
# snooper can see the plain-text seed sent by BackupAFS and plain-text
# message from the client, but cannot construct a valid MD5 digest since
# the secret $Conf{ServerMesgSecret} is unknown.  A replay attack is
# not possible since the seed changes on a per-connection and
# per-message basis.
#
$Conf{ServerMesgSecret} = '';

#
# PATH setting for BackupAFS.  An explicit value is necessary
# for taint mode.  Value shouldn't matter too much since
# all execs use explicit paths.  However, taint mode in perl
# will complain if this directory is world writable.
#
$Conf{MyPath} = '/bin';

#
# Permission mask for directories and files created by BackupAFS.
# Default value prevents any access from group other, and prevents
# group write.
#
$Conf{UmaskMode} = 027;

#
# Times at which we wake up, check all the VolumeSets, and schedule necessary
# backups.  Times are measured in hours since midnight.  Can be
# fractional if necessary (eg: 4.25 means 4:15am).
#
# If the fileservers hosting the volumes you are backing up are always
# available, and in the same timezone, you might have only one wakeup
# each night.  This will keep the backup activity after hours.
#
# Examples:
#     $Conf{WakeupSchedule} = [22.5];         # once per day at 10:30 pm.
#     $Conf{WakeupSchedule} = [2,4,6,8,10,12,14,16,18,20,22];  # every 2 hours
#
# The default value is every hour except midnight.
#
# The first entry of $Conf{WakeupSchedule} is when BackupAFS_nightly is run.
# You might want to re-arrange the entries in $Conf{WakeupSchedule}
# (they don't have to be ascending) so that the first entry is when
# you want BackupAFS_nightly to run (eg: when you don't expect a lot
# of regular backups to run).
#
$Conf{WakeupSchedule} = [23];

#
# Maximum number of simultaneous backups to run.  If there
# are no user backup requests then this is the maximum number
# of simultaneous backups.
#
$Conf{MaxBackups} = 4;

#
# Additional number of simultaneous backups that users can run.
# As many as $Conf{MaxBackups} + $Conf{MaxUserBackups} requests can
# run at the same time.
#
$Conf{MaxUserBackups} = 4;

#
# Maximum number of pending compress commands. New backups will only be
# started if there are no more than $Conf{MaxPendingCmds} plus
# $Conf{MaxBackups} number of pending compress commands, plus running jobs.
# This limit is to make sure BackupAFS doesn't fall too far behind in
# running BackupAFS_compress commands.
#
$Conf{MaxPendingCmds} = 20;

#
# Nice level at which CmdQueue commands (eg: BackupAFS_compress and
# BackupAFS_nightly) are run at.
#
$Conf{CmdQueueNice} = 10;

#
# How many BackupAFS_nightly processes to run in parallel.
#
# Each night, at the first wakeup listed in $Conf{WakeupSchedule},
# BackupAFS_nightly is run. To avoid race
# conditions, BackupAFS_nightly and BackupAFS_compress cannot run at
# the same time.  Starting in v3.0.0, BackupAFS_nightly can run
# concurrently with backups (BackupAFS_dump).
#
# So to reduce the elapsed time, you might want to increase this
# setting to run several BackupAFS_nightly processes in parallel
# (eg: 4, or even 8).
#
$Conf{MaxBackupAFSNightlyJobs} = 2;

#
# BackupPC uses the BackupAFSNightlyPeriod to specify what portion
# of the "pool" to process each night. BackupAFS doesn't have a notion
# of pooled files, therefore leave this at 1.
#
$Conf{BackupAFSNightlyPeriod} = 1;

#
# Maximum number of log files we keep around in log directory.
# These files are aged nightly.  A setting of 14 means the log
# directory will contain about 2 weeks of old log files, in
# particular at most the files LOG, LOG.0, LOG.1, ... LOG.13
# (except today's LOG, these files will have a .z extension if
# compression is on).
#
# If you decrease this number after BackupAFS has been running for a
# while you will have to manually remove the older log files.
#
$Conf{MaxOldLogFiles} = 20;

#
# Full path to the df command.  Security caution: normal users
# should not allowed to write to this file or directory.
#
$Conf{DfPath} = '';

#
# Command to run df.  The following variables are substituted at run-time:
#
#   $dfPath      path to df ($Conf{DfPath})
#   $topDir      top-level BackupAFS data directory
#
# Note: all Cmds are executed directly without a shell, so the prog name
# needs to be a full path and you can't include shell syntax like
# redirection and pipes; put that in a script if you need it.
#
$Conf{DfCmd} = '$dfPath $topDir';

#
# Full path to various commands for archiving
#
$Conf{CatPath} = '';
$Conf{GzipPath} = '';
$Conf{PigzPath} = '';
$Conf{AfsVosPath} = '';

$Conf{PigzThreads} = undef;

#
# Maximum threshold for disk utilization on the __TOPDIR__ filesystem.
# If the output from $Conf{DfPath} reports a percentage larger than
# this number then no new regularly scheduled backups will be run.
# However, user requested backups (which are usually incremental and
# tend to be small) are still performed, independent of disk usage.
# Also, currently running backups will not be terminated when the disk
# usage exceeds this number.
#
$Conf{DfMaxUsagePct} = 95;

#
# How long BackupAFS_trashClean sleeps in seconds between each check
# of the trash directory.  Once every 5 minutes should be reasonable.
#
$Conf{TrashCleanSleepSec} = 300;

#
# The BackupAFS user.
#
$Conf{BackupAFSUser} = '';

#
# Important installation directories:
#
#   TopDir     - where all the backup data is stored
#   ConfDir    - where the main config and VolumeSet-List files resides
#   LogDir     - where log files and other transient information
#   InstallDir - where the bin, lib and doc installation dirs reside.
#                Note: you cannot change this value since all the
#                perl scripts include this path.  You must reinstall
#                with configure.pl to change InstallDir.
#   CgiDir     - Apache CGI directory for BackupAFS_Admin
#
# Note: it is STRONGLY recommended that you don't change the
# values here.  These are set at installation time and are here
# for reference and are used during upgrades.
#
# Instead of changing TopDir here it is recommended that you use
# a symbolic link to the new location, or mount the new BackupAFS
# store at the existing $Conf{TopDir} setting.
#
$Conf{TopDir} =     '';
$Conf{ConfDir} =    '';
$Conf{LogDir} =     '';
$Conf{InstallDir} = '';
$Conf{CgiDir} =     '';

#
# Whether BackupAFS and the CGI script BackupAFS_Admin verify that they
# are really running as user $Conf{BackupAFSUser}.  If this flag is set
# and the effective user id (euid) differs from $Conf{BackupAFSUser}
# then both scripts exit with an error.  This catches cases where
# BackupAFS might be accidently started as root or the wrong user,
# or if the CGI script is not installed correctly.
#
$Conf{BackupAFSUserVerify} = '1';

#
# Advanced option for asking BackupAFS to load additional perl modules.
# Can be a list (array ref) of module names to load at startup.
#
$Conf{PerlModuleLoad} = undef;

#
# Path to init.d script and command to use that script to start the
# server from the CGI interface.  The following variables are substituted
# at run-time:
#
#   $sshPath           path to ssh ($Conf{SshPath})
#   $serverHost        same as $Conf{ServerHost}
#   $serverInitdPath   path to init.d script ($Conf{ServerInitdPath})
#
# Example:
#
# $Conf{ServerInitdPath}     = '/etc/init.d/backupafs';
# $Conf{ServerInitdStartCmd} = '$sshPath -q -x -l root $serverHost'
#                            . ' $serverInitdPath start'
#                            . ' < /dev/null >& /dev/null';
#
# Note: all Cmds are executed directly without a shell, so the prog name
# needs to be a full path and you can't include shell syntax like
# redirection and pipes; put that in a script if you need it.
#
$Conf{ServerInitdPath} = undef;
$Conf{ServerInitdStartCmd} = '';


###########################################################################
# What to backup and when to do it
# (can be overridden in the per-VolumeSet config.pl)
###########################################################################
#
# Minimum period in days between full backups. A full dump will only be
# done if at least this much time has elapsed since the last full dump,
# and at least $Conf{IncrPeriod} days has elapsed since the last
# successful dump.
#
# Typically this is set slightly less than an integer number of days. The
# time taken for the backup, plus the granularity of $Conf{WakeupSchedule}
# will make the actual backup interval a bit longer.
#
$Conf{FullPeriod} = '62.64';

#
# Minimum period in days between incremental backups (a user requested
# incremental backup will be done anytime on demand).
#
# Typically this is set slightly less than an integer number of days. The
# time taken for the backup, plus the granularity of $Conf{WakeupSchedule}
# will make the actual backup interval a bit longer.
#
$Conf{IncrPeriod} = '0.64';

#
# Number of full backups to keep.  Must be >= 1.
#
# In the steady state, each time a full backup completes successfully
# the oldest one is removed.  If this number is decreased, the
# extra old backups will be removed.
#
# If filling of incremental dumps is off the oldest backup always
# has to be a full (ie: filled) dump.  This might mean one or two
# extra full dumps are kept until the oldest incremental backups expire.
#
# Exponential backup expiry is also supported.  This allows you to specify:
#
#   - num fulls to keep at intervals of 1 * $Conf{FullPeriod}, followed by
#   - num fulls to keep at intervals of 2 * $Conf{FullPeriod},
#   - num fulls to keep at intervals of 4 * $Conf{FullPeriod},
#   - num fulls to keep at intervals of 8 * $Conf{FullPeriod},
#   - num fulls to keep at intervals of 16 * $Conf{FullPeriod},
#
# and so on.  This works by deleting every other full as each expiry
# boundary is crossed.
#
# Exponential expiry is specified using an array for $Conf{FullKeepCnt}:
#
#   $Conf{FullKeepCnt} = [4, 2, 3];
#
# Entry #n specifies how many fulls to keep at an interval of
# 2^n * $Conf{FullPeriod} (ie: 1, 2, 4, 8, 16, 32, ...).
#
# The example above specifies keeping 4 of the most recent full backups
# (1 week interval) two full backups at 2 week intervals, and 3 full
# backups at 4 week intervals, eg:
#
#    full 0 19 weeks old   \
#    full 1 15 weeks old    >---  3 backups at 4 * $Conf{FullPeriod}
#    full 2 11 weeks old   / 
#    full 3  7 weeks old   \____  2 backups at 2 * $Conf{FullPeriod}
#    full 4  5 weeks old   /
#    full 5  3 weeks old   \
#    full 6  2 weeks old    \___  4 backups at 1 * $Conf{FullPeriod}
#    full 7  1 week old     /
#    full 8  current       /
#
# On a given week the spacing might be less than shown as each backup
# ages through each expiry period.  For example, one week later, a
# new full is completed and the oldest is deleted, giving:
#
#    full 0 16 weeks old   \
#    full 1 12 weeks old    >---  3 backups at 4 * $Conf{FullPeriod}
#    full 2  8 weeks old   / 
#    full 3  6 weeks old   \____  2 backups at 2 * $Conf{FullPeriod}
#    full 4  4 weeks old   /
#    full 5  3 weeks old   \
#    full 6  2 weeks old    \___  4 backups at 1 * $Conf{FullPeriod}
#    full 7  1 week old     /
#    full 8  current       /
#
# You can specify 0 as a count (except in the first entry), and the
# array can be as long as you wish.  For example:
#
#   $Conf{FullKeepCnt} = [4, 0, 4, 0, 0, 2];
#
# This will keep 10 full dumps, 4 most recent at 1 * $Conf{FullPeriod},
# followed by 4 at an interval of 4 * $Conf{FullPeriod} (approx 1 month
# apart), and then 2 at an interval of 32 * $Conf{FullPeriod} (approx
# 7-8 months apart).
#
# Example: these two settings are equivalent and both keep just
# the four most recent full dumps:
#
#    $Conf{FullKeepCnt} = 4;
#    $Conf{FullKeepCnt} = [4];
#
$Conf{FullKeepCnt} = 2;

#
# Very old full backups are removed after $Conf{FullAgeMax} days.  However,
# we keep at least $Conf{FullKeepCntMin} full backups no matter how old
# they are.
#
# Note that $Conf{FullAgeMax} will be increased to $Conf{FullKeepCnt}
# times $Conf{FullPeriod} if $Conf{FullKeepCnt} specifies enough
# full backups to exceed $Conf{FullAgeMax}.
#
$Conf{FullKeepCntMin} = 1;
$Conf{FullAgeMax} = 90;

#
# Number of incremental backups to keep.  Must be >= 1.
#
# In the steady state, each time an incr backup completes successfully
# the oldest one is removed.  If this number is decreased, the
# extra old backups will be removed at the next wakeup. So be cautious
# when decreasing this number.
#
$Conf{IncrKeepCnt} = 60;

#
# Very old incremental backups are removed after $Conf{IncrAgeMax} days.
# However, we keep at least $Conf{IncrKeepCntMin} incremental backups no
# matter how old they are.
#
$Conf{IncrKeepCntMin} = 60;
$Conf{IncrAgeMax} = 180;

#
# Level of each incremental.  "Level" follows the terminology
# of dump(1).  A full backup has level 0.  A new incremental
# of level N will backup all files that have changed since
# the most recent backup of a lower level.
#
# The entries of $Conf{IncrLevels} apply in order to each
# incremental after each full backup.  It wraps around until
# the next full backup.  For example, these two settings
# have the same effect:
#
#       $Conf{IncrLevels} = [1, 2, 3];
#       $Conf{IncrLevels} = [1, 2, 3, 1, 2, 3];
#
# This means the 1st and 4th incrementals (level 1) go all
# the way back to the full.  The 2nd and 3rd (and 5th and
# 6th) backups just go back to the immediate preceeding
# incremental.
#
# Specifying a sequence of multi-level incrementals will
# usually mean more than $Conf{IncrKeepCnt} incrementals will
# need to be kept, since lower level incrementals are needed
# to merge a complete view of a backup.  For example, with
#
#       $Conf{FullPeriod}  = 7;
#       $Conf{IncrPeriod}  = 1;
#       $Conf{IncrKeepCnt} = 6;
#       $Conf{IncrLevels}  = [1, 2, 3, 4, 5, 6];
#
# there will be up to 11 incrementals in this case: 
#
#       backup #0  (full, level 0, oldest)
#       backup #1  (incr, level 1)
#       backup #2  (incr, level 2)
#       backup #3  (incr, level 3)
#       backup #4  (incr, level 4)
#       backup #5  (incr, level 5)
#       backup #6  (incr, level 6)
#       backup #7  (full, level 0)
#       backup #8  (incr, level 1)
#       backup #9  (incr, level 2)
#       backup #10 (incr, level 3)
#       backup #11 (incr, level 4)
#       backup #12 (incr, level 5, newest)
#
# Backup #1 (the oldest level 1 incremental) can't be deleted
# since backups 2..6 depend on it.  Those 6 incrementals can't
# all be deleted since that would only leave 5 (#8..12).
# When the next incremental happens (level 6), the complete
# set of 6 older incrementals (#1..6) will be deleted, since
# that maintains the required number ($Conf{IncrKeepCnt})
# of incrementals.  This situation is reduced if you set
# shorter chains of multi-level incrementals, eg:
#
#       $Conf{IncrLevels}  = [1, 2, 3];
#
# would only have up to 2 extra incremenals before all 3
# are deleted.
#
# BackupAFS merges the full and the sequence
# of incrementals together so each incremental can be
# browsed and restored as though it is a complete backup.
# If you specify a long chain of incrementals then more
# backups need to be merged when browsing, restoring,
# or getting the starting point for backups.
# In the example above (levels 1..6), browing backup
# #6 requires 7 different backups (#0..6) to be merged.
#
# Because of this merging and the additional incrementals
# that need to be kept, it is recommended that some
# level 1 incrementals be included in $Conf{IncrLevels}.
#
# The default is a slightly-modified tower-of-hanoi sequence
#
$Conf{IncrLevels} = [
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8,
  1,
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8,
  1,
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8,
  1,
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8,
  1,
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8,
  1,
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8,
  1,
  3,
  2,
  5,
  4,
  7,
  6,
  9,
  8
];

#
# Disable all full and incremental backups.  These settings are
# useful for a VolumeSet that is no longer being backed up
# (ie, a retired user, etc) but you wish to keep the last
# backups available for browsing or restoring.
#
# There are three values for $Conf{BackupsDisable}:
#
#   0    Backups are enabled.
#
#   1    Don't do any regular backups on this VolumeSet.  Manually
#        requested backups (via the CGI interface) will still occur.
#
#   2    Don't do any backups on this VolumeSet.  Manually requested
#        backups (via the CGI interface) will be ignored.
#
$Conf{BackupsDisable} = 0;

#
# Number of restore logs to keep.  BackupAFS remembers information about
# each restore request.  This number per VolumeSet will be kept around before
# the oldest ones are pruned.
#
$Conf{RestoreInfoKeepCnt} = 25;

#
# One or more blackout periods can be specified.  If a VolumeSet is
# subject to blackout then no regular (non-manual) backups will
# be started during any of these periods.  hourBegin and hourEnd
# specify hours fro midnight and weekDays is a list of days of
# the week where 0 is Sunday, 1 is Monday etc.
#
# For example:
#
#    $Conf{BlackoutPeriods} = [
#	{
#	    hourBegin =>  7.0,
#	    hourEnd   => 19.5,
#	    weekDays  => [1, 2, 3, 4, 5],
#	},
#    ];
#
# specifies one blackout period from 7:00am to 7:30pm local time
# on Mon-Fri.
#
# The blackout period can also span midnight by setting
# hourBegin > hourEnd, eg:
#
#    $Conf{BlackoutPeriods} = [
#	{
#	    hourBegin =>  7.0,
#	    hourEnd   => 19.5,
#	    weekDays  => [1, 2, 3, 4, 5],
#	},
#	{
#	    hourBegin => 23,
#	    hourEnd   =>  5,
#	    weekDays  => [5, 6],
#	},
#    ];
#
# This specifies one blackout period from 7:00am to 7:30pm local time
# on Mon-Fri, and a second period from 11pm to 5am on Friday and
# Saturday night.
#
$Conf{BlackoutPeriods} = [];

#
# A backup of a share that has zero files is considered fatal. This is
# used to catch miscellaneous Xfer errors that result in no files being
# backed up.  If you have shares that might be empty (and therefore an
# empty backup is valid) you should set this flag to 0.
#
$Conf{BackupZeroFilesIsFatal} = '1';

###########################################################################
# How to backup a VolumeSet
# (can be overridden in the per-VolumeSet config.pl)
###########################################################################
#
# 'vos' is the only XferMethod currently supported in BackupAFS
#
$Conf{XferMethod} = 'vos';

#
# Level of verbosity in Xfer log files.  0 means be quiet, 1 will give
# will give one line per file, 2 will also show skipped files on
# incrementals, higher values give more output.
#
$Conf{XferLogLevel} = 3;

#
$Conf{ClientCharset} = '';
$Conf{ClientCharsetLegacy} = '';

#
# Full path for ssh. Security caution: normal users should not
# allowed to write to this file or directory.
#
$Conf{SshPath} = '/usr/bin/ssh';

#
# Full path to the ping command.  Security caution: normal users
# should not be allowed to write to this file or directory.
#
# If you want to disable ping checking, set this to some program
# that exits with 0 status, eg:
#
#     $Conf{PingPath} = '/bin/echo';
#
$Conf{PingPath} = '';

#
# Ping command.  The following variables are substituted at run-time:
#
#   $pingPath      path to ping ($Conf{PingPath})
#   $volset        volumeset or host name
#
# Wade Brown reports that on solaris 2.6 and 2.7 ping -s returns the wrong
# exit status (0 even on failure).  Replace with "ping $volset 1", which
# gets the correct exit status but we don't get the round-trip time.
#
# Note: all Cmds are executed directly without a shell, so the prog name
# needs to be a full path and you can't include shell syntax like
# redirection and pipes; put that in a script if you need it.
#
$Conf{PingCmd} = '$pingPath -c 1 -w 3 $volset';

#
# Maximum round-trip ping time in milliseconds.  This threshold is set
# to avoid backing up volumes on servers that are remotely connected through WAN or
# dialup connections.  The output from ping -s (assuming it is supported
# on your system) is used to check the round-trip packet time.  On your
# local LAN round-trip times should be much less than 20msec.  On most
# WAN or dialup connections the round-trip time will be typically more
# than 20msec.  Tune if necessary.
#
$Conf{PingMaxMsec} = 20;

#
# Compression level to use on files.  0 means no compression.  Compression
# levels can be from 1 (least cpu time, slightly worse compression) to
# 9 (most cpu time, slightly better compression).  The recommended value
# is 3.  Changing to 5, for example, will take maybe 20% more cpu time
# and will get another 2-3% additional compression.
#
# If compression was off and you are enabling compression for the first
# time you can use the BackupAFS_migrate_compress_volsets utility to compress the
# dumps. See the documentation for more information.
#
# Note: compression needs the gzip or pigz binary.  If neither
# can be found then $Conf{CompressLevel} is forced to 0 (compression off).
#
$Conf{CompressLevel} = 4;

#
# Timeout in seconds when listening for the transport program's
# (vos etc) stdout. If no output is received during this
# time, then it is assumed that something has wedged during a backup,
# and the backup is terminated.
#
$Conf{ClientTimeout} = 72000;

#
# Maximum number of log files we keep around in each VolSet's directory
# (ie: volsets/$VolumeSet).  These files are aged monthly.  A setting of 12
# means there will be at most the files LOG, LOG.0, LOG.1, ... LOG.11
# in the volsets/$VolumeSet directory (ie: about a years worth).  (Except this
# month's LOG, these files will have a .z extension if compression
# is on).
#
# If you decrease this number after BackupAFS has been running for a
# while you will have to manually remove the older log files.
#
$Conf{MaxOldPerPCLogFiles} = 12;

#
# Optional commands to run before and after dumps and restores,
# and also before and after each share of a dump.
#
# These commands have not been tested with BackupAFS; they are a holdover from BackupPC.
#
# Stdout from these commands will be written to the Xfer (or Restore)
# log file.  One example of using these commands would be to
# shut down and restart a database server, dump a database
# to files for backup, or doing a snapshot of a share prior
# to a backup.  Example:
#
#    $Conf{DumpPreUserCmd} = '$sshPath -q -x -l root $host /usr/bin/dumpMysql';
#
# The following variable substitutions are made at run time for
# $Conf{DumpPreUserCmd}, $Conf{DumpPostUserCmd}, $Conf{DumpPreShareCmd}
# and $Conf{DumpPostShareCmd}:
#
#        $type         type of dump (incr or full)
#        $xferOK       1 if the dump succeeded, 0 if it didn't
#        $client       client name being backed up
#        $host         host name (could be different from client name if
#                                 $Conf{ClientNameAlias} is set)
#        $hostIP       IP address of host
#        $user         user name from the hosts file
#        $moreUsers    list of additional users from the hosts file
#        $share        the first share name (or current share for
#                        $Conf{DumpPreShareCmd} and $Conf{DumpPostShareCmd})
#        $shares       list of all the share names
#        $XferMethod   value of $Conf{XferMethod} (eg: tar, rsync, smb)
#        $sshPath      value of $Conf{SshPath},
#        $cmdType      set to DumpPreUserCmd or DumpPostUserCmd
#
# The following variable substitutions are made at run time for
# $Conf{RestorePreUserCmd} and $Conf{RestorePostUserCmd}:
#
#        $client       client name being backed up
#        $xferOK       1 if the restore succeeded, 0 if it didn't
#        $host         host name (could be different from client name if
#                                 $Conf{ClientNameAlias} is set)
#        $hostIP       IP address of host
#        $user         user name from the hosts file
#        $moreUsers    list of additional users from the hosts file
#        $share        the first share name
#        $XferMethod   value of $Conf{XferMethod} (eg: tar, rsync, smb)
#        $sshPath      value of $Conf{SshPath},
#        $type         set to "restore"
#        $bkupSrcHost  host name of the restore source
#        $bkupSrcShare share name of the restore source
#        $bkupSrcNum   backup number of the restore source
#        $pathHdrSrc   common starting path of restore source
#        $pathHdrDest  common starting path of destination
#        $fileList     list of files being restored
#        $cmdType      set to RestorePreUserCmd or RestorePostUserCmd
#
# Note: all Cmds are executed directly without a shell, so the prog name
# needs to be a full path and you can't include shell syntax like
# redirection and pipes; put that in a script if you need it.
#
$Conf{DumpPreUserCmd} = undef;
$Conf{DumpPostUserCmd} = undef;
$Conf{DumpPreShareCmd} = undef;
$Conf{DumpPostShareCmd} = undef;
$Conf{RestorePreUserCmd} = undef;
$Conf{RestorePostUserCmd} = undef;

#
# Whether the exit status of each PreUserCmd and
# PostUserCmd is checked.
#
# If set and the Dump/Restore/Archive Pre/Post UserCmd
# returns a non-zero exit status then the dump/restore/archive
# is aborted.  To maintain backward compatibility (where
# the exit status in early versions was always ignored),
# this flag defaults to 0.
#
# If this flag is set and the Dump/Restore/Archive PreUserCmd
# fails then the matching Dump/Restore/Archive PostUserCmd is
# not executed.  If DumpPreShareCmd returns a non-exit status,
# then DumpPostShareCmd is not executed, but the DumpPostUserCmd
# is still run (since DumpPreUserCmd must have previously
# succeeded).
#
# An example of a DumpPreUserCmd that might fail is a script
# that snapshots or dumps a database which fails because
# of some database error.
#
$Conf{UserCmdCheckStatus} = '0';

#
# Override the client's host name.  This allows multiple clients
# to all refer to the same physical host.  This should only be
# set in the per-VolumeSet config file and is only used by BackupAFS at
# the last moment prior to generating the command used to backup
# that machine (ie: the value of $Conf{ClientNameAlias} is invisible
# everywhere else in BackupAFS).  The setting can be a host name or
# IP address, eg:
#
#         $Conf{ClientNameAlias} = 'realHostName';
#         $Conf{ClientNameAlias} = '192.1.1.15';
#
# will cause the relevant smb/tar/rsync backup/restore commands to be
# directed to realHostName, not the client name.
#
$Conf{ClientNameAlias} = undef;

###########################################################################
# Email reminders, status and messages
# (can be overridden in the per-VolumeSet config.pl)
###########################################################################
#
# Full path to the sendmail command.  Security caution: normal users
# should not allowed to write to this file or directory.
#
$Conf{SendmailPath} = '';

#
# Minimum period between consecutive emails to a single user.
# This tries to keep annoying email to users to a reasonable
# level.  Email checks are done nightly, so this number is effectively
# rounded up (ie: 2.5 means a user will never receive email more
# than once every 3 days).
#
$Conf{EMailNotifyMinDays} = '2.5';

#
# Name to use as the "from" name for email.  Depending upon your mail
# handler this is either a plain name (eg: "admin") or a fully-qualified
# name (eg: "admin@mydomain.com").
#
$Conf{EMailFromUserName} = '';

#
# Destination address to an administrative user who will receive a
# nightly email with warnings and errors.  If there are no warnings
# or errors then no email will be sent.  Depending upon your mail
# handler this is either a plain name (eg: "admin") or a fully-qualified
# name (eg: "admin@mydomain.com").
#
$Conf{EMailAdminUserName} = '';

#
# Destination domain name for email sent to users.  By default
# this is empty, meaning email is sent to plain, unqualified
# addresses.  Otherwise, set it to the destintation domain, eg:
#
#    $Cong{EMailUserDestDomain} = '@mydomain.com';
#
# With this setting user email will be set to 'user@mydomain.com'.
#
$Conf{EMailUserDestDomain} = '';

#
# This subject and message is sent to a user if their VolumeSet has never been
# backed up.
#
# These values are language-dependent.  The default versions can be
# found in the language file (eg: lib/BackupAFS/Lang/en.pm).  If you
# need to change the message, copy it here and edit it, eg:
#
#   $Conf{EMailNoBackupEverMesg} = <<'EOF';
#   To: $user$domain
#   cc:
#   Subject: $subj
#   
#   Dear $userName,
#   
#   This is a site-specific email message.
#   EOF
#
$Conf{EMailNoBackupEverSubj} = undef;
$Conf{EMailNoBackupEverMesg} = undef;

#
# How old the most recent backup has to be before notifying user.
# When there have been no backups in this number of days the user
# is sent an email.
#
$Conf{EMailNotifyOldBackupDays} = 7;

#
# This subject and message is sent to a user if their VolumeSet has not recently
# been backed up (ie: more than $Conf{EMailNotifyOldBackupDays} days ago).
#
# These values are language-dependent.  The default versions can be
# found in the language file (eg: lib/BackupAFS/Lang/en.pm).  If you
# need to change the message, copy it here and edit it, eg:
#
#   $Conf{EMailNoBackupRecentMesg} = <<'EOF';
#   To: $user$domain
#   cc:
#   Subject: $subj
#   
#   Dear $userName,
#   
#   This is a site-specific email message.
#   EOF
#
$Conf{EMailNoBackupRecentSubj} = undef;
$Conf{EMailNoBackupRecentMesg} = undef;

#
# Additional email headers.  This sets to charset to
# utf8.
#
$Conf{EMailHeaders} = 'MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
';

###########################################################################
# CGI user interface configuration settings
# (can be overridden in the per-VolumeSet config.pl)
###########################################################################
#
# Normal users can only access information specific to their volumeset.
# They can start/stop/browse/restore backups.
#
# Administrative users have full access to all volumesets, plus overall
# status and log information.
#
# The administrative users are the union of the unix/linux group
# $Conf{CgiAdminUserGroup} and the manual list of users, separated
# by spaces, in $Conf{CgiAdminUsers}. If you don't want a group or
# manual list of users set the corresponding configuration setting
# to undef or an empty string.
#
# If you want every user to have admin privileges (careful!), set
# $Conf{CgiAdminUsers} = '*'.
#
# Examples:
#    $Conf{CgiAdminUserGroup} = 'admin';
#    $Conf{CgiAdminUsers}     = 'craig celia';
#    --> administrative users are the union of group admin, plus
#      craig and celia.
#
#    $Conf{CgiAdminUserGroup} = '';
#    $Conf{CgiAdminUsers}     = 'craig celia';
#    --> administrative users are only craig and celia'.
#
$Conf{CgiAdminUserGroup} = '';
#$Conf{CgiAdminUsers}     = '';
$Conf{CgiAdminUsers} = '';

#
# URL of the BackupAFS_Admin CGI script.  Used for email messages.
#
$Conf{CgiURL} = undef;

#   
# Language to use.  See lib/BackupAFS/Lang for the list of supported
# languages, which includes only English (en) right now.
#
# Currently the Language setting applies to the CGI interface and email
# messages sent to users.  Log files and other text are still in English.
#
$Conf{Language} = 'en';

#
# User names that are rendered by the CGI interface can be turned
# into links into their home page or other information about the
# user.  To set this up you need to create two sprintf() strings,
# that each contain a single '%s' that will be replaced by the user
# name.  The default is a mailto: link.
#
# $Conf{CgiUserHomePageCheck} should be an absolute file path that
# is used to check (via "-f") that the user has a valid home page.
# Set this to undef or an empty string to turn off this check.
#
# $Conf{CgiUserUrlCreate} should be a full URL that points to the
# user's home page.  Set this to undef or an empty string to turn
# off generation of URLs for user names.
#
# Example:
#    $Conf{CgiUserHomePageCheck} = '/var/www/html/users/%s.html';
#    $Conf{CgiUserUrlCreate}     = 'http://myhost/users/%s.html';
#    --> if /var/www/html/users/craig.html exists, then 'craig' will
#      be rendered as a link to http://myhost/users/craig.html.
#
$Conf{CgiUserHomePageCheck} = '';
$Conf{CgiUserUrlCreate} = 'mailto:%s';

#
# Date display format for CGI interface.  A value of 1 uses US-style
# dates (MM/DD), a value of 2 uses full YYYY-MM-DD format, and zero
# for international dates (DD/MM).
#
$Conf{CgiDateFormatMMDD} = 1;

#
# Enable/disable the search box in the navigation bar.
#
$Conf{CgiSearchBoxEnable} = '1';

#
# Additional navigation bar links.  These appear for both regular users
# and administrators.  This is a list of hashes giving the link (URL)
# and the text (name) for the link.  Specifying lname instead of name
# uses the language specific string (ie: $Lang->{lname}) instead of
# just literally displaying name.
#
$Conf{CgiNavBarLinks} = [
  {
    'link' => '?action=view&type=docs',
    'lname' => 'Documentation',
    'name' => undef
  },
  {
    'link' => 'http://backupafs.sourceforge.net',
    'lname' => undef,
    'name' => 'SourceForge'
  }
];

#
# Hilight colors based on status that are used in the VolumeSet summary page.
#
$Conf{CgiStatusHilightColor} = {
  'Reason_backup_failed' => '#ffcccc',
  'Reason_backup_done' => '#ccffcc',
  'Reason_backup_canceled_by_user' => '#ff9900',
  'Reason_no_ping' => '#ffff99',
  'Disabled_OnlyManualBackups' => '#d1d1d1',
  'Status_backup_in_progress' => '#66cc99',
  'Disabled_AllBackupsDisabled' => '#d1d1d1'
};

#
# Additional CGI header text.
#
$Conf{CgiHeaders} = '<meta http-equiv="pragma" content="no-cache">';

#
# Directory where images are stored.  This directory should be below
# Apache's DocumentRoot.  This value isn't used by BackupAFS but is
# used by configure.pl when you upgrade BackupAFS.
#
# Example:
#     $Conf{CgiImageDir} = '/var/www/htdocs/BackupAFS';
#
$Conf{CgiImageDir} = '';

#
# Additional mappings of file name extenions to Content-Type for
# individual file restore.  See $Ext2ContentType in BackupAFS_Admin
# for the default setting.  You can add additional settings here,
# or override any default settings.  Example:
#
#     $Conf{CgiExt2ContentType} = {
#                 'pl'  => 'text/plain',
#          };
#
$Conf{CgiExt2ContentType} = {};

#
# URL (without the leading http://host) for BackupAFS's image directory.
# The CGI script uses this value to serve up image files.
#
# Example:
#     $Conf{CgiImageDirURL} = '/BackupAFS';
#
$Conf{CgiImageDirURL} = '';

#
# CSS stylesheet "skin" for the CGI interface.  It is stored
# in the $Conf{CgiImageDir} directory and accessed via the
# $Conf{CgiImageDirURL} URL.
#
$Conf{CgiCSSFile} = 'BackupAFS_stnd.css';

#
# Whether the user is allowed to edit their per-VolumeSet config.
#
$Conf{CgiUserConfigEditEnable} = '1';

#
# These need to be documented
#
$Conf{AfsVosBackupArgs} = '--volume=$shareName --type=$type --incrDate=$incrDate --incrLevel=$incrLevel --clientDir=$topDir/volsets/$client --dest=$topDir/volsets/$client/new';
$Conf{AfsVosRestoreArgs} = '--volume=$shareName --type=$type --clientDir=$topDir/volsets/$client --restoreDir=$restoreDir --bkupSrcNum=$bkupSrcNum --bkupSrcVolSet=$bkupSrcVolSet --fileList=$fileList';

#
# Which per-volumeset config variables a non-admin user is allowed
# to edit.  Admin users can edit all per-volset config variables,
# even if disabled in this list.
#
# SECURITY WARNING: Do not let users edit any of the Cmd
# config variables!  That's because a user could set a
# Cmd to a shell script of their choice and it will be
# run as the BackupAFS user.  That script could do all
# sorts of bad things.
#
$Conf{CgiUserConfigEdit} = {
  'EMailNoBackupRecentMesg' => '1',
  'ClientCharset' => '1',
  'BackupZeroFilesIsFatal' => '1',
  'FullKeepCnt' => '1',
  'EMailNoBackupEverSubj' => '1',
  'EMailNoBackupRecentSubj' => '1',
  'IncrKeepCnt' => '1',
  'XferLogLevel' => '1',
  'EMailFromUserName' => '1',
  'PingCmd' => '0',
  'FullAgeMax' => '1',
  'ClientTimeout' => '1',
  'EMailNotifyMinDays' => '1',
  'PingMaxMsec' => '1',
  'IncrLevels' => '1',
  'CompressLevel' => '1',
  'EMailNotifyOldBackupDays' => '1',
  'FullPeriod' => '1',
  'EMailAdminUserName' => '1',
  'IncrPeriod' => '1',
  'FullKeepCntMin' => '1',
  'XferMethod' => '1',
  'BackupsDisable' => '1',
  'EMailUserDestDomain' => '1',
  'RestoreInfoKeepCnt' => '1',
  'UserCmdCheckStatus' => '0',
  'IncrAgeMax' => '1',
  'IncrKeepCntMin' => '1',
  'EMailNoBackupEverMesg' => '1',
  'EMailHeaders' => '1',
  'DumpPreUserCmd' => '0',
  'DumpPostUserCmd' => '0'
};
$Conf{CgiNavBarAdminAllVolSets} = '1';
