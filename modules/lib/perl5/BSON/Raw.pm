use 5.010001;
use strict;
use warnings;

package BSON::Raw;
# ABSTRACT: BSON type wrapper for pre-encoded BSON documents

use version;
our $VERSION = 'v1.4.0';

use Moo;

#pod =attr bson
#pod
#pod A string containing a BSON-encoded document.  Default is C<undef>.
#pod
#pod =attr metadata
#pod
#pod A hash reference containing arbitrary metadata about the BSON document.
#pod Default is C<undef>.
#pod
#pod =cut

has [qw/bson metadata/] => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Raw - BSON type wrapper for pre-encoded BSON documents

=head1 VERSION

version v1.4.0

=head1 SYNOPSIS

    use BSON::Types ':all';

    my $ordered = bson_raw( $bson_bytes );

=head1 DESCRIPTION

This module provides a BSON document wrapper for already-encoded BSON bytes.

Generally, end-users should have no need for this; it is provided for
optimization purposes for L<MongoDB> or other client libraries.

=head1 ATTRIBUTES

=head2 bson

A string containing a BSON-encoded document.  Default is C<undef>.

=head2 metadata

A hash reference containing arbitrary metadata about the BSON document.
Default is C<undef>.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
