#============================================================= -*-perl-*-
#
# BackupAFS::Config::Meta package
#
# DESCRIPTION
#
#   This library defines a BackupAFS::Config::Meta class.
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

package BackupAFS::Config::Meta;

use strict;

require Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

use vars qw(%ConfigMeta);

@ISA = qw(Exporter);

@EXPORT    = qw( );

@EXPORT_OK = qw(
		    %ConfigMeta
             );

%EXPORT_TAGS = (
    'all'    => [ @EXPORT_OK ],
);

#
# Define the data types for all the config variables
#

%ConfigMeta = (

    ######################################################################
    # General server configuration
    ######################################################################
    ServerHost 		=> "string",
    ServerPort	 	=> "integer",
    ServerMesgSecret 	=> "string",
    MyPath	 	=> {type => "string", undefIfEmpty => 1},
    UmaskMode	 	=> "integer",
    WakeupSchedule => {
            type  => "shortlist",
            child => "float",
        },
    MaxBackups	 	=> "integer",
    MaxUserBackups	=> "integer",
    MaxPendingCmds	=> "integer",
    MaxBackupAFSNightlyJobs => "integer",
    BackupAFSNightlyPeriod  => "integer",
    MaxOldLogFiles      => "integer",
    CmdQueueNice        => "integer",

    AfsVosPath		=> {type => "execPath", undefIfEmpty => 1},
    AfsVosBackupArgs	=> {type => "bigstring", undefIfEmpty => 1},
    AfsVosRestoreArgs	=> {type => "bigstring", undefIfEmpty => 1},
    SshPath	 	=> {type => "execPath", undefIfEmpty => 1},
    PingPath	 	=> {type => "execPath", undefIfEmpty => 1},
    DfPath	 	=> {type => "execPath", undefIfEmpty => 1},
    DfCmd	 	=> "string",
    CatPath	 	=> {type => "execPath", undefIfEmpty => 1},
    GzipPath	 	=> {type => "execPath", undefIfEmpty => 1},
    PigzPath	 	=> {type => "execPath", undefIfEmpty => 1},
    PigzThreads		=> "integer",
    DfMaxUsagePct	=> "float",
    TrashCleanSleepSec	=> "integer",
    VolSets => {
            type    => "list",
	    emptyOk => 1,
            child   => {
                type      => "VSHash",
                noKeyEdit => 1,
		order => [qw(volset user moreUsers
			 Entry1_Servers Entry1_Partitions Entry1_Volumes
			 Entry2_Servers Entry2_Partitions Entry2_Volumes
			 Entry3_Servers Entry3_Partitions Entry3_Volumes
			 Entry4_Servers Entry4_Partitions Entry4_Volumes
			 Entry5_Servers Entry5_Partitions Entry5_Volumes
			)],
                child     => {
                    volset => { type => "string", size => 20},
		    user       => { type => "string", size => 15 },
		    moreUsers  => { type => "string", size => 25 },
		    Entry1_Servers => { type => "string", size => 20},
		    Entry1_Partitions => { type => "string", size => 15},
		    Entry1_Volumes => { type => "string", size => 25},
		    Entry2_Servers => { type => "string", size => 20},
		    Entry2_Partitions => { type => "string", size => 15},
		    Entry2_Volumes => { type => "string", size => 25},
		    Entry3_Servers => { type => "string", size => 20},
		    Entry3_Partitions => { type => "string", size => 15},
		    Entry3_Volumes => { type => "string", size => 25},
		    Entry4_Servers => { type => "string", size => 20},
		    Entry4_Partitions => { type => "string", size => 15},
		    Entry4_Volumes => { type => "string", size => 25},
		    Entry5_Servers => { type => "string", size => 20},
		    Entry5_Partitions => { type => "string", size => 15},
		    Entry5_Volumes => { type => "string", size => 25},
                },
            },
    },
    BackupAFSUser 	=> "string",
    CgiDir	 	=> "string",
    InstallDir	 	=> "string",
    TopDir              => "string",
    ConfDir             => "string",
    LogDir              => "string",
    BackupAFSUserVerify  => "boolean",
    PerlModuleLoad 	=> {
	    type    => "list",
	    emptyOk => 1,
	    undefIfEmpty => 1,
	    child   => "string",
    },
    ServerInitdPath 	=> {type => "string", undefIfEmpty => 1},
    ServerInitdStartCmd => "string",

    ######################################################################
    # What to backup and when to do it
    # (can be overridden in the per-PC config.pl)
    ######################################################################
    FullPeriod	 	=> "float",
    IncrPeriod	 	=> "float",
    FullKeepCnt         => {
	    type   => "shortlist",
	    child  => "integer",
    },
    FullKeepCntMin	=> "integer",
    FullAgeMax		=> "float",
    IncrKeepCnt	 	=> "integer",
    IncrKeepCntMin	=> "integer",
    IncrAgeMax		=> "float",
    IncrLevels          => {
	    type   => "shortlist",
	    child  => "integer",
    },
    BackupsDisable      => "integer",
    RestoreInfoKeepCnt	=> "integer",

    BlackoutPeriods 	 => {
            type    => "list",
	    emptyOk => 1,
            child   => {
                type      => "hash",
                noKeyEdit => 1,
                child     => {
                    hourBegin => "float",
                    hourEnd   => "float",
                    weekDays  => {
                        type  => "shortlist",
                        child => "integer",
                    },
                },
            },
        },

    BackupZeroFilesIsFatal => "boolean",

    ######################################################################
    # How to backup a client
    ######################################################################
    XferMethod => {
	    type   => "select",
	    values => [qw(vos)],
    },
    XferLogLevel	=> "integer",

    ClientCharset       => "string",
    ClientCharsetLegacy => "string",

    ######################################################################
    # Other Client Configuration
    ######################################################################
    PingCmd	 	=> "string",
    PingMaxMsec		=> "float",

    ClientTimeout	=> "integer",

    MaxOldPerPCLogFiles	=> "integer",

    CompressLevel	=> "integer",

    DumpPreUserCmd	=> {type => "string", undefIfEmpty => 1},
    DumpPostUserCmd	=> {type => "string", undefIfEmpty => 1},
    DumpPreShareCmd     => {type => "string", undefIfEmpty => 1},
    DumpPostShareCmd	=> {type => "string", undefIfEmpty => 1},
    RestorePreUserCmd	=> {type => "string", undefIfEmpty => 1},
    RestorePostUserCmd	=> {type => "string", undefIfEmpty => 1},
    UserCmdCheckStatus  => "boolean",

    ######################################################################
    # Email reminders, status and messages
    # (can be overridden in the per-PC config.pl)
    ######################################################################
    SendmailPath 	      => {type => "execPath", undefIfEmpty => 1},
    EMailNotifyMinDays        => "float",
    EMailFromUserName         => "string",
    EMailAdminUserName        => "string",
    EMailUserDestDomain       => "string",
    EMailNoBackupEverSubj     => {type => "string",    undefIfEmpty => 1},
    EMailNoBackupEverMesg     => {type => "bigstring", undefIfEmpty => 1},
    EMailNotifyOldBackupDays  => "float",
    EMailNoBackupRecentSubj   => {type => "string",    undefIfEmpty => 1},
    EMailNoBackupRecentMesg   => {type => "bigstring", undefIfEmpty => 1},
    EMailHeaders              => {type => "bigstring", undefIfEmpty => 1},

    ######################################################################
    # CGI user interface configuration settings
    ######################################################################
    CgiAdminUserGroup 	=> "string",
    CgiAdminUsers	=> "string",
    CgiURL	 	=> "string",
    Language	 	=> {
	    type   => "select",
	    values => [qw(en)],
    },
    CgiUserHomePageCheck => "string",
    CgiUserUrlCreate    => "string",
    CgiDateFormatMMDD	=> "integer",
    CgiNavBarAdminAllVolSets => "boolean",
    CgiSearchBoxEnable 	=> "boolean",
    CgiNavBarLinks	=> {
	    type    => "list",
	    emptyOk => 1,
	    child   => {
		type => "hash",
                noKeyEdit => 1,
		child => {
		    link  => "string",
		    lname => {type => "string", undefIfEmpty => 1},
		    name  => {type => "string", undefIfEmpty => 1},
		},
	    },
    },
    CgiStatusHilightColor => {
	    type => "hash",
	    noKeyEdit => 1,
	    child => {
		Reason_backup_failed           => "string",
		Reason_backup_done             => "string",
		Reason_no_ping                 => "string",
		Reason_backup_canceled_by_user => "string",
		Status_backup_in_progress      => "string",
                Disabled_OnlyManualBackups     => "string", 
                Disabled_AllBackupsDisabled    => "string",  
	    },
    },
    CgiHeaders	 	=> "bigstring",
    CgiImageDir 	=> "string",
    CgiExt2ContentType  => {
            type      => "hash",
	    emptyOk   => 1,
            childType => "string",
        },
    CgiImageDirURL 	=> "string",
    CgiCSSFile	 	=> "string",
    CgiUserConfigEditEnable => "boolean",
    CgiUserConfigEdit   => {
	    type => "hash",
	    noKeyEdit => 1,
	    child => {
                FullPeriod                => "boolean",
                IncrPeriod                => "boolean",
                FullKeepCnt               => "boolean",
                FullKeepCntMin            => "boolean",
                FullAgeMax                => "boolean",
                IncrKeepCnt               => "boolean",
                IncrKeepCntMin            => "boolean",
                IncrAgeMax                => "boolean",
                IncrLevels                => "boolean",
                RestoreInfoKeepCnt        => "boolean",
                BackupsDisable            => "boolean",
                BackupZeroFilesIsFatal    => "boolean",
                XferMethod                => "boolean",
                XferLogLevel              => "boolean",
                ClientCharset             => "boolean",
                PingMaxMsec               => "boolean",
                PingCmd                   => "boolean",
                ClientTimeout             => "boolean",
                CompressLevel             => "boolean",
                DumpPreUserCmd            => "boolean",
                DumpPostUserCmd           => "boolean",
                UserCmdCheckStatus        => "boolean",
                EMailNotifyMinDays        => "boolean",
                EMailFromUserName         => "boolean",
                EMailAdminUserName        => "boolean",
                EMailUserDestDomain       => "boolean",
                EMailNoBackupEverSubj     => "boolean",
                EMailNoBackupEverMesg     => "boolean",
                EMailNotifyOldBackupDays  => "boolean",
                EMailNoBackupRecentSubj   => "boolean",
                EMailNoBackupRecentMesg   => "boolean",
                EMailHeaders              => "boolean",
	    },
    },

    ######################################################################
    # Fake config setting for editing the volsets
    ######################################################################
    #VolSets => {
#	    type    => "list",
#	    emptyOk => 1,
#	    child   => {
#		type  => "horizHash",
#                order => [qw(volset dhcp user moreUsers)],
#                noKeyEdit => 1,
#		child => {
#		    volset       => { type => "string", size => 20 },
#		    dhcp       => { type => "boolean"            },
#		    user       => { type => "string", size => 20 },
#		    moreUsers  => { type => "string", size => 30 },
#		},
#	    },
#    },
);

1;
