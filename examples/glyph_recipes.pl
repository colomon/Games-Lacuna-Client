#!perl
use strict;
use warnings;
use YAML::Any qw(Dump);
use 5.008;

my %ore = (
    ANT => 'anthracite',
    BAU => 'bauxite',
    BER => 'beryl',
    CHA => 'chalcopyrite',
    CHR => 'chromite',
    FLU => 'fluorite',
    GAL => 'galena',
    GOE => 'goethite',
    GOL => 'gold',
    GYP => 'gypsum',
    HAL => 'halite',
    KER => 'kerogen',
    MAG => 'magnetite',
    MET => 'methane',
    MON => 'monazite',
    RUT => 'rutile',
    SUL => 'sulfur',
    TRO => 'trona',
    URA => 'uraninite',
    ZIR => 'zircon',
);

my %recipe = (
    'Algae Pond'                    => [[@ore{qw(URA MET)}]],
    'Citadel of Knope'              => [[@ore{qw(BER SUL MON GAL)}]],
    'Crashed Ship Site'             => [[@ore{qw(MON TRO GOL BAU)}]],
    'Gas Giant Settlement Platform' => [[@ore{qw(SUL MET GAL ANT)}]],
    'Geo Thermal Vent'              => [[@ore{qw(CHA SUL)}]],
    'Halls of Vrbansk'              => [[@ore{qw(GOE HAL GYP TRO)}],
					[@ore{qw(GOL ANT URA BAU)}],
					[@ore{qw(KER MET SUL ZIR)}],
					[@ore{qw(MON FLU BER MAG)}],
					[@ore{qw(RUT CHR CHA GAL)}],
    ],
    'Interdimensional Rift'         => [[@ore{qw(MET ZIR FLU)}]],
    'Kalavian Ruins'                => [[@ore{qw(GAL GOL)}]],
    'Lapis Forest'                  => [[@ore{qw(HAL ANT)}]],
    'Malcud Field'                  => [[@ore{qw(FLU KER)}]],
    'Natural Spring'                => [[@ore{qw(MAG HAL)}]],
    'Pantheon of Hagness'           => [[@ore{qw(GYP TRO BER ANT)}]],
    'Ravine'                        => [[@ore{qw(ZIR MET GAL FLU)}]],
    'Temple of the Drajilites'      => [[@ore{qw(KER RUT CHR CHA)}]],
    'Terraforming Platform'         => [[@ore{qw(MET ZIR MAG BER)}]],
    'Volcano'                       => [[@ore{qw(MAG URA)}]],
);

my $filename = 'glyph_recipes.yml';
open my $out, '>', $filename or die $!;
print $out Dump(\%recipe);

1;
__END__
