#!/usr/bin/perl
#============================================================= -*-perl-*-
#
# getvols.pl
#
# DESCRIPTION
#   Query the (Open)AFS backup database. Construct a list of volumes
#   that match the regexps for a given volumeset. See the openafs
#   documentation <http://www.openafs.org> for information on creating
#   volumesets.
#
#   NOTE: This script assumes that it can use "-localauth", that is that
#   the cell's keyfile is available and readable by the user running this
#   script (normally backup or backuppc). This is a security concern!
#   You should take pains to ensure that normal users, even those
#   authenticated via the CGI, cannot read the keyfile. In all locations.
#   Including the backuppc server's backup, if the same instance of
#   backuppc does both.
#   An alternative is ensure that the user running this script has tokens
#   capable of accessing the backup database. In this case, "-localauth"
#   may be removed. If you choose to do this, you're on your own.
#   I decided that I'd rather limit the amount of code that runs with access
#   to the keys to the kingdom.
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


#$volset = 'panic1'; #get from @arg
my $volset = shift;

($VOS) = grep { -x $_ } qw(/usr/bin/vos /usr/sbin/vos /usr/afsws/etc/vos);

$VOS ||= '/usr/afsws/etc/vos';

($BACKUP) = grep { -x $_ } qw(/usr/sbin/backup /usr/afsws/etc/backup);

$BACKUP ||= '/usr/afsws/etc/backup';

#print "VOS: $VOS\nBACKUP: $BACKUP\n";
print "volumeset $volset\n";
open ENTRIES,"$BACKUP listvolsets -name $volset -localauth|" or die
	"can't open backup to get volumeset entries: $!\n";

while (<ENTRIES>) {
	chomp;
	$line=$_;
	if ($line=~/access to database denied/) {
		close ENTRIES;
		die "Access to backup database denied. Do you have tokens?\n";
	}
	if ($line=~/an't find/) {
		close ENTRIES;
		die "Can't find requested volume set: $line\n";
	}
	next if ( ! ($line =~/Entry\s*\d+:/));
	print "$line\n";
	$line=~s/Entry\s*\d+:\s*//g;
	my ($sre,$pre,$vre)=split(",",$line);
	$sre=~s/\s*server\s*//g;

	#debug
	#$sre=".*gen.*";
	#$vre="user.*\.backup";
	$pre=~s/\s*partition\s*//g;
	$vre=~s/\s*volumes:\s*//g;
	#print "server pattern: \"$sre\"\n";
	#print "partition pattern: \"$pre\"\n";
	#print "volume pattern: \"$vre\"\n";
	my $servers;
	open GS,"$VOS listaddrs -localauth|" or die "cant run vos listaddrs: $!\n";
	while (<GS>) {
		chomp;
		$addr=$_;
		if ($addr=~/^$sre$/) {
			#print "server: $addr\n";
		} else { next; }

		# we have a server... find the partitions
		open GP,"$VOS listpart -server $addr -localauth|" or die "cant run vos listpart: $!\n";
		while (<GP>) {
			chomp;
			next unless m:/vice:;
			s/^\s+//g;
			s/\s+$//g;
			foreach my $partname (split) {
				if ($partname=~/^$pre$/) {
					#print "partition: $partname\n";
					#print ".";
				} else { next; }
			
				# we have a partition.. get the volumes

				#open GV,"$VOS listvol -server $addr -partition $partname -localauth|" or die "can't run vos listvol: $!\n";
				#while (<GV>) {
				#	chomp;
				#	my $pv=$_;
				#	next if $pv=~/^$/;
				#	next if $pv=~/^Total/;
				#	next if $pv=~/^\s/;
				#	$pv=(split(/\s+/,$pv))[0];
				#	next unless $pv=~/^$vre$/;
				#	print "+";
				#	#print "Volume: $pv\n";
				#	push (@volumes, $pv);
				#}
				open GV,"$VOS listvldb -server $addr -partition $partname -quiet -localauth|" or die "can't run vos listvldb: $!\n";
				while (<GV>) {
					chomp;
					next if ($_=~/^\s+/);
					next if ($_=~/^$/);
					my $pv=$_;
					$pv=~s/\s+$//g;
					$pv="$pv.backup";
					#print "debug: \"$pv\"\n";
					next unless $pv=~/^$vre$/;
					#print "+";
					push (@volumes, $pv);
				}


			}

		}
	}
	#print "\n";
}
# Uniquify the list, just in case of multihomed fileservers
undef %saw;
@saw{@volumes} = ();
@ndvolumes = sort keys %saw;
#print "VOLUMES: @ndvolumes\n";

for $volume (@ndvolumes) {
	print "VOLUME:$volume\n";
#	system ("vos examine $volume | grep On-line");
}
