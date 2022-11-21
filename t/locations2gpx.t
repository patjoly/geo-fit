# t/locations2gpx.t - script to convert locations.fit file
use Test::More tests => 1;

use strict;
use warnings;
use Geo::FIT;
use IPC::System::Simple qw(system);

my $output_file = 't/Locations.gpx';
unlink $output_file if -f $output_file;

my @ARGS = qw( --force --indent=4 t/Locations.fit );
system($^X, 'script/locations2gpx.pl', @ARGS);

is(-f $output_file, 1, "    locations2gpx.pl: results in new gpx file");
unlink $output_file;

print "so debugger doesn't exit\n";
