use Test::More tests => 5;
BEGIN {  @ARGV = ("-x", "--foo") };
use Getopt::Auto;
# Can't use_ok, because of CHECK
ok(1,"Getopt::Auto was loaded");
our %options;

my @exspec = ( [ '--foo', 'do a foo', 'Test

', \&foo]);

my %ex_options = ("--foo" => {
          'longhelp' => 'Test

',
          'code' => \&foo,
          'help' => 'do a foo'
        }
);
is_deeply(\@Getopt::Auto::spec, \@exspec, "Spec was built correctly");
is_deeply(\%Getopt::Auto::options, \%ex_options, "... and was converted to options OK");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

=head2 foo - do a foo

Test

=cut

sub foo {
    ok(1,"Foo got called");
    is($options{"x"}, 1, "option was set");
}
