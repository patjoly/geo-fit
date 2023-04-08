# t/01_main.t - main testing file (for FIT.pm)
use strict;
use warnings;

use Test::More tests => 9;
use Geo::FIT;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

$o->file( 't/10004793344_ACTIVITY.fit' );

# a few defaults: may change some of these later but picking the same value as in fit2tcx.pl
$o->use_gmtime(1);
$o->numeric_date_time(0);
$o->semicircles_to_degree(1);
$o->without_unit(1);
$o->mps_to_kph(0);

my @must = ('Time');
my $include_creator = 1;

# i) register callbacks needed for this test file (copied from fit2tcx.pl)

my $cb_file_id = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test that file type is activity (4)
    my $file_type     = $obj->value_cooked(@{$desc}{qw(t_type a_type I_type)}, $values->[$desc->{i_type}]);
    my $file_type_alt = $obj->named_type_value($desc->{t_type}, $values->[$desc->{i_type}]);
    is( $file_type,     'activity',       "   test value_cooked() and named_type_value: should be identical for named types");
    is( $file_type,     $file_type_alt,   "   test value_cooked() -- file_id: field type");
    # ... should be the same value as value_cooked() calls named_type_value() if t_type is defined

    # test that the product is a garmin_product -- edge 830
    my ($tname, $attr, $inval, $id) = (@{$desc}{ qw(t_product a_product I_product) }, $values->[ $desc->{i_product} ]);
    my $t_attr = $obj->switched($desc, $values, $attr->{switch});
    if (ref $t_attr eq 'HASH') {
        $attr = $t_attr;
        $tname = $attr->{type_name}
    }
    is( $tname, 'garmin_product',       "   test switched() -- garmin_product");
    my $product = $obj->named_type_value($tname, $values->[$desc->{i_product}]);
    is( $product, 'edge_830',           "   test switched() followed by named_type_value() -- garmin_product");
    1
    };

my $cb_file_creator = sub {
    my ($obj, $desc, $values, $memo) = @_;

    my $software_version = $obj->value_cooked(@{$desc}{qw(t_software_version a_software_version I_software_version)}, $values->[$desc->{i_software_version}]);
    is( $software_version,      950,   "   test value_cooked() -- file_creator: field software_version");
    1
    };

my $got_device_info = 0;
my $cb_device_info = sub {
    my ($obj, $desc, $values, $memo) = @_;
    $got_device_info = 1;

    if ($include_creator &&
            $obj->value_cooked(@{$desc}{qw(t_device_index a_device_index I_device_index)}, $values->[$desc->{i_device_index}]) eq 'creator') {

        # test that the product is a garmin_product -- edge 830
        my ($tname, $attr, $inval, $id) = (@{$desc}{qw(t_product a_product I_product)}, $values->[$desc->{i_product}]);
        my $t_attr = $obj->switched($desc, $values, $attr->{switch});
        if (ref $t_attr eq 'HASH') {
            $attr = $t_attr;
            $tname = $attr->{type_name}
        }
        is( $tname, 'garmin_product',       "   test switched() -- garmin_product");
        my $product = $obj->named_type_value($tname, $values->[$desc->{i_product}]);
        is( $product, 'edge_830',           "   test switched() followed by named_type_value() -- garmin_product");

        my $software_version = $obj->value_cooked(@{$desc}{qw(t_software_version a_software_version I_software_version)}, $values->[$desc->{i_software_version}]);
        is( $software_version,    '9.50',   "   test value_cooked() -- device_info: field software_version");

    }
    1
    };

my $cb_event = sub {
    my ($obj, $desc, $values, $memo) = @_;
    my $event = $obj->named_type_value($desc->{t_event}, $values->[$desc->{i_event}]);
    my $event_type = $obj->named_type_value($desc->{t_event_type}, $values->[$desc->{i_event_type}]);

    # TODO: add tests for event messages
    #    if ($event_type eq 'stop_all') {
    #
    #    &track_end($memo)
    #}
    1
    };

my $memo = { 'tpv' => [], 'trackv' => [], 'lapv' => [], 'av' => [] };

$o->data_message_callback_by_name('file_id',      $cb_file_id,      $memo) or die $o->error;
$o->data_message_callback_by_name('file_creator', $cb_file_creator, $memo) or die $o->error;
$o->data_message_callback_by_name('device_info',  $cb_device_info,  $memo) or die $o->error;
# TODO: need callbacks and tests for: event, device_settings, user_profile, sport, zones_target

#
# A - test value_cooked(), named_type_value() and switch() with the above callbacks

my (@header_things, $ret_val);

$o->open or die $o->error;
@header_things = $o->fetch_header;

$ret_val = undef;

while ( my $ret = $o->fetch ) {
    # we are testing with callbacks, so not much to do here
    # as we add more tests, set the last to be when we have the latest one to test, i.e. will probably zones_target
    last if $got_device_info
}
$o->close();

print "so debugger doesn't exit\n";

