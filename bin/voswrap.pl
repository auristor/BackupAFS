#!/usr/bin/perl
#============================================================= -*-perl-*-
#
# voswrap.pl
#
# DESCRIPTION
#   Takes backuppc arguments and actually runs the "vos dump" and
#   "vos restore" commands necessary to backup and restore volumes
#   from AFS <http://www.openafs.org>
#
#   There are currently lots of places that the code could be cleaned up.
#   This should be considered a proof of concept.
#
#   NOTE: This script assumes that it can use "-localauth", that is that
#   the cell's keyfile is available and readable by the user running this
#   script (normally backup or backuppc). This is a security concern!
#   You should take pains to ensure that normal users, even those
#   authenticated via the CGI, cannot read the keyfile. In all locations.
#   Including the backuppc server's backup, if the same instance of
#   backuppc does both.
#   An alternative is ensure that the user running this script has tokens
#   capable of performing vos dumps. In this case, "-localauth"
#   may be removed. If you choose to do this, you're on your own.
#   I decided that I'd rather limit the amount of code that runs with access
#   to the keys to the kingdom.
#
#   NOTE2: We don't do file pooling. On purpose. Hear me out. AFS volume
#   dump files can range from under 1MB up to 10's or 100+ GBs, depending
#   on the size of the volume being dumped. We don't want to compute a hash
#   on 100GB files, let alone do complete file comparisons on 100GB files
#   when hashes do collide. Besides that, every .vdmp file is of a freshly
#   created .backup volume. Even if the volume contents hasn't changed,
#   its metadata, which is encoded in the file, has (Creation date, etc).
#
#   TODO: Consider using the AFS perl module (and compression)
#
# AUTHOR
#   Stephen Joyce  <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2006  Stephen Joyce
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
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
# Version 3.0.0, released 28 Jan 2007.
#

use File::Basename;
use Getopt::Long;

sub getLevel {
	# Given a backup number, parse the BPC backups file to determine
	# that backup's level.
	my ($dump) = @_;
	my $level = undef;
	my $backupsfile = "$clientDir/backups";
	open BF,"<$backupsfile" or die "Couldn't open backups file for reading";
	while (<BF>) {
		my $line=$_;
		next if ( !($line=~/^$dump\t/));
		# got our dump. Whew!
		$level = (split /\t/,$line)[21];
		last;
	}
	close (BF);
        $level = 0 if ( !$level);
	return $level;
}

sub restoreaFile {
	# Given the path to a .vdmp file (created by vos dump), perform
	# a vos restore, using the args provided by the admin
	my ($path) = @_;
	my $vosrestoreargs;
	print " **** vos restore $path\n"; # XXX123
	my @path = split/\//,$path;
	#my $filename = @path[$#path];
        my ($filename,$dirname,$suffix) = fileparse ($path,"");

	# Yank the volumename out of the filename and unmangle it
	my $volume = $filename;
	$volume=~s/-\d\d\d\d_\d\d_\d\d_\d\d_\d\d_\d\d-L\d\.vdmp//g;
	$volume=~s/^f//g;

	# vos restore doesn't understand "-extension" unlike afs' backup
	# program. So we emulate it here since the admin probably doesn't
	# often want to overwrite the original when restoring a volume.
	# Simply append the value to $volume.
	# XXX what's that volumename length limit again??
	for my $arg ( split /-+/,$restoreargs) {
		next if (!$arg);
		if ($arg=~/extension/) {
			my ($keyword,$value) = split /\s+/,$arg;
			$volume=$volume . "$value";
		} else {
			$vosrestoreargs = $vosrestoreargs . "-$arg";
		}
	}
	if ($filename=~/-L0.vdmp/ ) {
		# it's a full (Level 0) dump file
		$vosrestoreargs = $vosrestoreargs . " -overwrite full -verbose";
	} elsif ($filename=~/L\d.vdmp$/) {
		$vosrestoreargs = $vosrestoreargs . " -overwrite incremental -verbose";
	} else {
		# should never be reached
		$vosrestoreargs = $vosrestoreargs . " -overwrite abort -verbose";
	}
        chdir "$dirname" or die "Couldn't change to dir $dir: $!\n";
	my $cmd = "$VOS restore -file $filename -name $volume $vosrestoreargs -localauth";
	print "$cmd\n";
	my $failure=1;
	open (VRES, "$cmd 2>&1 |") or warn "Couldn't restore $volume from $path\n";
	while (<VRES>) {
		chomp;
		my $line=$_;
		print "\"$line\"\n";
		$failure=0 if ($line=~/^Restored volume/);
	}
	close (VRES);
	die "Error with vos restore\n" if ($failure);

	# XXX This ls crap is ugly.. should do something better. Perhaps
	# stat? vos examine?
	my $listing = `/bin/ls -l $path`;
	$byteCnt+=(split /\s+/,$listing)[4];
	$fileCnt+=1;
}


sub restoreaDir {
	# Technically we can only restore files, so perhaps this
	# should be parseaDir. Regardless, traverse the tree looking
	# for files to restore.
	my ($dir) = @_;
	opendir(DIR, $dir) or warn "couldn't read $dir for restoration\n";
	my @names = readdir(DIR);
	for my $name (@names) {
		next if (($name eq ".") || ($name eq ".."));
		restoreaDir ("$dir/$name") if (-d "$dir/$name");
		restoreaFile ("$dir/$name") if (-f "$dir/$name");
	}
	close (DIR);
}

sub IncrIsNecessary {
	my ($volume)=@_;
	my $update, $dumpdate = undef;
		$dumpdate = $incrDate;
		my ($date,$time)=split /\s+/,$dumpdate;
		my ($year,$monthnum,$dom)=split /-/,$date;
		my ($hour,$min,$sec)=split /:/,$time;
		$dumpdate = $year . $monthnum . $dom . $hour . $min . $sec;
		print "$volume dumped $dumpdate,";
	open (VEX, "$VOS examine $volume -localauth|") or warn "couldn't examine $volume\n";
	while (<VEX>) {
		my $line=$_;
		next unless ($line=~/Last Update/);
		$update=$line;
		$update=~s/^\s+Last Update\s+//g;

		# sometimes a volume is "Never" modified. ?!?
		$update = "Thu Aug 24 21:36:00 1972" if ($update=~/ever/);

		my ($dow,$month,$dom,$time,$year)=split /\s+/,$update;
		my ($hour,$min,$sec)=split /:/,$time;
		$dom = "0$dom" unless ($dom=~/\d\d/);
		%map = (
			Jan => "01",
			Feb => "02",
			Mar => "03",
			Apr => "04",
			May => "05",
			Jun => "06",
			Jul => "07",
			Aug => "08",
			Sep => "09",
			Oct => "10",
			Nov => "11",
			Dec => "12",
		);
		my $monthnum = $map{$month};
		$update = $year . $monthnum . $dom . $hour . $min . $sec;

		print " last updated $update\n";
		last;
	}
	close (VEX);
	if ($dumpdate < $update ) {
		# if dumpdate is older (less than) volume update,
		# IncrIsNecessary is true
		return 1;
	} else {
		return 0;
	}
}

sub bynumber {
	$a <=> $b;
}

sub parse_args {
        &GetOptions ("volume=s","type=s","incrDate=s","incrLevel=s","clientDir=s","dest=s","restoreDir=s","bkupSrcNum=s","bkupSrcHost=s","fileList=s@");
        if ($opt_volume) {
                $volume=$opt_volume;
        }
        if ($opt_type) {
                $type=$opt_type;
        }
        if ($opt_incrDate) {
                $incrDate=$opt_incrDate;
        }
        if ($opt_incrLevel) {
                $incrLevel=$opt_incrLevel;
        }
	if ($opt_clientDir) {
		$clientDir=$opt_clientDir;
	}
	if ($opt_dest) {
		$dest=$opt_dest;
	}
	if ($opt_restoreDir) {
		$restoreDir=$opt_restoreDir;
	}
	if ($opt_bkupSrcNum) {
		$bkupSrcNum=$opt_bkupSrcNum;
	}
	if ($opt_bkupSrcHost) {
		$bkupSrcHost=$opt_bkupSrcHost;
	}
	if (@opt_fileList) {
		@fileList=@opt_fileList;
	}
	#die "\tUSAGE: XXXX\n" if (!($opt_volume && $opt_type && $opt_incrDate && $opt_dest && $opt_clientDir )); 
	$incrLevel = 0 if ( ! $incrLevel);
}

($VOS) = grep { -x $_ } qw(/usr/bin/vos /usr/sbin/vos /usr/afsws/etc/vos);

$VOS ||= '/usr/bin/vos';

parse_args();
my $vosop=undef;


#print "$0 called with volume:$volume type:$type incrDate:$incrDate incrLevel:$incrLevel clientDir:$clientDir dest:$dest restoreDir:$restoreDir fileList:@fileList\n";

if (( $type eq "full" ) || ( $type eq "incr" )) {
	$vosop = "dump";

	# We can't vos backup ".backup" volumes. *sigh*
	$RWvolume = $volume;
	$RWvolume =~s/\.backup$//g;

	# setup the dir for BackupPC. We do this regardless, because
	# if we don't mkdir and we don't need to do an incremental dump
	#(because of no updates), then no parent dumps of this volume
	# would show up when browsing via the CGI at this level.
	system("/bin/mkdir -p $dest/f%2f/f$RWvolume"); # Ugly as sin.

	my $cmd = "$VOS backup -id $RWvolume -localauth";
	print "$cmd\n";
	my $failure = 1;
	open (VBU, "$cmd 2>&1 |") or die "Couldn't create backup volume of $RWvolume\n";
	while (<VBU>) {
		$failure=0 if ($_=~/Created backup volume/)
	}
	close (VBU);
	die "Error with vos backup\n" if ($failure);

	if (($type eq "incr") && (IncrIsNecessary($volume) == 0)) {
		# Cowardly refuse to dump an unchanged volume
		print "Cowardly refusing to dump an unchanged volume\n";
		print "Total files: 0\n";
		print "Total bytes: 0\n";
		exit 0;
	}

	# The volume is now frozen (.backup created) and ready for dumping.
	# Note that the dump timestamp recorded by backuppc should not really
	# be the timestamp that backuppc finishes the dump, but rather the
	# timestamp of the above command. It's beyond the scope of this
	# XferMethod to change that, however. Instead we settle for naming
	# our files with the real date&time that the .backup volume was created
	# and remembering that backuppc defaults to an incremental-time
	# one hour prior to the last successful dump. For VERY LARGE volumes,
	# this value (3600 in Vos.pm) may need to be adjusted upwards. The
	# tradeoff being that more data may be unnecessarily dumped for
	# volumes that change often.

	my $backuptime=0;
		open (VEX, "$VOS examine $volume -localauth|") or die "Couldn't examine volume $volume\n";
		while (<VEX>) {
			my $line=$_;
			next unless ($line=~/Creation/);
			my $creationdate=$line;
			$creationdate=~s/^\s+Creation\s+//g;
			my ($dow,$month,$dom,$time,$year)=split /\s+/,$creationdate;
			my ($hour,$min,$sec)=split /:/,$time;
			$dom = "0$dom" unless ($dom=~/\d\d/);
			%map = (
				Jan => "01",
				Feb => "02",
				Mar => "03",
				Apr => "04",
				May => "05",
				Jun => "06",
				Jul => "07",
				Aug => "08",
				Sep => "09",
				Oct => "10",
				Nov => "11",
				Dec => "12",
			);
			my $monthnum = $map{$month};
			# We're constructing part of the filename for the
			# vos dump here. Do NOT change this or you will
			# break other parts of this script which make
			# assumptions about the naming (sorting and
			# restorations). You've been warned.
			$backuptime="$year"."_"."$monthnum"."_"."$dom"."_"."$hour"."_"."$min"."_"."$sec";
			my ($day,$hour)=split /\s+/,$time;
			print "Volume created on: $creationdate\n";
			print "Backup file time: $backuptime\n";
		}
		close (VEX);
	# Again, pleased to not be touching the file name.
	my $file = "f%2f/f$RWvolume/f$RWvolume-$backuptime-L$incrLevel.vdmp";
	my $NFLfile = "$dest/$RWvolume/$RWvolume-$backuptime-L$incrLevel.vdmp";

	if ($type eq "full") {
		$time = 0;
		print "Doing a full backup\n";
	} else {
		# Of COURSE vos dump expects the "-time" value to be in
		# a different format than BackupPC uses. Epoch anyone?
		$time = $incrDate;
		my ($day,$hour)=split /\s+/,$time;
		$day=join("/",(split /-/,$day)[1,2,0]);
		$time="$day $hour";
		print "Doing an incremental backup for $time\n";
	}

	# OK, finally do the dump and then add the file to NewFileList.
	# XXX attrib files? Not really important for us as long as the
	# backuppc user can read and write the dump files. But it would be
	# nice if we could say "BackupPC_makeattrib".
        chdir "$dest" or die "Couldn't change to dir $dir while dumping $volume: $!\n";
	my $cmd = "$VOS $vosop -id $volume -time \"$time\" -file $file -verbose -localauth";
	#system("$cmd");
	print "$cmd\n";
	$failure = 1;
	open (VDMP, "$cmd 2>&1 |") or die "Couldn't dump $volume\n";
	while (<VDMP>) {
		chomp;
		my $line=$_;
		print "\"$line\"\n";
		$failure = 0 if ( $line=~/Dumped volume/)
	}
	close (VDMP);
	die "Error with vos dump\n" if ($failure);

	my $cmd = "/bin/echo $NFLfile >> $clientDir/NewFileList";
	system("$cmd");

	# XXX ls is an ugly way to get this info.
	my $listing = `/bin/ls -l $dest/$file`;
	my $byteCnt=(split /\s+/,$listing)[4];
	my $fileCnt=1;
	print "Total files: $fileCnt\n";
	print "Total bytes: $byteCnt\n";
} else {
	$vosop = "restore";
	# yank info out of $restoreDir
	# format is UserProvidedArgs/extension, assuming that the user didn't
	# specify the partition as /vicepX.. if they did, preserve their
	# partition name. This is necessary because BackupPC concatenates
	# the sharename and restoredir. Yes, this workaround is stupid,
	#but perl loves string matching.
	$restoreDir=~s/\/vicep/SomeStringAUserWouldNotType/g;
	$restoreargs = (split /\//,$restoreDir)[0];
	$restoreargs=~s/SomeStringAUserWouldNotType/\/vicep/g;
	die "Not enough information to restore volume(s)" unless (
		($restoreargs=~/-server /) &&
		($restoreargs=~/-partition /));

	# discover the parents of $bkupSrcNum
	my $level = getLevel($bkupSrcNum);
	my @backupdirs = ();
	push (@backupdirs, $bkupSrcNum);
	for ( $i = $bkupSrcNum ; $level > 0 && $i >= 0; $i--) {
		$testlevel = getLevel($i);
		next if ($testlevel >= $level );

		# $i's level is < current level... so it's a parent dump
		$level = $testlevel; #2
		push (@backupdirs, $i);
		print "Found parent dump $i, level:$level\n";
	}

	my @filelist = sort (@fileList); # alphanumeric is ok here.

	@backupdirs = sort bynumber @backupdirs; # bynumber!

	# When restoring multiple volumes at the same time, some
	# volumes would reach total restoration faster if these
	# nested loops were inverted. But the code would be quite a
	# bit more complicated.
	foreach my $datadir (@backupdirs) {
		print "searching $clientDir/$datadir...";
		foreach my $file (@filelist ) {
			my $mangfile=$file;
			$mangfile = join ("/f",split /\//,$mangfile);
			$mangfile = "f%2f" . $mangfile unless ($mangfile=~/^f%2f/);
			restoreaDir ("$clientDir/$datadir/$mangfile") if (-d "$clientDir/$datadir/$mangfile");
			restoreaFile ("$clientDir/$datadir/$mangfile") if (-f "$clientDir/$datadir/$mangfile");
			# I should probably remove $mangfile from @filelist once
			# restored... but not at 4am XXX
		}
	}
	print "Total files: $fileCnt\n";
	print "Total bytes: $byteCnt\n";

}
exit 0;
