#============================================================= -*-perl-*-
#
# BackupAFS::CGI::Lib package
#
# DESCRIPTION
#
#   This library defines a BackupAFS::Lib class and a variety of utility
#   functions used by BackupAFS.
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

package BackupAFS::CGI::Lib;

use strict;
use BackupAFS::Lib;

require Exporter;

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

use vars qw($Cgi %In $MyURL $User %Conf $TopDir $LogDir $BinDir $bafs);
use vars qw(%Status %Info %Jobs @BgQueue @UserQueue @CmdQueue
            %QueueLen %StatusVolSet);
use vars qw($VolSets $VolSetsMTime $ConfigMTime $PrivAdmin);
use vars qw(%UserEmailInfo $UserEmailInfoMTime %RestoreReq %ArchiveReq);
use vars qw($Lang);

@ISA = qw(Exporter);

@EXPORT    = qw( );

@EXPORT_OK = qw(
		    timeStamp2
		    VolSetLink
		    UserLink
		    EscHTML
		    EscURI
		    ErrorExit
		    ServerConnect
		    GetStatusInfo
		    ReadUserEmailInfo
		    CheckPermission
		    GetUserVolSets
		    ConfirmIPAddress
		    Header
		    Trailer
		    NavSectionTitle
		    NavSectionStart
		    NavSectionEnd
		    NavLink
		    h1
		    h2
		    $Cgi %In $MyURL $User %Conf $TopDir $LogDir $BinDir $bafs
		    %Status %Info %Jobs @BgQueue @UserQueue @CmdQueue
		    %QueueLen %StatusVolSet
		    $VolSets $VolSetsMTime $ConfigMTime $PrivAdmin
		    %UserEmailInfo $UserEmailInfoMTime %RestoreReq %ArchiveReq
		    $Lang
             );

%EXPORT_TAGS = (
    'all'    => [ @EXPORT_OK ],
);

sub NewRequest
{
    $Cgi = new CGI;
    %In = $Cgi->Vars;

    if ( !defined($bafs) ) {
	ErrorExit($Lang->{BackupAFS__Lib__new_failed__check_apache_error_log})
	    if ( !($bafs = BackupAFS::Lib->new(undef, undef, undef, 1)) );
	$TopDir = $bafs->TopDir();
	$LogDir = $bafs->LogDir();
	$BinDir = $bafs->BinDir();
	%Conf   = $bafs->Conf();
	$Lang   = $bafs->Lang();
	$ConfigMTime = $bafs->ConfigMTime();
        umask($Conf{UmaskMode});
    } elsif ( $bafs->ConfigMTime() != $ConfigMTime ) {
        $bafs->ConfigRead();
	$TopDir = $bafs->TopDir();
	$LogDir = $bafs->LogDir();
	$BinDir = $bafs->BinDir();
        %Conf   = $bafs->Conf();
        $Lang   = $bafs->Lang();
        $ConfigMTime = $bafs->ConfigMTime();
        umask($Conf{UmaskMode});
    }

    #
    # Default REMOTE_USER so in a miminal installation the user
    # has a sensible default.
    #
    $ENV{REMOTE_USER} = $Conf{BackupAFSUser} if ( $ENV{REMOTE_USER} eq "" );

    #
    # We require that Apache pass in $ENV{SCRIPT_NAME} and $ENV{REMOTE_USER}.
    # The latter requires .ht_access style authentication.  Replace this
    # code if you are using some other type of authentication, and have
    # a different way of getting the user name.
    #
    $MyURL  = $ENV{SCRIPT_NAME};
    $User   = $ENV{REMOTE_USER};

    #
    # Handle LDAP uid=user when using mod_authz_ldap and otherwise untaint
    #
    $User   = $1 if ( $User =~ /uid=([^,]+)/i || $User =~ /(.*)/ );

    #
    # Clean up %ENV for taint checking
    #
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
    $ENV{PATH} = $Conf{MyPath};

    #
    # Verify we are running as the correct user
    #
    if ( $Conf{BackupAFSUserVerify}
	    && $> != (my $uid = (getpwnam($Conf{BackupAFSUser}))[2]) ) {
	ErrorExit(eval("qq{$Lang->{Wrong_user__my_userid_is___}}"), <<EOF);
This script needs to run as the user specified in \$Conf{BackupAFSUser},
which is set to $Conf{BackupAFSUser}.
<p>
This is an installation problem.  If you are using mod_perl then
it appears that Apache is not running as user $Conf{BackupAFSUser}.
If you are not using mod_perl, then most like setuid is not working
properly on BackupAFS_Admin.  Check the permissions on
$Conf{CgiDir}/BackupAFS_Admin and look at the documentation.
EOF
    }

    if ( !defined($VolSets) || $bafs->VolSetsMTime() != $VolSetsMTime ) {
	$VolSetsMTime = $bafs->VolSetsMTime();
	$VolSets = $bafs->VolSetInfoRead();

	# turn moreUsers list into a hash for quick lookups
	foreach my $volset (keys %$VolSets) {
	   $VolSets->{$volset}{moreUsers} =
	       {map {$_, 1} split(",", $VolSets->{$volset}{moreUsers}) }
	}
    }

    #
    # Untaint the volset name
    #
    if ( $In{volset} =~ /^([\w.\s-]+)$/ ) {
	$In{volset} = $1;
    } else {
	delete($In{volset});
    }
}

sub timeStamp2
{
    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
              = localtime($_[0] == 0 ? time : $_[0] );
    $mon++;
    if ( $Conf{CgiDateFormatMMDD} == 2 ) {
        $year += 1900;
        return sprintf("%04d-%02d-%02d %02d:%02d", $year, $mon, $mday, $hour, $min);
    } elsif ( $Conf{CgiDateFormatMMDD} ) {
        return sprintf("$mon/$mday %02d:%02d", $hour, $min);
    } else {
        return sprintf("$mday/$mon %02d:%02d", $hour, $min);
    }
}

sub VolSetLink
{
    my($volset) = @_;
    my($s);
    if ( defined($VolSets->{$volset}) || defined($Status{$volset}) ) {
        $s = "<a href=\"$MyURL?volset=${EscURI($volset)}\">$volset</a>";
    } else {
        $s = $volset;
    }
    return \$s;
}

sub UserLink
{
    my($user) = @_;
    my($s);

    return \$user if ( $user eq ""
                    || $Conf{CgiUserUrlCreate} eq "" );
    if ( $Conf{CgiUserHomePageCheck} eq ""
            || -f sprintf($Conf{CgiUserHomePageCheck}, $user, $user, $user) ) {
        $s = "<a href=\""
             . sprintf($Conf{CgiUserUrlCreate}, $user, $user, $user)
             . "\">$user</a>";
    } else {
        $s = $user;
    }
    return \$s;
}

sub EscHTML
{
    my($s) = @_;
    $s =~ s/&/&amp;/g;
    $s =~ s/\"/&quot;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/</&lt;/g;
    ### $s =~ s{([^[:print:]])}{sprintf("&\#x%02X;", ord($1));}eg;
    return \$s;
}

sub EscURI
{
    my($s) = @_;
    $s =~ s{([^\w.\/-])}{sprintf("%%%02X", ord($1));}eg;
    return \$s;
}

sub ErrorExit
{
    my(@mesg) = @_;
    my($head) = shift(@mesg);
    my($mesg) = join("</p>\n<p>", @mesg);

    if ( !defined($ENV{REMOTE_USER}) ) {
	$mesg .= <<EOF;
<p>
Note: \$ENV{REMOTE_USER} is not set, which could mean there is an
installation problem.  BackupAFS_Admin expects Apache to authenticate
the user and pass their user name into this script as the REMOTE_USER
environment variable.  See the documentation.
EOF
    }

    $bafs->ServerMesg("log User $User (volset=$In{volset}) got CGI error: $head")
                            if ( defined($bafs) );
    if ( !defined($Lang->{Error}) ) {
        $mesg = <<EOF if ( !defined($mesg) );
There is some problem with the BackupAFS installation.
Please check the permissions on BackupAFS_Admin.
EOF
        my $content = <<EOF;
${h1("Error: Unable to read config.pl or language strings!!")}
<p>$mesg</p>
EOF
        Header("BackupAFS: Error", $content);
	Trailer();
    } else {
        my $content = eval("qq{$Lang->{Error____head}}");
        Header(eval("qq{$Lang->{Error}}"), $content);
	Trailer();
    }
    exit(1);
}

sub ServerConnect
{
    #
    # Verify that the server connection is ok
    #
    return if ( $bafs->ServerOK() );
    $bafs->ServerDisconnect();
    if ( my $err = $bafs->ServerConnect($Conf{ServerHost}, $Conf{ServerPort}) ) {
        if ( CheckPermission() 
          && -f $Conf{ServerInitdPath}
          && $Conf{ServerInitdStartCmd} ne "" ) {
            my $content = eval("qq{$Lang->{Admin_Start_Server}}");
            Header(eval("qq{$Lang->{Unable_to_connect_to_BackupAFS_server}}"), $content);
            Trailer();
            exit(1);
        } else {
            ErrorExit(eval("qq{$Lang->{Unable_to_connect_to_BackupAFS_server}}"),
                      eval("qq{$Lang->{Unable_to_connect_to_BackupAFS_server_error_message}}"));
        }
    }
}

sub GetStatusInfo
{
    my($status) = @_;
    ServerConnect();
    %Status = ()     if ( $status =~ /\bvolsets\b/ );
    %StatusVolSet = () if ( $status =~ /\bvolset\(/ );
    my $reply = $bafs->ServerMesg("status $status");
    $reply = $1 if ( $reply =~ /(.*)/s );
    eval($reply);
    # ignore status related to admin and trashClean jobs
    if ( $status =~ /\bvolsets\b/ ) {
	foreach my $volset ( grep(/admin/, keys(%Status)) ) {
	    delete($Status{$volset}) if ( $bafs->isAdminJob($volset) );
	}
        delete($Status{$bafs->trashJob});
    }
}

sub ReadUserEmailInfo
{
    if ( (stat("$LogDir/UserEmailInfo.pl"))[9] != $UserEmailInfoMTime ) {
        do "$LogDir/UserEmailInfo.pl";
        $UserEmailInfoMTime = (stat("$LogDir/UserEmailInfo.pl"))[9];
    }
}

#
# Check if the user is privileged.  A privileged user can access
# any information (backup files, logs, status pages etc).
#
# A user is privileged if they belong to the group
# $Conf{CgiAdminUserGroup}, or they are in $Conf{CgiAdminUsers}
# or they are the user assigned to a volset in the volset file.
#
sub CheckPermission
{
    my($volset) = @_;
    my $Privileged = 0;

    return 0 if ( $User eq "" && $Conf{CgiAdminUsers} ne "*"
	       || $volset ne "" && !defined($VolSets->{$volset}) );
    if ( $Conf{CgiAdminUserGroup} ne "" ) {
        my($n,$p,$gid,$mem) = getgrnam($Conf{CgiAdminUserGroup});
        $Privileged ||= ($mem =~ /\b\Q$User\E\b/);
    }
    if ( $Conf{CgiAdminUsers} ne "" ) {
        $Privileged ||= ($Conf{CgiAdminUsers} =~ /\b\Q$User\E\b/);
        $Privileged ||= $Conf{CgiAdminUsers} eq "*";
    }
    $PrivAdmin = $Privileged;
    return $Privileged if ( !defined($volset) );

    $Privileged ||= $User eq $VolSets->{$volset}{user};
    $Privileged ||= defined($VolSets->{$volset}{moreUsers}{$User});
    return $Privileged;
}

#
# Returns the list of volsets that should appear in the navigation bar
# for this user.  If $getAll is set, the admin gets all the volsets.
# Otherwise, regular users get volsets for which they are the user or
# are listed in the moreUsers column in the volsets file.
#
sub GetUserVolSets
{
    my($getAll) = @_;
    my @volsets;

    if ( $getAll && CheckPermission() ) {
        @volsets = sort keys %$VolSets;
    } else {
        @volsets = sort grep { $VolSets->{$_}{user} eq $User ||
                       defined($VolSets->{$_}{moreUsers}{$User}) } keys(%$VolSets);
    }
    return @volsets;
}

#
# Given a volset name tries to find the IP address.  For non-dhcp volsets
# we just return the volset name.  For dhcp volsets we check the address
# the user is using ($ENV{REMOTE_ADDR}) and also the last-known IP
# address for $volset.  (Later we should replace this with a broadcast
# nmblookup.)
#
sub ConfirmIPAddress
{
    my($volset) = @_;
    my $ipAddr = $volset;

    if ( defined($VolSets->{$volset}) && $VolSets->{$volset}{dhcp}
	       && $ENV{REMOTE_ADDR} =~ /^(\d+[\.\d]*)$/ ) {
	$ipAddr = $1;
	my($netBiosVolSet, $netBiosUser) = $bafs->NetBiosInfoGet($ipAddr);
	if ( $netBiosVolSet ne $volset ) {
	    my($tryIP);
	    GetStatusInfo("volset(${EscURI($volset)})");
	    if ( defined($StatusVolSet{dhcpVolSetIP})
			&& $StatusVolSet{dhcpVolSetIP} ne $ipAddr ) {
		$tryIP = eval("qq{$Lang->{tryIP}}");
		($netBiosVolSet, $netBiosUser)
			= $bafs->NetBiosInfoGet($StatusVolSet{dhcpVolSetIP});
	    }
	    if ( $netBiosVolSet ne $volset ) {
		ErrorExit(eval("qq{$Lang->{Can_t_find_IP_address_for}}"),
		          eval("qq{$Lang->{volset_is_a_DHCP_volset}}"));
	    }
	    $ipAddr = $StatusVolSet{dhcpVolSetIP};
	}
    }
    return $ipAddr;
}

###########################################################################
# HTML layout subroutines
###########################################################################

sub Header
{
    my($title, $content, $noBrowse, $contentSub, $contentPost) = @_;
    my @adminLinks = (
        { link => "",                      name => $Lang->{Status}},
        { link => "?action=summary",       name => $Lang->{PC_Summary}},
        { link => "?action=editConfig",    name => $Lang->{CfgEdit_Edit_Server_Config},
                                           priv => 1},
        { link => "?action=editConfig&newMenu=volsets",
                                           name => $Lang->{CfgEdit_Edit_VolSets},
                                           priv => 1},
        { link => "?action=adminOpts",     name => $Lang->{Admin_Options},
                                           priv => 1},
        { link => "?action=view&type=LOG", name => $Lang->{Server_LOG_file},
                                           priv => 1},
        { link => "?action=LOGlist",       name => $Lang->{Server_LOG_files},
                                           priv => 1},
        { link => "?action=emailSummary",  name => $Lang->{Email_summary},
                                           priv => 1},
        { link => "?action=queue",         name => $Lang->{Current_queues},
                                           priv => 1},
        @{$Conf{CgiNavBarLinks} || []},
    );
    my $volset = $In{volset};

    binmode(STDOUT, ":utf8");
    print $Cgi->header(-charset => "utf-8");
    print <<EOF;
<!doctype html public "-//W3C//DTD HTML 4.01 Transitional//EN">
<html><head>
<title>$title</title>
<link rel=stylesheet type="text/css" href="$Conf{CgiImageDirURL}/$Conf{CgiCSSFile}" title="CSSFile">
<link rel="shortcut icon" href="$Conf{CgiImageDirURL}/BackupAFS_favicon.ico" type="image/x-icon">
<link rel="icon" href="$Conf{CgiImageDirURL}/BackupAFS_favicon.gif" type="image/gif">
$Conf{CgiHeaders}
<script src="$Conf{CgiImageDirURL}/sorttable.js"></script>
<style>
 body
  {
    background-image: url("$Conf{CgiImageDirURL}/BackupAFS-logo.gif");
    background-repeat: no-repeat
  }
</style>
</head><body onLoad="document.getElementById('NavMenu').style.height=document.body.scrollHeight">
<div class="SiteLogo"><img src="$Conf{CgiImageDirURL}/Site-logo.gif" border="0"></div>
EOF

    print "<div class=\"NavSpacer\"></div>";
    if ( defined($VolSets) && defined($volset) && defined($VolSets->{$volset}) ) {
	print "<div class=\"NavMenu\">";
	NavSectionTitle("${EscHTML($volset)}");
	print <<EOF;
</div>
<div class="NavMenu">
EOF
	NavLink("?volset=${EscURI($volset)}",
		"$volset $Lang->{Home}", " class=\"navbar\"");
	NavLink("?action=browse&volset=${EscURI($volset)}",
		$Lang->{Browse}, " class=\"navbar\"") if ( !$noBrowse );
	NavLink("?action=view&type=LOG&volset=${EscURI($volset)}",
		$Lang->{VolumeSet_LOG_file}, " class=\"navbar\"");
	NavLink("?action=LOGlist&volset=${EscURI($volset)}",
		$Lang->{VolumeSet_LOG_files}, " class=\"navbar\"");
	if ( -f "$TopDir/volsets/$volset/XferLOG.bad"
		    || -f "$TopDir/volsets/$volset/XferLOG.bad.z" ) {
	   NavLink("?action=view&type=XferLOGbad&volset=${EscURI($volset)}",
		    $Lang->{Last_bad_XferLOG}, " class=\"navbar\"");
	   NavLink("?action=view&type=XferErrbad&volset=${EscURI($volset)}",
		    $Lang->{Last_bad_XferLOG_errors_only},
		    " class=\"navbar\"");
	}
        if ( $Conf{CgiUserConfigEditEnable} || $PrivAdmin ) {
            NavLink("?action=editConfig&volset=${EscURI($volset)}",
                    $Lang->{CfgEdit_Edit_VS_Config}, " class=\"navbar\"");
        } elsif ( -f "$TopDir/volsets/$volset/config.pl"
                    || ($volset ne "config" && -f "$TopDir/conf/$volset.pl") ) {
            NavLink("?action=view&type=config&volset=${EscURI($volset)}",
                    $Lang->{Config_file}, " class=\"navbar\"");
        }
	print "</div>\n";
    }
    print("<div id=\"Content\">\n$content\n");
    if ( defined($contentSub) && ref($contentSub) eq "CODE" ) {
	while ( (my $s = &$contentSub()) ne "" ) {
	    print($s);
	}
    }
    print($contentPost) if ( defined($contentPost) );
    print <<EOF;
<br><br><br>
</div>
<div class="NavMenu" id="NavMenu"> 
EOF
    my $volsetSelectbox = "<option value=\"#\">$Lang->{Select_a_volset}</option>";
    my @volsets = GetUserVolSets($Conf{CgiNavBarAdminAllVolSets});
    NavSectionTitle($Lang->{VolSets});
    if ( defined($VolSets) && %$VolSets > 0 && @volsets ) {
        foreach my $volset ( @volsets ) {
	    NavLink("?volset=${EscURI($volset)}", $volset)
		    if ( @volsets < $Conf{CgiNavBarAdminAllVolSets} );
	    my $sel = " selected" if ( $volset eq $In{volset} );
	    $volsetSelectbox .= "<option value=\"?volset=${EscURI($volset)}\"$sel>"
			    . "$volset</option>";
        }
    }
    if ( @volsets >= $Conf{CgiNavBarAdminAllVolSets} ) {
        print <<EOF;
<br>
<select onChange="document.location=this.value">
$volsetSelectbox
</select>
<br><br>
EOF
    }
    if ( $Conf{CgiSearchBoxEnable} ) {
        print "...or type a VolumeSet's name<br>\n";
        print <<EOF;
<form action="$MyURL" method="get">
    <input type="text" name="volset" size="14" maxlength="64">
    <input type="hidden" name="action" value="volsetInfo"><input type="submit" value="$Lang->{Go}" name="ignore">
    </form>
EOF
    }
    NavSectionTitle($Lang->{NavSectionTitle_});
    foreach my $l ( @adminLinks ) {
        if ( $PrivAdmin || !$l->{priv} ) {
            my $txt = $l->{lname} ne "" ? $Lang->{$l->{lname}} : $l->{name};
            NavLink($l->{link}, $txt);
        }
    }

    print <<EOF;
<br><br><br>
</div>
EOF
}

sub Trailer
{
    print <<EOF;
</body></html>
EOF
}


sub NavSectionTitle
{
    my($head) = @_;
    print <<EOF;
<div class="NavTitle">$head</div>
EOF
}

sub NavSectionStart
{
}

sub NavSectionEnd
{
}

sub NavLink
{
    my($link, $text) = @_;
    if ( defined($link) ) {
        my($class);
        $class = " class=\"NavCurrent\""
                if ( length($link) && $ENV{REQUEST_URI} =~ /\Q$link\E$/
                    || $link eq "" && $ENV{REQUEST_URI} !~ /\?/ );
        $link = "$MyURL$link" if ( $link eq "" || $link =~ /^\?/ );
        print <<EOF;
<a href="$link"$class>$text</a>
EOF
    } else {
        print <<EOF;
$text<br>
EOF
    }
}

sub h1
{
    my($str) = @_;
    return \<<EOF;
<div class="h1">$str</div>
EOF
}

sub h2
{
    my($str) = @_;
    return \<<EOF;
<div class="h2">$str</div>
EOF
}
