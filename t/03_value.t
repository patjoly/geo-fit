# t/01_main.t - main testing file (for FIT.pm)
use strict;
use warnings;

use Test::More tests => 60;
use Geo::FIT;

my $o = Geo::FIT->new();
isa_ok($o, 'Geo::FIT');

$o->file( 't/10004793344_ACTIVITY.fit' );

# a few defaults: may change some of these later but picking the same value as in fit2tcx.pl
$o->use_gmtime(1);              # already the default
$o->semicircles_to_degree(1);   # already the default
$o->numeric_date_time(0);
$o->without_unit(1);
$o->mps_to_kph(0);

my @must = ('Time');

# callbacks needed for this test file

my $cb_file_id = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # test field_list() -- we know the 'file_id' data message occurs just once, so proper place here to test field_list() once
    my @field_list = $obj->field_list( $desc );
    my @field_list_exp = qw( serial_number time_created unknown7 manufacturer product number type );
    is_deeply( \@field_list, \@field_list_exp,  "   test field_list()");

    # test switched() and named_type_value() -- field_value() also calls both of these as required, so also tested indirectly
    my ($type_name, $attr, $inval, $id) = (@{$desc}{ qw(t_product a_product I_product) }, $values->[ $desc->{i_product} ]);
    my $t_attr = $obj->switched($desc, $values, $attr->{switch});
    if (ref $t_attr eq 'HASH') {
        $attr      = $t_attr;
        $type_name = $attr->{type_name}
    }
    is( $type_name, 'garmin_product',           "   test switched() -- product in file_id");
    my  $product_ntv_sw = $obj->named_type_value($type_name, $values->[$desc->{i_product}]);
    is( $product_ntv_sw,  'edge_830',           "   test switched() and named_type_value(): product in file_id");

    # compare field_value() and named_type_value() -- should be the same as the former calls the latter
    #  - test that type is 'activity' (4) -- type here for this data message refers to the type of the FIT file
    my  $file_type             = $obj->field_value( 'type', $desc, $values );
    my  $file_type_ntv         = $obj->named_type_value($desc->{t_type}, $values->[$desc->{i_type}]);
    is( $file_type,              'activity',    "   test field_value() -- type in file_id");
    is( $file_type,              $file_type_ntv,"   test field_value() and named_type_value(): should be identical");
    my  $file_type_as_read     = $obj->field_value_as_read( 'type', $desc, $file_type );
    is( $file_type_as_read,      4,             "   test field_value_as_read(): activity in file_id");

    my  $manufacturer          = $obj->field_value( 'manufacturer', $desc, $values );
    is( $manufacturer,           'garmin',      "   test field_value(): manufacturer in file_id");
    my  $manufacturer_as_read  = $obj->field_value_as_read( 'manufacturer', $desc, $manufacturer );
    is( $manufacturer_as_read,   1,             "   test field_value_as_read(): manufacturer in file_id");

    my  $product               = $obj->field_value( 'product', $desc, $values );
    is( $product,                'edge_830',    "   test field_value(): product in file_id");
    my  $product_as_read       = $obj->field_value_as_read( 'product', $desc, $product, $values );
    is( $product_as_read,        3122,          "   test field_value_as_read() with an additional arg: product in file_id");

    my  $time_created          = $obj->field_value( 'time_created', $desc, $values );
    is( $time_created,           '2022-11-19T22:10:20Z', "   test field_value(): time_created in file_id");
    my  $time_created_as_read  = $obj->field_value_as_read( 'time_created', $desc, $time_created );
    is( $time_created_as_read,   1037830220,    "   test field_value_as_read(): time_created in file_id");

    #
    # field_value_as_read() with the type name instead of the values aref as last argument (expect the same result)
    $product_as_read = $obj->field_value_as_read( 'product', $desc, $product, $type_name );
    is( $product_as_read,        3122,          "   test field_value_as_read() with the type name as additional arg: product in file_id");

    # my $product_as_read = $obj->field_value_as_read( 'product', $desc, $product );
    # ... that one should croak
    1
    };

my $cb_file_creator = sub {
    my ($obj, $desc, $values, $memo) = @_;

    my  $software_version    = $obj->field_value( 'software_version', $desc, $values );
    is( $software_version,     950,             "   test field_value(): software_version in file_creator");
    1
    };

my $cb_event = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # we have: timestamp data event event_type event_group

    my  $event               = $obj->field_value( 'event', $desc, $values );
    is( $event,                'timer',         "   test field_value(): event in event");
    my  $event_as_read       = $obj->field_value_as_read( 'event', $desc, $event );
    is( $event_as_read,        0,               "   test field_value_as_read(): event in event");

    my  $event_type          = $obj->field_value( 'event_type', $desc, $values );
    is( $event_type,           'start',         "   test field_value(): event_type in event");
    my  $event_type_as_read  = $obj->field_value_as_read( 'event_type', $desc, $event_type );
    is( $event_type_as_read,   0,               "   test field_value_as_read(): event_type in event");

    my  $data                = $obj->field_value( 'data', $desc, $values );
    is( $data,                 'manual',        "   test field_value(): data in event");
    my  $data_as_read        = $obj->field_value_as_read( 'data', $desc, $data, $values );
    is( $data_as_read,         0,               "   test field_value_as_read() with additional arg: data in event");

    my  $event_group         = $obj->field_value( 'event_group', $desc, $values );
    is( $event_group,          0,               "   test field_value(): event_group in event");
    my  $event_group_as_read = $obj->field_value_as_read( 'event_group', $desc, $event_group );
    is( $event_group_as_read,  0,               "   test field_value_as_read(): event_group in event");

    1
    };

my $device_info_got = 0;
my $device_info_i   = 0;
my $cb_device_info = sub {
    my ($obj, $desc, $values, $memo) = @_;

    $device_info_got = 1 if ++$device_info_i == 4;

    my  $device_index         = $obj->field_value( 'device_index', $desc, $values );
    my  $device_index_as_read = $obj->field_value_as_read( 'device_index', $desc, $device_index );

    if ( $device_index_as_read == 0 ) {
        is( $device_index,          'creator',  "   test field_value(): device_index in device_info");

        my  $manufacturer         = $obj->field_value( 'manufacturer', $desc, $values );
        is( $manufacturer,          'garmin',   "   test field_value(): manufacturer in device_info");
        my  $manufacturer_as_read = $obj->field_value_as_read( 'manufacturer', $desc, $manufacturer );
        is( $manufacturer_as_read,  1,          "   test field_value_as_read(): manufacturer in device_info");

        my  $product              = $obj->field_value( 'product', $desc, $values );
        is( $product,               'edge_830', "   test field_value(): product in device_info");
        my  $product_as_read      = $obj->field_value_as_read( 'product', $desc, $product, $values );
        is( $product_as_read,       3122,       "   test field_value_as_read() with an additional arg: product in device_info");

        my  $software_version = $obj->field_value( 'software_version', $desc, $values );
        is( $software_version,     '9.50',      "   test field_value(): software_version in device_info");

        my  $source_type          = $obj->field_value( 'source_type', $desc, $values );
        is( $source_type,           'local',    "   test field_value(): source_type in device_info");
        my  $source_type_as_read  = $obj->field_value_as_read( 'source_type', $desc, $source_type );
        is( $source_type_as_read,   5,          "   test field_value_as_read(): source_type in device_info");
    }

    if ( $device_index_as_read == 1 ) {
        is( $device_index,          'device1',  "   test field_value(): device_index in device_info");

        my  $device_type          = $obj->field_value( 'device_type', $desc, $values );
        is( $device_type,           'barometer', "   test field_value(): device_type in device_info");
        my  $device_type_as_read  = $obj->field_value_as_read( 'device_type', $desc, $device_type, $values );
        is( $device_type_as_read,   4,          "   test field_value_as_read() with additional arg: device_type in device_info");
    }

    if ( $device_index_as_read == 2 ) {
        is( $device_index,          'device2',  "   test field_value(): device_index in device_info");

        my  $device_type          = $obj->field_value( 'device_type', $desc, $values );
        is( $device_type,           'gps',      "   test field_value(): device_type in device_info");
        my  $device_type_as_read  = $obj->field_value_as_read( 'device_type', $desc, $device_type, $values );
        is( $device_type_as_read,   0,          "   test field_value_as_read() with additional arg: device_type in device_info");

        my  $product              = $obj->field_value( 'product', $desc, $values );
        is( $product,               3107, "   test field_value(): product in device_info");
        # ... don't seem to have a name for this one
        my  $product_as_read      = $obj->field_value_as_read( 'product', $desc, $product, $values );
        is( $product_as_read,       3107,       "   test field_value_as_read() with an additional arg: product in device_info");

        my  $software_version = $obj->field_value( 'software_version', $desc, $values );
        is( $software_version,    '4.80',       "   test field_value(): software_version in device_info");
        my  $software_version_as_read  = $obj->field_value_as_read( 'software_version', $desc, $software_version );
        is( $software_version_as_read,   480,   "   test field_value_as_read(): software_version in device_info");

    }

    if ( $device_index_as_read == 3 ) {
        is( $device_index,          'heart_rate',  "   test field_value(): device_index in device_info");

        my  $device_type          = $obj->field_value( 'device_type', $desc, $values );
        is( $device_type,           7,      "   test field_value(): device_type in device_info");
        my  $device_type_as_read  = $obj->field_value_as_read( 'device_type', $desc, $device_type, $values );
        is( $device_type_as_read,   7,          "   test field_value_as_read() with additional arg: device_type in device_info");
    }
    1
    };

my $cb_device_settings = sub {
    my ($obj, $desc, $values, $memo) = @_;

    # we have: active_time_zone, time_mode, time_zone_offset, backlight_mode (3), date_mode (1), lactate_threshold_autodetect_enabled (1),

    my  $utc_offset          = $obj->field_value( 'utc_offset', $desc, $values );
    is( $utc_offset,           0,               "   test field_value(): utc_offset in device_settings");
    my  $utc_offset_as_read  = $obj->field_value_as_read( 'utc_offset', $desc, $utc_offset );
    is( $utc_offset_as_read,   0,               "   test field_value_as_read(): utc_offset in device_settings");

    my  $time_offset          = $obj->field_value( 'time_offset', $desc, $values );
    is( $time_offset,           71582488,       "   test field_value(): time_offset in device_settings");
    my  $time_offset_as_read  = $obj->field_value_as_read( 'time_offset', $desc, $time_offset );
    is( $time_offset_as_read,   71582488,       "   test field_value_as_read(): utc_offset in device_settings");

    my  $active_time_zone          = $obj->field_value( 'active_time_zone', $desc, $values );
    is( $active_time_zone,           0,         "   test field_value(): active_time_zone in device_settings");
    my  $active_time_zone_as_read  = $obj->field_value_as_read( 'active_time_zone', $desc, $active_time_zone );
    is( $active_time_zone_as_read,   0,         "   test field_value_as_read(): active_time_zone in device_settings");

    my  $time_mode          = $obj->field_value( 'time_mode', $desc, $values );
    is( $time_mode,           'hour12',         "   test field_value(): time_mode in device_settings");
    my  $time_mode_as_read  = $obj->field_value_as_read( 'time_mode', $desc, $time_mode );
    is( $time_mode_as_read,   0,                "   test field_value_as_read(): time_mode in device_settings");

    my  $time_zone_offset          = $obj->field_value( 'time_zone_offset', $desc, $values );
    is( $time_zone_offset,           '0.0',     "   test field_value(): time_zone_offset in device_settings");
    # when scale > 0, the value gets sprintf with decimal points (is that the propoer value here? Try with other more meaningful fields when scale>0)
    my  $time_zone_offset_as_read  = $obj->field_value_as_read( 'time_zone_offset', $desc, $time_zone_offset );
    is( $time_zone_offset_as_read,   0,         "   test field_value_as_read(): time_zone_offset in device_settings");

    my  $backlight_mode          = $obj->field_value( 'backlight_mode', $desc, $values );
    is( $backlight_mode,           'auto_brightness',       "   test field_value(): backlight_mode in device_settings");
    my  $backlight_mode_as_read  = $obj->field_value_as_read( 'backlight_mode', $desc, $backlight_mode );
    is( $backlight_mode_as_read,   3,           "   test field_value_as_read(): backlight_mode in device_settings");

    my  $date_mode          = $obj->field_value( 'date_mode', $desc, $values );
    is( $date_mode,           'month_day',      "   test field_value(): date_mode in device_settings");
    my  $date_mode_as_read  = $obj->field_value_as_read( 'date_mode', $desc, $date_mode );
    is( $date_mode_as_read,   1,                "   test field_value_as_read(): date_mode in device_settings");

    my  $lactate_threshold_autodetect_enabled          = $obj->field_value( 'lactate_threshold_autodetect_enabled', $desc, $values );
    is( $lactate_threshold_autodetect_enabled,           1,         "   test field_value(): lactate_threshold_autodetect_enabled in device_settings");
    my  $lactate_threshold_autodetect_enabled_as_read  = $obj->field_value_as_read( 'lactate_threshold_autodetect_enabled', $desc, $lactate_threshold_autodetect_enabled );
    is( $lactate_threshold_autodetect_enabled_as_read,   1,         "   test field_value_as_read(): lactate_threshold_autodetect_enabled in device_settings");

    # my  $data                = $obj->field_value( 'data', $desc, $values );
    #is( $data,                 'manual',        "   test field_value(): data in device_settings");
    #my  $data_as_read        = $obj->field_value_as_read( 'data', $desc, $data, $values );
    #is( $data_as_read,         0,               "   test field_value_as_read() with additional arg: data in device_settings");

    1
    };

my $memo = { 'tpv' => [], 'trackv' => [], 'lapv' => [], 'av' => [] };

$o->data_message_callback_by_name('file_id',            $cb_file_id,            $memo) or die $o->error;
$o->data_message_callback_by_name('file_creator',       $cb_file_creator,       $memo) or die $o->error;
$o->data_message_callback_by_name('event',              $cb_event,              $memo) or die $o->error;
$o->data_message_callback_by_name('device_info',        $cb_device_info,        $memo) or die $o->error;
$o->data_message_callback_by_name('device_settings',    $cb_device_settings,    $memo) or die $o->error;
# TODO: need callbacks and tests for: user_profile, sport, zones_target
# my @f = $obj->field_list( $desc );

#
# A - test field_value(), named_type_value() and switch() with the above callbacks

my (@header_things, $ret_val);

$o->open or die $o->error;
@header_things = $o->fetch_header;

$ret_val = undef;

my $temp_max_i = 100;                   # temporary number of iterations (ensure we don't end up in endless loop if anything goes wrong)
my $i;
while ( my $ret = $o->fetch ) {
    # we are testing with callbacks, so not much to do here
    # as we add more tests, set the last to be when we have the latest one to test, i.e. will probably zones_target
    # last if $device_info_got;
    last if ++$i == $temp_max_i;
}
$o->close();

print "so debugger doesn't exit\n";

