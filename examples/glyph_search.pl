#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use List::Util            (qw(first));
use Games::Lacuna::Client ();
use Getopt::Long          (qw(GetOptions));
use Data::Dumper;

if ( $^O !~ /MSWin32/) {
    $Games::Lacuna::Client::PrettyPrint::ansi_color = 1;
}

my $planet_name;
my $opt_update_yml = 0;
GetOptions(
    'planet=s' => \$planet_name,
    'c|color!' => \$Games::Lacuna::Client::PrettyPrint::ansi_color,
    'u|update' => \$opt_update_yml,
);

my $cfg_file = shift(@ARGV) || 'lacuna.yml';
unless ( $cfg_file and -e $cfg_file ) {
	die "Did not provide a config file";
}

if( $opt_update_yml ){
    warn "This web-scraping function requires HTML::TableExtract and a helluva lot of luck.\n";
    eval { require HTML::TableExtract };
    die "Sorry, unable to load HTML::TableExtract, please install. Error: $@" if $@;
    warn "Replace the DATA block in this script with the following STDOUT content.\n";
    generate_yaml();
    warn "Complete.\n";
    exit;
}

my $client = Games::Lacuna::Client->new(
	cfg_file => $cfg_file,
	# debug    => 1,
);

my @ores_to_look_for = ("anthracite", "zircon", "gold", 
                        "magnetite", "halite", "goethite", 
                        "trona", "fluorite");

# Load the planets
my $empire  = $client->empire->get_status->{empire};

# reverse hash, to key by name instead of id
my %planets = map { $empire->{planets}{$_}, $_ } keys %{ $empire->{planets} };

# Scan each planet
my %all_glyphs;
foreach my $name ( sort keys %planets ) {

    next if defined $planet_name && $planet_name ne $name;

    # Load planet data
    my $planet    = $client->body( id => $planets{$name} );
    my $result    = $planet->get_buildings;
    my $body      = $result->{status}->{body};
    
    my $buildings = $result->{buildings};

    # Find the Archaeology Ministry
    my $arch_id = first {
            $buildings->{$_}->{name} eq 'Archaeology Ministry'
    } keys %$buildings;

    next if not $arch_id;
    
    my $arch   = $client->building( id => $arch_id, type => 'Archaeology' );
    if ($arch->view->{building}->{work}) {
        print "Ministry on $name is already working\n";
        next;
    }
    
    my $ores = $arch->get_ores_available_for_processing;
    my @available_ores = keys %{$ores->{ore}};
    if (scalar @available_ores) {
        my $ore_to_try = $ores_to_look_for[0] // $available_ores[0] // next;
        foreach my $desired_ore (@ores_to_look_for) {
            if ($ores->{ore}->{$desired_ore} && $ores->{ore}->{$desired_ore} > 10000) {
                $ore_to_try = $desired_ore;
                last;
            }
        }
        print "Looking for $ore_to_try on $name\n";
        $arch->search_for_glyph ($ore_to_try);
    }
}

