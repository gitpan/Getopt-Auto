#! /usr/bin/perl

#  Copyright (C) 2010, Geoffrey Leach
#
#===============================================================================
#
#         FILE:  03-options_package.t
#
#  DESCRIPTION:  Test combination of 'long' ('--') run-time options
#                The only difference between this and 03.options_long.t
#                is the package statement, so we can prove that Getopt::Auto
#                is able to execute/access in packages other than main.
#
#       AUTHOR:  Geoffrey Leach (), <geoff@hughes.net>
#      VERSION:  1.9.7
#      CREATED:  Mon Aug 10 14:15:20 PDT 2009
#===============================================================================

package Test_in_package;

use strict;
use warnings;

use Test::More tests => 7;

use 5.006;
our $VERSION = '1.9.7';

## no critic (RequireLocalizedPunctuationVars)
## no critic (ProhibitPackageVars)

BEGIN {

   # This simulates our being called with various options on the command line.
   # It's here because Getopt::Auto needs to look at it
    @ARGV
        = qw(--foo --bar bararg1 bararg2 notanarg --tar=tararg2 --nosub -- --foobar);
    use Getopt::Auto;
}

our %options;

# Option has no args
my $is_foo_called;
sub foo { $is_foo_called = 1; return; }
ok( $is_foo_called, 'Calling foo()' );

# Option has two args
my $is_bar_called;

sub bar {
    $is_bar_called = ( shift @ARGV ) . ' and ' . shift @ARGV;
    return;
}
ok( defined $is_bar_called, "Calling bar() with $is_bar_called" );

# Option has one arg, tied with '='
my $is_tar_called;
sub tar { $is_tar_called = shift @ARGV; return; }
ok( defined $is_tar_called, "Calling tar() with $is_tar_called" );

# Option occurs after '--', so is not called
# Subroutine is required as otherwise its always ignored
my $is_foobar_called;
sub foobar { $is_foobar_called = 1; return; }
ok( !defined $is_foobar_called, 'Foobar was not called' );

# --nosub has no associated sub`, so ..
ok( $options{'--nosub'} == 1, 'Option "--nosub" processed correcly' );

# Check the leftover command line args, and their position
ok( $ARGV[0] eq 'notanarg',
    'Unused command line argument "notanarg" remains' );
ok( $ARGV[1] eq '--foobar',
    'Unused command line argument "--foobar" remains' );

exit 0;

__END__

=pod

=begin stopwords
Nosub
nosubs 
=end stopwords 

=head2 --foo - do a foo

This is the help for --foo

=head2 --bar - do a bar

This is the help for --bar

=head2 --tar - do a tar

This is the help for --tar

=head2 --foobar - do a foobar

This is the help for --foobar, which won't be executed
because of the '--' in the command line

=head2 --nosub -- bump a counter

Nosub has -- supprise -- no associated sub

=cut
