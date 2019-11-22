package PRTG;
use strict;
use LWP::UserAgent;
use JSON;
use URI;
use HTTP::Request::Common qw{ POST };
use IO::Socket::SSL;
use Data::Dumper qw( Dumper );
my $args = \@ARGV;

##change these to fit your prtg server/account
my $cfg = {
    'PRTG_URL' => 'http://localhost',
    'USER'     => 'user',
    'PASSHASH'   => 'updatepasshash',
};


my $prtg_pfx = $cfg->{'PRTG_URL'};

##helper function to add credentials to api calls
sub _add_creds{
    my $uri = shift;
    return $uri . qq{&username=$cfg->{'USER'}&passhash=$cfg->{'PASSHASH'}};
}


##function to get hashpass from prtg
sub _auth{
    my $uname = shift;
    my $pass = shift;
    my $rew = qq{/api/getpasshash.htm?username=$uname&password=$pass};
    pl($rew);
    my $reply = call($rew);
    pl($reply->{'_content'});
}

##setting object properties for devices and sensors
##There are many hidden properties for sensors and devices. To see the example call
##make a change in the prtg web interface then view the webserver log file. Use the names to fill this out
sub _set_value{
	my $id = shift;
	my $var = shift;
	my $val = shift;
	my $uri = qq{/api/setobjectproperty.htm?id=$id&name=$var&value=$val};
	call(_add_creds($uri));
}

##unpausing device,group, or sensor 
sub resume{
    my $id = shift;
    call(_add_creds(qq{/api/pause.htm?id=$id&action=1}));
}

##Delete object
sub _del_obj{
    my $id = shift;
    my $uri = qq{/api/deleteobject.htm?id=$id&approve=1};
    
    call(_add_creds($uri));
}

##CLI function delete object
sub del_obj{
    if(scalar(@$args) == 1){
        my $id = shift(@$args);
        _del_obj($id);
    }
    else{
        pl("prtg del_obj called with 1 argument");
        pl("./prtg del_obj objid");
    }
}

##CLI function clone device
sub clone_device{
    if(scalar(@$args) == 4){
        my $id = shift(@$args);
        my $name = shift(@$args);
        my $host = shift(@$args);
        my $did = shift(@$args);
        
        _clone_device($id,$name,$host,$did);
    }
    else{
        pl("prtg clone_group called with 4 arguments");
        pl("./prtg clone_device start_id new_name ip/hostname target_group_id");
    }
    return 0;
}

##clone device and unpause device
##will carry over sensors
sub _clone_device{
    my $sid = shift;
    my $name = shift;
    my $host = shift;
    my $gid  = shift;
    
    my $uri = qq{/api/duplicateobject.htm?id=$sid&name=$name&host=$host&targetid=$gid};
    $uri = _add_creds($uri);
    my $reply = call($uri);
    my $req = $reply->{'_request'};
    my $prev = $reply->{'_previous'};
    my $request = $prev->{'_request'};
    my $ruri = $request->{'_uri'};
    $ruri = Dumper $ruri;
    
    if($ruri =~ m/.*id=(\d*)/){
        my $new_id = $1;
        pl(qq{new_id=}.$new_id);
        resume($new_id);
        return $new_id;
    }
    
    return 0;
}

##clone sensor and unpause sensor
sub _clone_sensor{
    my $sid = shift;
    my $device_name = shift;
    my $did = shift;
    
    my $uri = qq{/api/duplicateobject.htm?id=$sid&name=$device_name&targetid=$did};
    $uri = _add_creds($uri);
    my $reply = call($uri);
    my $req = $reply->{'_request'};
    my $prev = $reply->{'_previous'};
    my $request = $prev->{'_request'};
    my $ruri = $request->{'_uri'};
    $ruri = Dumper $ruri;
    
    if($ruri =~ m/.*id=(\d*)/){
        my $new_id = $1;
        resume($new_id);
        return $new_id;
    }
    return 0;
}

##full clone of group
##will also clone devices and their sensors
sub _clone_group{
    my $gid = shift;
    my $name = shift;
    my $did = shift;
    
    my $uri = qq{/api/duplicateobject.htm?id=$gid&name=$name&targetid=$did};
    $uri = _add_creds($uri);
    my $reply = call($uri);
    my $req = $reply->{'_request'};
    my $prev = $reply->{'_previous'};
    my $request = $prev->{'_request'};
    my $ruri = $request->{'_uri'};
    $ruri = Dumper $ruri;
    
    if($ruri =~ m/.*id=(\d*)/){
        my $new_id = $1;
        resume($new_id);
        return $new_id;
    }
    return 0;
}

##CLI clone group
sub clone_group{
    if(scalar(@$args) == 3){
        my $id = shift(@$args);
        my $name = shift(@$args);
        my $did = shift(@$args);
        
        _clone_group($id,$name,$did);
    }
    else{
        pl("prtg clone_group called with 3 arguments");
        pl("./prtg clone_group start_id new_name target_id");
    }
    return 0;
}

##CLI clone sensor
sub clone_sensor{
    if(scalar(@$args) == 3){
        my $sid = shift(@$args);
        my $device_name = shift(@$args);
        my $did = shift(@$args);
        
        _clone_sensor($sid,$device_name,$did);
    }
    else{
        pl("prtg CLONE called with 3 arguments");
        pl("./prtg CLONE start_sensor_id new_name target_device_id");
    }
    return 0;
}

##CLI get device, limited contents
sub get_device{
    my $id = shift(@$args);
    my $uri = qq{/api/table.json?id=$id&content=devices&columns=objid,device,groupid};
    $uri = _add_creds($uri);
    my $reply = call($uri);
    print Dumper decode_json($reply->{'_content'});
}

##CLI get probe
sub get_probe{
    my $id = shift(@$args);
    my $uri = qq{/api/table.json?id=$id&content=probes&columns=objid,group};
    $uri = _add_creds($uri);
    my $reply = call($uri);
    print Dumper decode_json($reply->{'_content'});
}

##CLI get sensor details
sub get_sensor{
    my $sensor_id = shift;
    my $uri = qq{/api/getsensordetails.json?id=$sensor_id};
    $uri = _add_creds($uri);
    my $reply = call($uri);
    ##pl($reply->{'_content'});
	my $hash = decode_json($reply->{'_content'});
	return $hash->{'sensordata'};
}

##wrapper function to do remote call
sub call{
    my $ua = LWP::UserAgent->new();
    $ua->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    IO::Socket::SSL::set_ctx_defaults(
        {
            SSL_verifycn_scheme => 'www',
            SSL_verify_mode => 0,    
        }
    );
    my $request = shift;
    my $uri = $prtg_pfx . $request;
    return $ua->get($uri);
}

##CLI Clones target sensor to all devices in a group
sub clone_sensor_to_group{
    if(scalar(@$args) == 3){
        my $sid = shift(@$args);
        my $sname = shift(@$args);
        my $did = shift(@$args);
        
        my $devices = get_devices_in_group($did);
        
        foreach my $row (@$devices){
            my $id = $row->{'objid'};
            my $name = $row->{'device'};
            _clone_sensor($sid,$name.' - '.$sname, $id);
        }
    }
    else{
        pl("prtg clone_sensor_to_group called with 3 arguments");
        pl("./prtg clone_sensor_to_group start_sensor_id sensor_name group_name");
    }
    return 0;
}

##CLI delete all sensors of type from all devices in said group
sub delete_group_sensor{
    if(scalar(@$args) == 2){
        my $group = shift(@$args);
        my $type = shift(@$args);
        
        _delete_group_sensor($group,$type);
    }
    else{
        pl("prtg delete_group_sensor called with 2 arguments");
        pl("./prtg delete_group_sensor group_id type");
    }
    return 0;
}

##delete all sensors of type from all devices in said group
sub _delete_group_sensor {
    my $group = shift;
    my $type = shift;
    my $sensors = get_group_sensors_by_type($group,$type);
    foreach my $row(@$sensors){
        my $id = $row->{'objid'};
        pl(qq{deleting $id:$row->{'sensor'}});
        _del_obj($id);
    }
}

##get list of sensors of a given type belonging to a specific group
sub get_group_sensors_by_type{
    my $group = shift;
    my $type  = shift;
    
    my $uri = qq{/api/table.json?content=sensors&filter_group=$group&filter_type=$type&columns=objid,type,sensor};
    my $data = call(_add_creds($uri));
    my $decoded = decode_json($data->{'_content'});
    my $sensors = $decoded->{'sensors'};
    return $sensors;
}

##CLI bulk rename sensors of a given type
sub rename_sensors_by_type{
    if(scalar(@$args) == 2){
        my $type = shift(@$args);
        my $pfx = shift(@$args);
        
        _rename_sensors_by_type($type,$pfx);
    }
    else{
        pl("prtg rename_sensors_by_type called with 2 arguments");
        pl("./prtg rename_sensors_by_type type prefix");
    }
    return 0;
}

##CLI rename group, device, or sensor
sub rename_obj{
    if(scalar(@$args) == 2){
        my $id = shift(@$args);
        my $name= shift(@$args);
        
        _rename($id,$name);
    }
    else{
        pl("prtg rename called with 2 arguments");
        pl("./prtg rename id name");
    }
    return 0;
}

##bulk rename sensors of a given type
sub _rename_sensors_by_type {
    my $type = shift;
    my $pfx = shift;
    
    my $sensors = get_sensors_by_type($type);
    
    foreach my $row(@$sensors){
        my $id = $row->{'objid'};
        my $name = $row->{'device'};
        my $newname = $pfx.$name;
        pl(qq{obj: $id Parent:$name rename to $newname });
        _rename($id,$newname);
    }
}

##rename group, devicde, or sensor
sub _rename{
    my $id = shift;
    my $name = shift;
    
    my $uri = qq{/api/rename.htm?id=$id&value=$name};
    call(_add_creds($uri));
}

##get all sensors for a given type
sub get_sensors_by_type{
    my $type  = shift;
    
    my $uri = qq{/api/table.json?content=sensors&filter_type=$type&columns=objid,type,sensor,device};
    my $data = call(_add_creds($uri));
    my $decoded = decode_json($data->{'_content'});
    my $sensors = $decoded->{'sensors'};
    return $sensors;
}

##get all sensors for a given device
sub get_sensors_by_device{
    my $id  = shift;   
    my $uri = qq{/api/table.json?content=sensors&filter_parentid=$id&columns=objid,type,sensor,device,tags};
    my $data = call(_add_creds($uri));
    my $decoded = decode_json($data->{'_content'});
    my $sensors = $decoded->{'sensors'};
    return $sensors;
}

##get all devices in a group
sub get_devices_in_group{
    my $group_id = shift;
    my $uri = qq{/api/table.json?content=devices&output=json&filter_group=$group_id&columns=objid,device,host};
    my $data = call(_add_creds($uri));
	##pl(Dumper $data);
    my $decoded = decode_json($data->{'_content'});
    my $devices = $decoded->{'devices'};
    return $devices;
}

##modify scanning interval for sensor
sub update_interval{
	my $id = shift;
	my $int = shift;
	my $sensor = get_sensor($id);
	##pl(Dumper $sensor);
	if($sensor->{'interval'} == $int){
		return;
	}
	PRTG::pl(qq{updating sensor interval});
	set_inherit($id,0);
	_set_value($id,'interval',$int);
}

##set interval inherit property
sub set_inherit{
    my $id = shift;
    my $value = shift;
    
    return _set_value($id,'intervalgroup_',$value);
}

sub pl{
    print shift . "\n";
}