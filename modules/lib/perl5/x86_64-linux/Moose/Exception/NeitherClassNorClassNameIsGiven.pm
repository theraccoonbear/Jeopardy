package Moose::Exception::NeitherClassNorClassNameIsGiven;
our $VERSION = '2.2005';

use Moose;
extends 'Moose::Exception';

sub _build_message {
    "You need to give class or class_name or both";
}

1;
