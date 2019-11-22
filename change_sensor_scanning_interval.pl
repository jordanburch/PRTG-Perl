#! /usr/bin/perl/perl

use lib('/home/jburch/prtg/prtg');
use strict;
use PRTG;
use Data::Dumper qw( Dumper );



my $config = {
    'ping' => 60,
    'wmidiskspace'    => 60*60*2,
    'wmiprocessor'    => 60*5,
    'wmimemory'       => 60*5,
    'wmihypervserver' => 60*5,
    'wmihyperv'       => 60*5,
};

foreach my $type (keys(%$config)){
    my $sensors = PRTG::get_sensors_by_type($type);
    my $interval = $config->{$type};
    foreach my $row(@$sensors){
	my $id = $row->{'objid'};
	PRTG::update_interval($id,$interval);
    }
    
}
1;