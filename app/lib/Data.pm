package Data;
use strict;
use warnings;

our $VERSION = 0.1;

use Moose;
use Data::Printer;
use File::Slurp;
use JSON::XS;
use Cwd qw(abs_path);

sub listJSON {
	my $data_path = "$FindBin::Bin/../../data/";
	opendir DFH, $data_path;
	return [
		grep {
			/\.json$/xsm && -f ($data_path . $_)
		} readdir DFH
	];
}

sub loadJSON {
	my ($self, $file) = @_;
	if ($file =~ m/\.\./xsm) { return; }
	p($file);
	my $data_path = abs_path("$FindBin::Bin/../../data/$file");
	p($data_path);
	return decode_json(read_file($data_path));
}

1;
