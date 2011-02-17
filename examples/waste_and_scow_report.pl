#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use List::Util            (qw(first));
use Games::Lacuna::Client ();
use Getopt::Long          (qw(GetOptions));

my $speed;
my $max;
my $from;
my $trades_per_page = 25;

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
my $target_name;
my $target_type;

my $star = "Iowiofroupl";
my $planet = "Icheis";

my $star_result = $client->map->get_star_by_name($star)->{star};
my $bodies = $star_result->{bodies};
my ($body) = first { $_->{name} eq $planet } @$bodies;
die "Planet '$planet' not found at star '$star'"
    if !$body;
my $target_id   = $body->{id};

# Where are we sending from?

for my $key (keys %$planets) {
    my $name = $planets->{$key};
    
    my $body         = $client->body( id => $key );
    my $waste_stored = $body->get_buildings->{"status"}->{"body"}->{"waste_stored"};
    my $waste_capacity = $body->get_buildings->{"status"}->{"body"}->{"waste_capacity"};
    
    my $result       = $body->get_buildings;
    my $buildings    = $result->{buildings};

    my $space_port_id = first {
            $buildings->{$_}->{name} eq 'Space Port'
    } keys %$buildings;

    my $space_port = $client->building( id => $space_port_id, type => 'SpacePort' );

    my $ships = $space_port->get_ships_for( $key, { body_id => $target_id }  );
    
    # for my $ship ( @{ $ships->{available} }) {
    #     say "available: " . $ship->{name};
    # }
    # for my $ship ( @{ $ships->{unavailable} } ) {
    #     say "unavailable: " . $ship->{ship}->{name};
    #     say "reason: " . $ship->{reason}->[1];
    # }

    my $available = $ships->{available};
    
    my $scow_capacity = 0;
    for my $ship ( @$available ) {
        next if $ship->{type} ne "scow";
        next if $ship->{name} eq "";
        $scow_capacity += $ship->{hold_size};
    }
    
    my $scow_capacity_needed = $waste_stored - $scow_capacity;
    print "$name: $waste_stored / $waste_capacity, $scow_capacity scow capacity present\n";
    print "       additional $scow_capacity_needed needed\n";
}


