use strict;
use PRTG;
use Data::Dumper qw( Dumper );


my $sensors = PRTG::get_sensors_by_type('ping');

foreach my $row(@$sensors){
    my $id = $row->{'objid'};
    PRTG::update_interval($id,'60');
}

1;