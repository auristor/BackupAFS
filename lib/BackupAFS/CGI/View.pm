#============================================================= -*-perl-*-
#
# BackupAFS::CGI::View package
#
# DESCRIPTION
#
#   This module implements the View action for the CGI interface.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2003-2009  Craig Barratt
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

package BackupAFS::CGI::View;

use strict;
use BackupAFS::CGI::Lib qw(:all);
use BackupAFS::FileZIO;

sub action
{
    my $Privileged = CheckPermission($In{volset});
    my $compress = 0;
    my $fh;
    my $volset = $In{volset};
    my $num  = $In{num};
    my $type = $In{type};
    my $linkVolSets = 0;
    my($file, $comment);
    my $ext = $num ne "" ? ".$num" : "";

    ErrorExit(eval("qq{$Lang->{Invalid_number__num}}"))
		    if ( $num ne "" && $num !~ /^\d+$/ );
    if ( $type eq "XferLOG" ) {
        #$file = "$TopDir/volsets/$volset/SmbLOG$ext";
        $file = "$TopDir/volsets/$volset/XferLOG$ext" if ( !-f $file && !-f "$file.z");
    } elsif ( $type eq "XferLOGbad" ) {
        #$file = "$TopDir/volsets/$volset/SmbLOG.bad";
        $file = "$TopDir/volsets/$volset/XferLOG.bad" if ( !-f $file && !-f "$file.z");
    } elsif ( $type eq "XferErrbad" ) {
        #$file = "$TopDir/volsets/$volset/SmbLOG.bad";
        $file = "$TopDir/volsets/$volset/XferLOG.bad" if ( !-f $file && !-f "$file.z");
        $comment = $Lang->{Extracting_only_Errors};
    } elsif ( $type eq "XferErr" ) {
        #$file = "$TopDir/volsets/$volset/SmbLOG$ext";
        $file = "$TopDir/volsets/$volset/XferLOG$ext" if ( !-f $file && !-f "$file.z");
        $comment = $Lang->{Extracting_only_Errors};
    } elsif ( $type eq "RestoreLOG" ) {
        $file = "$TopDir/volsets/$volset/RestoreLOG$ext";
    } elsif ( $type eq "RestoreErr" ) {
        $file = "$TopDir/volsets/$volset/RestoreLOG$ext";
        $comment = $Lang->{Extracting_only_Errors};
    #} elsif ( $type eq "ArchiveLOG" ) {
    #    $file = "$TopDir/volsets/$volset/ArchiveLOG$ext";
    #} elsif ( $type eq "ArchiveErr" ) {
    #    $file = "$TopDir/volsets/$volset/ArchiveLOG$ext";
    #    $comment = $Lang->{Extracting_only_Errors};
    } elsif ( $type eq "config" ) {
        # Note: only works for Storage::Text
        $file = $bafs->{storage}->ConfigPath($volset);
    } elsif ( $type eq "volsets" ) {
        # Note: only works for Storage::Text
        $file = $bafs->ConfDir() . "/volsets";
        $linkVolSets = 1;
    } elsif ( $type eq "docs" ) {
        $file = $bafs->InstallDir() . "/doc/BackupAFS.html";
    } elsif ( $volset ne "" ) {
        if ( !defined($In{num}) ) {
            # get the latest LOG file
            $file = ($bafs->sortedPCLogFiles($volset))[0];
            $file =~ s/\.z$//;
        } else {
            $file = "$TopDir/volsets/$volset/LOG$ext";
        }
        $linkVolSets = 1;
    } else {
        $file = "$LogDir/LOG$ext";
        $linkVolSets = 1;
    }
    if ( $type ne "docs" && !$Privileged ) {
        ErrorExit($Lang->{Only_privileged_users_can_view_log_or_config_files});
    }
    if ( !-f $file && -f "$file.z" ) {
        $file .= ".z";
        $compress = 1;
    }
    my($contentPre, $contentSub, $contentPost);
    $contentPre .= eval("qq{$Lang->{Log_File__file__comment}}");
    if ( $file ne ""
            && defined($fh = BackupAFS::FileZIO->open($file, 0, $compress)) ) {

        $fh->utf8(1);
        my $mtimeStr = $bafs->timeStamp((stat($file))[9], 1);

	$contentPre .= eval("qq{$Lang->{Contents_of_log_file}}");

        $contentPre .= "<pre>";
        if ( $type eq "XferErr" || $type eq "XferErrbad"
				|| $type eq "RestoreErr"
				|| $type eq "ArchiveErr" ) {
	    $contentSub = sub {
		#
		# Because the content might be large, we use
		# a sub to return the data in 64K chunks.
		#
		my($skipped, $c, $s);
		while ( length($c) < 65536 ) {
		    $s = $fh->readLine();
		    if ( $s eq "" ) {
			$c .= eval("qq{$Lang->{skipped__skipped_lines}}")
							if ( $skipped );
			last;
		    }
		    $s =~ s/[\n\r]+//g;
		    #if ( $s =~ /smb: \\>/
		#	    || $s =~ /^\s*(\d+) \(\s*\d+\.\d kb\/s\) (.*)$/
		#	    || $s =~ /^tar: dumped \d+ files/
		#	    || $s =~ /^\s*added interface/i
		#	    || $s =~ /^\s*restore tar file /i
		#	    || $s =~ /^\s*restore directory /i
		#	    || $s =~ /^\s*tarmode is now/i
		#	    || $s =~ /^\s*Total bytes written/i
		#	    || $s =~ /^\s*Domain=/i
		#	    || $s =~ /^\s*Getting files newer than/i
		#	    || $s =~ /^\s*Output is \/dev\/null/
		#	    || $s =~ /^\s*\([\d.,]* kb\/s\) \(average [\d\.]* kb\/s\)$/
		#	    || $s =~ /^\s+directory \\/
		#	    || $s =~ /^\s*Timezone is/
		#	    || $s =~ /^\s*creating lame (up|low)case table/i
		#	    || $s =~ /^\.\//
		#	    || $s =~ /^  / ) {
		#	$skipped++;
		#	next;
		#    }
		    $c .= eval("qq{$Lang->{skipped__skipped_lines}}")
							 if ( $skipped );
		    $skipped = 0;
		    $c .= ${EscHTML($s)} . "\n";
		}
		return $c;
	    };
        } elsif ( $linkVolSets ) {
	    #
	    # Because the content might be large, we use
	    # a sub to return the data in 64K chunks.
	    #
	    $contentSub = sub {
		my($c, $s);
		while ( length($c) < 65536 ) {
		    $s = $fh->readLine();
		    last if ( $s eq "" );
		    $s =~ s/[\n\r]+//g;
		    $s = ${EscHTML($s)};
		    $s =~ s/\b([\w-.]+)\b/defined($VolSets->{$1})
					    ? ${VolSetLink($1)} : $1/eg;
		    $c .= $s . "\n";
		}
		return $c;
            };
        } elsif ( $type eq "config" ) {
	    #
	    # Because the content might be large, we use
	    # a sub to return the data in 64K chunks.
	    #
	    $contentSub = sub {
		my($c, $s);
		while ( length($c) < 65536 ) {
		    $s = $fh->readLine();
		    last if ( $s eq "" );
		    $s =~ s/[\n\r]+//g;
		    # remove any secrets
		    $s =~ s/(ServerMesgSecret.*=.*['"]).*(['"])/$1****$2/ig;
		    $s = ${EscHTML($s)};
		    $s =~ s[(\$Conf\{.*?\})][
			my $c = $1;
			my $s = lc($c);
			$s =~ s{(\W)}{_}g;
			"<a href=\"?action=view&type=docs#item_$s\"><tt>$c</tt></a>"
		    ]eg;
		    $c .= $s . "\n";
		}
		return $c;
            };
        } elsif ( $type eq "docs" ) {
	    #
	    # Because the content might be large, we use
	    # a sub to return the data in 64K chunks.
	    #
	    $contentSub = sub {
		my($c, $s);
		while ( length($c) < 65536 ) {
		    $s = $fh->readLine();
		    last if ( $s eq "" );
		    $c .= $s;
		}
		return $c;
            };
	    #
	    # Documentation has a different header and no pre or post text,
	    # so just handle it here
	    #
            Header($Lang->{BackupAFS__Documentation}, "", 0, $contentSub);
            Trailer();
	    return;
        } else {
	    #
	    # Because the content might be large, we use
	    # a sub to return the data in 64K chunks.
	    #
	    $contentSub = sub {
		my($c, $s);
		while ( length($c) < 65536 ) {
		    $s = $fh->readLine();
		    last if ( $s eq "" );
		    $s =~ s/[\n\r]+//g;
		    $s = ${EscHTML($s)};
		    $c .= $s . "\n";
		}
		return $c;
            };
        }
    } else {
	if ( $type eq "docs" ) {
	    ErrorExit(eval("qq{$Lang->{Unable_to_open__file__configuration_problem}}"));
	}
	$contentPre .= eval("qq{$Lang->{_pre___Can_t_open_log_file__file}}");
    }
    $contentPost .= "</pre>\n" if ( $type ne "docs" );
    Header(eval("qq{$Lang->{Backup_PC__Log_File__file}}"),
                    $contentPre, !-f "$TopDir/volsets/$volset/backups",
		    $contentSub, $contentPost);
    Trailer();
    $fh->close() if ( defined($fh) );
}

1;
