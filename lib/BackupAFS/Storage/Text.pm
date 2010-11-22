#============================================================= -*-perl-*-
#
# BackupAFS::Storage::Text package
#
# DESCRIPTION
#
#   This library defines a BackupAFS::Storage::Text class that implements
#   BackupAFS's persistent state storage (config, volset info, backup
#   and restore info) using text files.
#
# AUTHOR
#   Craig Barratt  <cbarratt@users.sourceforge.net>
#   Stephen Joyce <stephen@physics.unc.edu>
#
# COPYRIGHT
#   Copyright (C) 2004-2009  Craig Barratt
#   opyright (C) 2010 Stephen Joyce
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

package BackupAFS::Storage::Text;

use strict;
use vars qw(%Conf);
use Data::Dumper;
use File::Path;
use Fcntl qw/:flock/;

sub new
{
    my $class = shift;
    my($flds, $paths) = @_;

    my $s = bless {
	%$flds,
	%$paths,
    }, $class;
    return $s;
}

sub setPaths
{
    my $class = shift;
    my($paths) = @_;

    foreach my $v ( keys(%$paths) ) {
        $class->{$v} = $paths->{$v};
    }
}

sub BackupInfoRead
{
    my($s, $volset) = @_;
    local(*BK_INFO, *LOCK);
    my(@Backups);

    flock(LOCK, LOCK_EX) if open(LOCK, "$s->{TopDir}/volsets/$volset/LOCK");
    if ( open(BK_INFO, "$s->{TopDir}/volsets/$volset/backups") ) {
	binmode(BK_INFO);
        while ( <BK_INFO> ) {
            s/[\n\r]+//;
            next if ( !/^(\d+\t(incr|full|partial).*)/ );
            $_ = $1;
            @{$Backups[@Backups]}{@{$s->{BackupFields}}} = split(/\t/);
        }
        close(BK_INFO);
    }
    close(LOCK);
    #
    # Default the version field.  Prior to 3.0.0 the xferMethod
    # field is empty, so we use that to figure out the version.
    #
    for ( my $i = 0 ; $i < @Backups ; $i++ ) {
        next if ( $Backups[$i]{version} ne "" );
        if ( $Backups[$i]{xferMethod} eq "" ) {
            $Backups[$i]{version} = "2.1.2";
        } else {
            $Backups[$i]{version} = "3.0.0";
        }
    }
    return @Backups;
}

sub BackupInfoWrite
{
    my($s, $volset, @Backups) = @_;
    my($i, $contents, $fileOk);

    #
    # Generate the file contents
    #
    for ( $i = 0 ; $i < @Backups ; $i++ ) {
        my %b = %{$Backups[$i]};
        $contents .= join("\t", @b{@{$s->{BackupFields}}}) . "\n";
    }
    
    #
    # Write the file
    #
    return $s->TextFileWrite("$s->{TopDir}/volsets/$volset/backups", $contents);
}

sub RestoreInfoRead
{
    my($s, $volset) = @_;
    local(*RESTORE_INFO, *LOCK);
    my(@Restores);

    flock(LOCK, LOCK_EX) if open(LOCK, "$s->{TopDir}/volsets/$volset/LOCK");
    if ( open(RESTORE_INFO, "$s->{TopDir}/volsets/$volset/restores") ) {
	binmode(RESTORE_INFO);
        while ( <RESTORE_INFO> ) {
            s/[\n\r]+//;
            next if ( !/^(\d+.*)/ );
            $_ = $1;
            @{$Restores[@Restores]}{@{$s->{RestoreFields}}} = split(/\t/);
        }
        close(RESTORE_INFO);
    }
    close(LOCK);
    return @Restores;
}

sub RestoreInfoWrite
{
    my($s, $volset, @Restores) = @_;
    local(*RESTORE_INFO, *LOCK);
    my($i, $contents, $fileOk);

    #
    # Generate the file contents
    #
    for ( $i = 0 ; $i < @Restores ; $i++ ) {
        my %b = %{$Restores[$i]};
        $contents .= join("\t", @b{@{$s->{RestoreFields}}}) . "\n";
    }

    #
    # Write the file
    #
    return $s->TextFileWrite("$s->{TopDir}/volsets/$volset/restores", $contents);
}

sub ArchiveInfoRead
{
    my($s, $volset) = @_;
    local(*ARCHIVE_INFO, *LOCK);
    my(@Archives);

    flock(LOCK, LOCK_EX) if open(LOCK, "$s->{TopDir}/volsets/$volset/LOCK");
    if ( open(ARCHIVE_INFO, "$s->{TopDir}/volsets/$volset/archives") ) {
        binmode(ARCHIVE_INFO);
        while ( <ARCHIVE_INFO> ) {
            s/[\n\r]+//;
            next if ( !/^(\d+.*)/ );
            $_ = $1;
            @{$Archives[@Archives]}{@{$s->{ArchiveFields}}} = split(/\t/);
        }
        close(ARCHIVE_INFO);
    }
    close(LOCK);
    return @Archives;
}

sub ArchiveInfoWrite
{
    my($s, $volset, @Archives) = @_;
    local(*ARCHIVE_INFO, *LOCK);
    my($i, $contents, $fileOk);

    #
    # Generate the file contents
    #
    for ( $i = 0 ; $i < @Archives ; $i++ ) {
        my %b = %{$Archives[$i]};
        $contents .= join("\t", @b{@{$s->{ArchiveFields}}}) . "\n";
    }

    #
    # Write the file
    #
    return $s->TextFileWrite("$s->{TopDir}/volsets/$volset/archives", $contents);
}

#
# Write a text file as safely as possible.  We write to
# a new file, verify the file, and the rename the file.
# The previous version of the file is renamed with a
# .old extension.
#
sub TextFileWrite
{
    my($s, $file, $contents) = @_;
    local(*FD, *LOCK);
    my($fileOk);

    (my $dir = $file) =~ s{(.+)/(.+)}{$1};

    if ( !-d $dir ) {
        eval { mkpath($dir, 0, 0775) };
        return "TextFileWrite: can't create directory $dir" if ( $@ );
    }
    if ( open(FD, ">", "$file.new") ) {
	binmode(FD);
        print FD $contents;
        close(FD);
        #
        # verify the file
        #
        if ( open(FD, "<", "$file.new") ) {
            binmode(FD);
            if ( join("", <FD>) ne $contents ) {
                return "TextFileWrite: Failed to verify $file.new";
            } else {
                $fileOk = 1;
            }
            close(FD);
        }
    }
    if ( $fileOk ) {
        my $lock;
        
        if ( open(LOCK, "$dir/LOCK") || open(LOCK, ">", "$dir/LOCK") ) {
            $lock = 1;
            flock(LOCK, LOCK_EX);
        }
        if ( -s "$file" ) {
            unlink("$file.old")           if ( -f "$file.old" );
            rename("$file", "$file.old")  if ( -f "$file" );
        } else {
            unlink("$file") if ( -f "$file" );
        }
        rename("$file.new", "$file") if ( -f "$file.new" );
        close(LOCK) if ( $lock );
    } else {
        return "TextFileWrite: Failed to write $file.new";
    }
    return;
}

sub ConfigPath
{
    my($s, $volset) = @_;

    return "$s->{ConfDir}/config.pl" if ( !defined($volset) );
    if ( $s->{useFHS} ) {
        return "$s->{ConfDir}/volsets/$volset.pl";
    } else {
        return "$s->{TopDir}/volsets/$volset/config.pl"
            if ( -f "$s->{TopDir}/volsets/$volset/config.pl" );
        return "$s->{ConfDir}/$volset.pl"
            if ( $volset ne "config" && -f "$s->{ConfDir}/$volset.pl" );
        return "$s->{ConfDir}/volsets/$volset.pl";
    }
}

sub ConfigDataRead
{
    my($s, $volset, $prevConfig) = @_;
    my($ret, $mesg, $config, @configs);

    #
    # TODO: add lock
    #
    my $conf = $prevConfig || {};
    my $configPath = $s->ConfigPath($volset);

    push(@configs, $configPath) if ( -f $configPath );
    foreach $config ( @configs ) {
        %Conf = %$conf;
        if ( !defined($ret = do $config) && ($! || $@) ) {
            $mesg = "Couldn't open $config: $!" if ( $! );
            $mesg = "Couldn't execute $config: $@" if ( $@ );
            $mesg =~ s/[\n\r]+//;
            return ($mesg, $conf);
        }
        %$conf = %Conf;
    }

    #
    # Handle backward compatibility with defunct BlackoutHourBegin,
    # BlackoutHourEnd, and BlackoutWeekDays parameters.
    #
    if ( defined($conf->{BlackoutHourBegin}) ) {
        push(@{$conf->{BlackoutPeriods}},
             {
                 hourBegin => $conf->{BlackoutHourBegin},
                 hourEnd   => $conf->{BlackoutHourEnd},
                 weekDays  => $conf->{BlackoutWeekDays},
             }
        );
        delete($conf->{BlackoutHourBegin});
        delete($conf->{BlackoutHourEnd});
        delete($conf->{BlackoutWeekDays});
    }

    return (undef, $conf);
}

sub ConfigDataWrite
{
    my($s, $volset, $newConf) = @_;

    my $configPath = $s->ConfigPath($volset);

    my($err, $contents) = $s->ConfigFileMerge("$configPath", $newConf);
    if ( defined($err) ) {
        return $err;
    } else {
        #
        # Write the file
        #
        return $s->TextFileWrite($configPath, $contents);
    }
}

sub ConfigFileMerge
{
    my($s, $inFile, $newConf) = @_;
    local(*C);
    my($contents, $skipExpr, $fakeVar);
    my $done = {};

    if ( -f $inFile ) {
        #
        # Match existing settings in current config file
        #
        open(C, $inFile)
            || return ("ConfigFileMerge: can't open/read $inFile", undef);
        binmode(C);

        while ( <C> ) {
            if ( /^\s*\$Conf\{([^}]*)\}\s*=(.*)/ ) {
                my $var = $1;
                $skipExpr = "\$fakeVar = $2\n";
                if ( exists($newConf->{$var}) ) {
                    my $d = Data::Dumper->new([$newConf->{$var}], [*value]);
                    $d->Indent(1);
                    $d->Terse(1);
                    my $value = $d->Dump;
                    $value =~ s/(.*)\n/$1;\n/s;
                    $contents .= "\$Conf{$var} = " . $value;
                    $done->{$var} = 1;
                }
            } elsif ( defined($skipExpr) ) {
                $skipExpr .= $_;
            } else {
                $contents .= $_;
            }
            if ( defined($skipExpr)
                    && ($skipExpr =~ /^\$fakeVar = *<</
                        || $skipExpr =~ /;[\n\r]*$/) ) {
                #
                # if we have a complete expression, then we are done
                # skipping text from the original config file.
                #
                $skipExpr = $1 if ( $skipExpr =~ /(.*)/s );
                eval($skipExpr);
                $skipExpr = undef if ( $@ eq "" );
            }
        }
        close(C);
    }

    #
    # Add new entries not matched in current config file
    #
    foreach my $var ( sort(keys(%$newConf)) ) {
	next if ( $done->{$var} );
	my $d = Data::Dumper->new([$newConf->{$var}], [*value]);
	$d->Indent(1);
	$d->Terse(1);
	my $value = $d->Dump;
	$value =~ s/(.*)\n/$1;\n/s;
	$contents .= "\$Conf{$var} = " . $value;
	$done->{$var} = 1;
    }
    return (undef, $contents);
}

#
# Return the mtime of the config file
#
sub ConfigMTime
{
    my($s) = @_;
    return (stat($s->ConfigPath()))[9];
}

#
# Returns information from the volset file in $s->{ConfDir}/volsets.
# With no argument a ref to a hash of volsets is returned.  Each
# hash contains fields as specified in the volsets file.  With an
# argument a ref to a single hash is returned with information
# for just that volset.
#
sub VolSetInfoRead
{
    my($s, $volset) = @_;
    my(%volsets, @hdr, @fld);
    local(*VOLUMESET_INFO, *LOCK);

    flock(LOCK, LOCK_EX) if open(LOCK, "$s->{ConfDir}/LOCK");
    if ( !open(VOLUMESET_INFO, "$s->{ConfDir}/VolumeSet-List") ) {
        print(STDERR "Can't open $s->{ConfDir}/VolumeSet-List\n");
        close(LOCK);
        return {};
    }

    binmode(VOLUMESET_INFO);
    while ( <VOLUMESET_INFO> ) {
        s/[\n\r]+//;
        s/#.*//;
        s/\s+$//;
        next if ( /^\s*$/ || !/^([\w\.\\-]+:.*)/ );
        #
	# Split on colon (:), except if preceded by \
        # using zero-width negative look-behind assertion
	# (always wanted to use one of those).
        #
        @fld = split(/(?<!\\):/, $1);
        #
        # Remove any \
        #
        foreach ( @fld ) {
            s{\\(\s)}{$1}g;
        }
        if ( @hdr ) {
            if ( defined($volset) ) {
                next if ( lc($fld[0]) ne lc($volset) );
                @{$volsets{lc($fld[0])}}{@hdr} = @fld;
		close(VOLUMESET_INFO);
                close(LOCK);
                return \%volsets;
            } else {
                @{$volsets{lc($fld[0])}}{@hdr} = @fld;
            }
        } else {
            @hdr = @fld;
        }
    }
    close(VOLUMESET_INFO);
    close(LOCK);
    return \%volsets;
}

#
# Writes new volsets information to the volsets file in $s->{ConfDir}/volsets.
# With no argument a ref to a hash of volsets is returned.  Each
# hash contains fields as specified in the volsets file.  With an
# argument a ref to a single hash is returned with information
# for just that volset.
#
sub VolSetInfoWrite
{
    my($s, $volsets) = @_;
    my($gotHdr, @fld, $volsetText, $contents);
    local(*VOLUMESET_INFO);

    if ( !open(VOLUMESET_INFO, "$s->{ConfDir}/VolumeSet-List") ) {
        return "Can't open $s->{ConfDir}/VolumeSet-List";
    }
    foreach my $volset ( keys(%$volsets) ) {
        my $name = "$volsets->{$volset}{volset}";
        my $rest = ":$volsets->{$volset}{user}"
                 . ":$volsets->{$volset}{moreUsers}"
                 . ":$volsets->{$volset}{Entry1_Servers}"
                 . ":$volsets->{$volset}{Entry1_Partitions}"
                 . ":$volsets->{$volset}{Entry1_Volumes}"
                 . ":$volsets->{$volset}{Entry2_Servers}"
                 . ":$volsets->{$volset}{Entry2_Partitions}"
                 . ":$volsets->{$volset}{Entry2_Volumes}"
                 . ":$volsets->{$volset}{Entry3_Servers}"
                 . ":$volsets->{$volset}{Entry3_Partitions}"
                 . ":$volsets->{$volset}{Entry3_Volumes}"
                 . ":$volsets->{$volset}{Entry4_Servers}"
                 . ":$volsets->{$volset}{Entry4_Partitions}"
                 . ":$volsets->{$volset}{Entry4_Volumes}"
                 . ":$volsets->{$volset}{Entry5_Servers}"
                 . ":$volsets->{$volset}{Entry5_Partitions}"
                 . ":$volsets->{$volset}{Entry5_Volumes}";
        $name =~ s/ /\\ /g;
        $rest =~ s/ //g;
        $volsetText->{$volset} = $name . $rest;
    }
    binmode(VOLUMESET_INFO);
    while ( <VOLUMESET_INFO> ) {
        s/[\n\r]+//;
        if ( /^\s*$/ || /^\s*#/ ) {
            $contents .= $_ . "\n";
            next;
        }
        if ( !$gotHdr ) {
            $contents .= $_ . "\n";
            $gotHdr = 1;
            next;
        }
        @fld = split(/(?<!\\)\s+/, $1);
        #
        # Remove any \
        #
        foreach ( @fld ) {
            s{\\(\s)}{$1}g;
        }
        if ( defined($volsetText->{$fld[0]}) ) {
            $contents .= $volsetText->{$fld[0]} . "\n";
            delete($volsetText->{$fld[0]});
        }
    }
    foreach my $volset ( sort(keys(%$volsetText)) ) {
        $contents .= $volsetText->{$volset} . "\n";
        delete($volsetText->{$volset});
    }
    close(VOLUMESET_INFO);

    #
    # Write and verify the new volset file
    #
    return $s->TextFileWrite("$s->{ConfDir}/VolumeSet-List", $contents);
}

#
# Return the mtime of the volsets file
#
sub VolSetsMTime
{
    my($s) = @_;
    return (stat("$s->{ConfDir}/VolumeSet-List"))[9];
}

1;
