#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use List::Util            (qw(first));
use Games::Lacuna::Client ();
use Try::Tiny;
use YAML::Any             (qw(Dump));

my $cfg_file = shift(@ARGV) || 'lacuna.yml';
unless ( $cfg_file and -e $cfg_file ) {
    die "Did not provide a config file";
}

my $affinity_file = shift(@ARGV) || 'affinity.yml';
unless ( $affinity_file and -e $affinity_file ) {
    die "Did not provide an affinity file";
}
my $species = YAML::Any::LoadFile($affinity_file);


my $client = Games::Lacuna::Client->new(
	cfg_file => $cfg_file,
	 #debug    => 1,
);

my %check = (%$species);
delete $check{name};
delete $check{description};
my $tally = delete($check{max_orbit}) - delete($check{min_orbit}) + 1;
$tally += delete $check{$_}  for keys %check;

for my $key (keys %$species) {
    print "$key: $species->{$key}\n";
}
print "total affinity points allocated: $tally\n";

if ($tally != 45) {
    print "redefine_species affinity points must total 45 points!\n";
    exit;
}

print "Changing your species affinities costs 100 essentia.\n";
print "Are you absolutely sure you have the essentia and want to do this? (y/n) ";
my $in = <STDIN>;
exit  unless $in =~ /^y/i;

try {
    $client->empire->redefine_species($species);
}
catch {
    warn "caught error attempting: \$client->empire->redefine_species(\$species)\n$!";
};




1;
__END__


