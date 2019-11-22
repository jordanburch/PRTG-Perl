use strict;
use PRTG;
use Data::Dumper qw( Dumper );
use Text::CSV qw( csv );

my $aoh = csv (in => "in.csv",headers => "auto");

##need to create clone device and add ID below
my $clone_id = 0000;

##need to create groups below and replace the group ids
my $groups = {
    ##location top group from csv. exact match
    "Location1" => {
	##group name -> group_id
	"Switch" => 0000,
	"Router" => 0000,
	"Server" => 0000,
    },
    "Location2" => {
	"Switch" => 0000,
	"Router" => 0000,
	"Server" => 0000,	
    },
};



foreach my $row (@$aoh){
	my $name = $row->{'DeviceName'};
	my $IP = $row->{'IPAddress'};
	my $group_name = $row->{'GroupName'};
	my $location = $row->{'LocationName'};	
	my $group_id = $groups->{$location}->{$group_name};

	PRTG::_clone_device($clone_id,$name,$IP,$group_id);
	PRTG::pl("Added device:$location -> $group_name -> $name");
}
1;