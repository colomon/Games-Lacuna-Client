#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use List::Util            (qw(first));
use Games::Lacuna::Client ();
use Getopt::Long          (qw(GetOptions));

my $star;
my $planet;

GetOptions(
    'star=s'   => \$star,
    'planet=s' => \$planet,
);

usage() if !$star || !$planet;

my $cfg_file = shift(@ARGV) || 'lacuna.yml';
unless ( $cfg_file and -e $cfg_file ) {
    die "Did not provide a config file";
}

my $client = Games::Lacuna::Client->new(
	cfg_file => $cfg_file,
	 #debug    => 1,
);

my $empire  = $client->empire->get_status->{empire};
my $planets = $empire->{planets};
my $target_id;
my $target_name;
my $target_type;

my $star_result = $client->map->get_star_by_name($star)->{star};

# send to planet on star
my $target_bodies = $star_result->{bodies};

my ($target_body) = first { $_->{name} eq $planet } @$target_bodies;

die "Planet '$planet' not found at star '$star'"
    if !$target_body;

$target_id   = $target_body->{id};
$target_name = "$planet [$star]";
$target_type = "body_id";

for my $from_id (sort { $planets->{$a} cmp $planets->{$b} } keys %$planets) {
    say "From " . $planets->{$from_id} . ":";

    # find planet, buildings on that planet, and finally its spaceport
    my $body         = $client->body( id => $from_id );
    my $result       = $body->get_buildings;
    my $buildings    = $result->{buildings};
    my $space_port_id = first {
            $buildings->{$_}->{name} eq 'Space Port'
    } keys %$buildings;
    my $space_port = $client->building( id => $space_port_id, type => 'SpacePort' );
    
    # get the ships we can send from that spaceport to our target
    my $ships = $space_port->get_ships_for( $from_id, { body_id => $target_id } );
    my $available = $ships->{available};

    for my $ship (sort { $a->{name} cmp $b->{name} } @$available) {
        say "  " . $ship->{name};
        my $speed = $ship->{speed};
        
    }
}



sub usage {
  die <<"END_USAGE";
Usage: $0 attack_schedule.yml
       --star       NAME (required)
       --planet     NAME (required)

Lays out the attack times to the target planet.

END_USAGE

}



