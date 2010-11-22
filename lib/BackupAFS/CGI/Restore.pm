#============================================================= -*-perl-*-
#
# BackupAFS::CGI::Restore package
#
# DESCRIPTION
#
#   This module implements the Restore action for the CGI interface.
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

package BackupAFS::CGI::Restore;

use strict;
use BackupAFS::CGI::Lib qw(:all);
use BackupAFS::Xfer;
use Data::Dumper;
use File::Path;
use Encode qw/decode_utf8/;

sub action
{
    my($str, $reply, $content);
    my $Privileged = CheckPermission($In{volset});
    if ( !$Privileged ) {
        ErrorExit(eval("qq{$Lang->{Only_privileged_users_can_restore_backup_files}}"));
    }
    my $volset  = $In{volset};
    my $num   = $In{num};
    my $share = $In{share};
    my(@fileList, $fileListStr, $hiddenStr, $pathHdr, $badFileCnt);
    my $fileListv;
    my @Backups = $bafs->BackupInfoRead($volset);

    ServerConnect();
    if ( !defined($VolSets->{$volset}) ) {
        ErrorExit(eval("qq{$Lang->{Bad_volset_name}}"));
    }
    for ( my $i = 0 ; $i < $In{fcbMax} ; $i++ ) {
        next if ( !defined($In{"fcb$i"}) );
        (my $name = $In{"fcb$i"}) =~ s/%([0-9A-F]{2})/chr(hex($1))/eg;
        $badFileCnt++ if ( $name =~ m{(^|/)\.\.(/|$)} );
	if ( @fileList == 0 ) {
	    $pathHdr = substr($name, 0, rindex($name, "/"));
	} else {
	    while ( substr($name, 0, length($pathHdr)) ne $pathHdr ) {
		$pathHdr = substr($pathHdr, 0, rindex($pathHdr, "/"));
	    }
	}
        push(@fileList, $name);
        $hiddenStr .= <<EOF;
<input type="hidden" name="fcb$i" value="$In{'fcb' . $i}">
EOF
        $name = decode_utf8($name);
        $fileListStr .= <<EOF;
<li> ${EscHTML($name)}
EOF
    }
    $hiddenStr .= "<input type=\"hidden\" name=\"fcbMax\" value=\"$In{fcbMax}\">\n";
    $hiddenStr .= "<input type=\"hidden\" name=\"share\" value=\"${EscHTML(decode_utf8($share))}\">\n";
    $badFileCnt++ if ( $In{pathHdr} =~ m{(^|/)\.\.(/|$)} );
    $badFileCnt++ if ( $In{num} =~ m{(^|/)\.\.(/|$)} );
    if ( @fileList == 0 ) {
        ErrorExit($Lang->{You_haven_t_selected_any_files__please_go_Back_to});
    }
    if ( $badFileCnt ) {
        ErrorExit($Lang->{Nice_try__but_you_can_t_put});
    }
    $pathHdr = "/" if ( $pathHdr eq "" );
    if ( $In{type} != 0 && @fileList == $In{fcbMax} ) {
	#
	# All the files in the list were selected, so just restore the
	# entire parent directory
	#
	@fileList = ( $pathHdr );
    }
    if ( $In{type} == 0 ) {
	#
	# Build list of volsets
	#
	my($volsetDestSel, @volsets, $gotThisVolSet, $directVolSet);

        #
        # Check all the volsets this user has permissions for
        # and make sure direct restore is enabled.
        # Note: after this loop we have the config for the
        # last volset in @volsets, not the original $In{volset}!!
        #
        $directVolSet = $volset;
	foreach my $h ( GetUserVolSets(1) ) {
            #
            # Pick up the volset's config file
            #
            $bafs->ConfigRead($h);
            %Conf = $bafs->Conf();
                #
                # Direct restore is enabled
                #
                push(@volsets, $h);
                $gotThisVolSet = 1 if ( $h eq $volset );
            #}
	}
        $directVolSet = $volsets[0] if ( !$gotThisVolSet && @volsets );
        foreach my $h ( @volsets ) {
            my $sel = " selected" if ( $h eq $directVolSet );
            $volsetDestSel .= "<option value=\"$h\"$sel>${EscHTML($h)}</option>";
        }

        #
        # Tell the user what options they have
        #
        $pathHdr = decode_utf8($pathHdr);
        $share   = decode_utf8($share);
	$content = eval("qq{$Lang->{Restore_Options_for__volset2}}");

	#
	# Decide if option 1 (direct restore) is available based
	# on whether the restore command is set.
	#
        $content .="<b>Restoration of data from VolumeSet $In{volset} via $Conf{XferMethod}</b></br>";
        if ($Conf{XferMethod} eq "vos" ) {
           $share = "-server SERVERNAME -partition PARTITIONNAME -extension EXTENSION";
	        my $volsetDest = $In{volset};
		$VolSets->{$In{volsetDest}} = $In{volset};
           $content .= eval(
               "qq{$Lang->{Restore_Options_for__afs_Option1}}");
        } else {
	    if ( $volsetDestSel ne "" ) {
	        $content .= eval(
	    	    "qq{$Lang->{Restore_Options_for__volset_Option1}}");
	    } else {
	        my $volsetDest = $In{volset};
	        $content .= eval(
		    "qq{$Lang->{Restore_Options_for__volset_Option1_disabled}}");
	    }
        }

	Header(eval("qq{$Lang->{Restore_Options_for__volset}}"), $content);
        Trailer();
    } elsif ( $In{type} == 3 ) {
        #
        # Do restore directly onto volset
        #
            $In{volsetDest} = $volset;
        #
        # Pick up the destination volset's config file
        #
        my $volsetDest = $1 if ( $In{volsetDest} =~ /(.*)/ );
        $bafs->ConfigRead($volsetDest);
        %Conf = $bafs->Conf();

        #
        # Decide if option 1 (direct restore) is available based
        # on whether the restore parameters are set.
        #
        unless ( defined($Conf{AfsVosPath}) && defined ($Conf{AfsVosRestoreArgs}) ) {
	    ErrorExit(eval("qq{$Lang->{Restore_Options_for__volset_Option1_disabled}}"));
        }

        $fileListStr = "";
        $fileListv = "";
        my $restTablerows = "";
        foreach my $f ( @fileList ) {
            my $targetFile = $f;
	    (my $strippedShare = $share) =~ s/^\///;
	    $In{shareDest} = "-server ".$In{serverDest}." -partition ".$In{partitionDest}." -extension ".$In{extensionDest};
	    (my $strippedShareDest = $In{shareDest}) =~ s/^\///;
            substr($targetFile, 0, length($pathHdr)) = "/$In{pathHdr}/";
	    $targetFile =~ s{//+}{/}g;
            $strippedShareDest = decode_utf8($strippedShareDest);
            $targetFile = decode_utf8($targetFile);
            $strippedShare = decode_utf8($strippedShare);
		my $g=$f;
            $f = decode_utf8($f);
            $fileListStr .= <<EOF;
<tr><td>$volset:/$strippedShare$f</td><td>$In{volsetDest}:/$strippedShareDest$targetFile</td></tr>
EOF
		$g=~s/\///;
		if ($g eq "") {$g = "[ALL]";}
		#$g.="$temp<br>";
		$fileListv.="VolumeSet: <b><i>$volset</i></b> Volume(s): <b><i>$g</i></b><br>";
		$restTablerows.="<tr><td> VolumeSet:<b><i>$volset </i></b>Backup:<b><i>$num</i></b> Volume:<b><i>$g</i></b>&nbsp;&nbsp<br></td>";
		$restTablerows.="<td> Server:<b><i>$In{serverDest} </i></b>Partition:<b><i>$In{partitionDest} </i></b> Volume:<b><i>$g"."$In{extensionDest}</i></b>&nbsp;&nbsp;</td></tr>";
        }
        $In{shareDest} = decode_utf8($In{shareDest});
        $In{pathHdr}   = decode_utf8($In{pathHdr});
        my $content = eval("qq{$Lang->{Are_you_sure}}");
        Header(eval("qq{$Lang->{Restore_Confirm_on__volset}}"), $content);
        Trailer();
    } elsif ( $In{type} == 4 ) {
	if ( !defined($VolSets->{$In{volsetDest}}) ) {
	    ErrorExit(eval("qq{$Lang->{VolSet__doesn_t_exist}}"));
	}
	if ( !CheckPermission($In{volsetDest}) ) {
	    ErrorExit(eval("qq{$Lang->{You_don_t_have_permission_to_restore_onto_volset}}"));
	}
	my $volsetDest = $1 if ( $In{volsetDest} =~ /(.+)/ );
	my $ipAddr = ConfirmIPAddress($volsetDest);
        #
        # Prepare and send the restore request.  We write the request
        # information using Data::Dumper to a unique file,
        # $TopDir/volsets/$volsetDest/restoreReq.$$.n.  We use a file
        # in case the list of files to restore is very long.
        #
        my $reqFileName;
        for ( my $i = 0 ; ; $i++ ) {
            $reqFileName = "restoreReq.$$.$i";
            last if ( !-f "$TopDir/volsets/$volsetDest/$reqFileName" );
        }
	my $inPathHdr = $In{pathHdr};
	$inPathHdr = "/$inPathHdr" if ( $inPathHdr !~ m{^/} );
	$inPathHdr = "$inPathHdr/" if ( $inPathHdr !~ m{/$} );
        my %restoreReq = (
	    # source of restore is volsetSrc, #num, path shareSrc/pathHdrSrc
            num         => $In{num},
            volsetSrc     => $volset,
            shareSrc    => $share,
            pathHdrSrc  => $pathHdr,

	    # destination of restore is volsetDest:shareDest/pathHdrDest
            volsetDest    => $volsetDest,
            shareDest   => $In{shareDest},
            pathHdrDest => $inPathHdr,

	    # list of files to restore
            fileList    => \@fileList,

	    # other info
            user        => $User,
            reqTime     => time,
        );
        my($dump) = Data::Dumper->new(
                         [  \%restoreReq],
                         [qw(*RestoreReq)]);
        $dump->Indent(1);
        eval { mkpath("$TopDir/volsets/$volsetDest", 0, 0777) }
                                    if ( !-d "$TopDir/volsets/$volsetDest" );
	my $openPath = "$TopDir/volsets/$volsetDest/$reqFileName";
        if ( open(REQ, ">", $openPath) ) {
	    binmode(REQ);
            print(REQ $dump->Dump);
            close(REQ);
        } else {
            ErrorExit(eval("qq{$Lang->{Can_t_open_create__openPath}}"));
        }
	$reply = $bafs->ServerMesg("restore ${EscURI($ipAddr)}"
			. " ${EscURI($volsetDest)} $User $reqFileName");
	$str = eval("qq{$Lang->{Restore_requested_to_volset__volsetDest__backup___num}}");
	my $content = eval("qq{$Lang->{Reply_from_server_was___reply}}");
        Header(eval("qq{$Lang->{Restore_Requested_on__volsetDest}}"), $content);
        Trailer();
    }
}

1;
