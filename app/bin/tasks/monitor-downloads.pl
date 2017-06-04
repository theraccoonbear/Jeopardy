#!/usr/bin/env perl
use FindBin;

use lib "$FindBin::Bin/../../../modules/lib/perl5";
use lib "$FindBin::Bin/../../lib";

use strict;
use warnings;
use FindBin;
use Data::Printer;
# only one copy running
use Sys::RunAlone;
use AppData::Mongo;

# make 'em hot!
select((select(STDOUT), $|=1)[0]);
select((select(STDERR), $|=1)[0]);

my $mongo = new AppData::Mongo(collection_name => 'api');

my $downloads = [$mongo->getAll()->all];
p($downloads);







#########################
# for Sys::RunAlone
__END__