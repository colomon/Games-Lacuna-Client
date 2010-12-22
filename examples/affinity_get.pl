#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use List::Util            (qw(first));
use Games::Lacuna::Client ();
use DateTime;
use Try::Tiny;
use YAML::Any             (qw(Dump));
my $star;
my $orbit;
my $eta;

my $cfg_file = shift(@ARGV) || 'lacuna.yml';
unless ( $cfg_file and -e $cfg_file ) {
    die "Did not provide a config file";
}

#my $affinity = shift(@ARGV) || 'affinity.yml';
#unless ( $affinity and -e $affinity ) {
#    die "Did not provide an affinity file";
#}

my $client = Games::Lacuna::Client->new(
	cfg_file => $cfg_file,
	 #debug    => 1,
);

my $species  = $client->empire->view_species_stats()->{species};
open my $out, '>', 'species.yml';
print $out Dump($species), "\n";
print Dump($species), "\n";
1;
__END__

my $species = $empire->view_species_stat
my $planets = $empire->{planets};
my %target;
my %bol;      #Bill of Lading

my $star_result = $client->map->get_star_by_name($star)->{star};

# find planet in $orbit around $star
my ($target_body) = grep {$_->{orbit} == $orbit} @{$star_result->{bodies}};
die "Planet not found in orbit $orbit of star '$star'"
    if !$target_body;

$target{id}   = $target_body->{id};
$target{name} = "$target_body->{name} [$star]";
$target{type} = 'body_id';
$target{x}    = $target_body->{x};
$target{y}    = $target_body->{y};

for my $from_id (sort { $planets->{$a} cmp $planets->{$b} } keys %$planets) {
    my %poo; # point of origin

    # find planet, buildings on that planet, and finally its spaceport
    my $body   = $client->body( id => $from_id );
    my $result = $body->get_buildings;
    @poo{qw(name id x y w1 w2)} = (@{$result->{status}{body}}{qw(name id x y)}); #,{}{});
    my $planet_id = $poo{id};
    $poo{d} = sqrt(abs($target{x}-$poo{x})**2 + abs($target{y}-$poo{y})); # distance to target from point of origin

#    say "From " . $planets->{$from_id} . sprintf(" (distance: %.3f):",$poo{d});

    my $buildings    = $result->{buildings};
    my $space_port_id = first {
            $buildings->{$_}->{name} eq 'Space Port'
    } keys %$buildings;
    my $space_port = $client->building( id => $space_port_id, type => 'SpacePort' );
    
    # get the ships we can send from that spaceport to our target
    my $ships = $space_port->get_ships_for( $from_id, { body_id => $target{id} } );
    my $available = $ships->{available};

    # Scanners go into Wave 1, everything else into Wave 2
    for my $ship (sort { $a->{name} cmp $b->{name} } @$available) {
	my ($ship_id, $name, $type, $speed) = @{$ship}{qw(id name type speed)};

	my $secs = ($poo{d} / ($speed/100)) * 60 * 60; # duration in seconds
	$secs -= 60  if $ship->{type} ne 'scanner'; # arrival 60 seconds after initial eta
	
	my @order = (@poo{qw(id name)}, $ship_id, $name, $type, $speed);
        my $d = DateTime::Duration->new(seconds => $secs);
	my $launch = $t1->clone->subtract($d)->strftime('%F %T');
	my $launch_local = $t1->clone->subtract($d)->set_time_zone($LocalTZ)->strftime('%F %T');

	$launch = "$launch ($launch_local $LocalTZ)";
	if ($secs < $tminus) { # if ship can arrive by eta add to a wave of attack
	    $bol{$launch} ||= [];
	    push @{$bol{$launch}}, [($ship->{type} eq 'scanner' ? '1' : '2'), @order];
	}
    }
}

print "Launch Plan $target{name}:\n";
for my $launch (sort keys %bol) {
    print "\t$launch\n";
    for my $order (@{$bol{$launch}}) {
	my ($wave, $planet_id, $planet_name, $ship_id, $ship_name, $ship_type, $ship_speed) = @$order;
	print "\t\t$planet_name, $ship_name, $ship_type, $ship_speed, wave $wave\n";
    }
}



sub usage {
  die <<"END_USAGE";
Usage: $0 attack_schedule.yml
       --star       NAME   (required)
       --orbit      NUMBER (required)
       --eta        TIME   (required)

Lays out the attack times to the target planet.

The eta is the time at which the 1st wave should arrive.
eta must be provided in the following format: yyyy:MM:dd:HH:mm::ss

END_USAGE

}



