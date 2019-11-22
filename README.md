PRTG module holds library functions that access the prtg api to
perform normal tasks.

Modules required:
use LWP::UserAgent;
use JSON;
use URI;
use HTTP::Request::Common
use IO::Socket::SSL;
use Data::Dumper
use Text::CSV


import_csv script is a sample script to show how the prtg module is
called.

Headers:
DeviceName,IPAddress,GroupName,Location

IPAddress can be Fully qualified domain name

