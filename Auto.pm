package Getopt::Auto;

use 5.006;
use strict;
use warnings;
use Carp;
our $VERSION = '1.00';

our $do_it;
our @spec;

sub import {
    my $class = shift;

    # Process into usable format.
    @spec = @_;
}

our %options;
our $type;

CHECK {
    @spec = superauto()
      unless @spec;

    for (@spec) {
        croak "Option specification $_ should be an array reference"
          unless ref $_ eq "ARRAY";
        my @stuff = @$_;
        my $flag  = shift @stuff;
        if (defined $type) {
            croak
              "Option inconsistency: expected $type options, found '$flag'"
              unless _type($flag) eq $type;
          } else {
            $type = _type($flag);
            croak
"Option style unknown: found '$flag', neither long, short nor bare"
              if $type eq "unknown";
        }

        $options{$flag}{help} = shift @stuff;

        if (defined $stuff[0] and ref $stuff[0] eq "CODE") {
            $options{$flag}{code} = shift @stuff;
          } else {
            $options{$flag}{longhelp} = shift @stuff if defined $stuff[0];
            $options{$flag}{code}     = shift @stuff
              if defined $stuff[0] and ref $stuff[0] eq "CODE";
        }

        if (!exists $options{$flag}{code}) {
            my $sub = $flag;
            $sub =~ s/^-+//;
            $sub =~ s/-/_/g;
            no strict 'refs';
            $options{$flag}{code} = *{"main::$sub"}{CODE};
        }
    }
}

sub _type {
    my $option = shift;
    $option =~ /^--/ and return "long";
    $option =~ /^-/ and return "short";
    $option =~ /^\w/ and return "bare";
    return "unknown";
}

use FindBin;

sub superauto {
    my $pod  = new Getopt::Auto::PodExtract;
    my $self = -r $0 ? $0 : -r $FindBin::Bin . "/" . $0 ? -r $FindBin::Bin
      . "/" . $0 :
      croak "Couldn't automatically parse your POD - $0 not readable!";
    $pod->parse_from_file($self, '/dev/null');
    my @spec;

    while (my ($k, $v) = each %{ $pod->{funcs} }) {
        $k =~ s/_/-/g;
        push @spec,
          [ "--$k", $v->{shorthelp}, $v->{longhelp}, $v->{code} ];
    }
    return @spec;
}

sub version {
    print "This is $0, version $main::VERSION\n\n";
}

sub helpme {
    version();
    my $sig = "";
    if ($type eq "long")     { $sig = "--" }
    elsif ($type eq "short") { $sig = "-" }

    # Are we being asked for *specific* help?
    if (my @help = grep{ exists $options{$_} } @ARGV) {
        my $what = $help[0];
        if (exists $options{ $help[0] }{longhelp}) {
            print "$0 $what - $options{$what}{help}\n\n";
            print $options{$what}{longhelp} . "\n";
          } else {
            print "No help available for $what\n";
        }
      } else {
        my $and_there_s_more = 0;
        print <<EOF;
$0 ${sig}help - This text
$0 ${sig}version - Prints the version number

EOF

        for (keys %options) {
            print "$0 $_ - $options{$_}{help}";
            $and_there_s_more++, (print "[*]")
              if defined $options{$_}{longhelp}
              and $options{$_}{longhelp} =~ /\S/;
            print "\n";
        }

        if ($and_there_s_more) {
            print <<EOF

More help is available on the topics marked with [*]
Try $0 ${sig}help ${sig}foo

EOF
        }
    }
    exit 0;
}

END {
    if (grep { /^-{0,2}h(elp|)$/ } @ARGV) { helpme() }
    if (grep { /^--version|-V$/  } @ARGV) { version(); exit 0; }
    while (my $foo = shift @ARGV) {
        if (exists $options{$foo}) {
            $options{$foo}{code}->(@ARGV);
            exit;
        } else {
            if (_type($foo) ne $type and _type($foo) ne "bare") {
                if (_type($foo) eq "short") {
                    $foo =~ s/-//;
                    $main::options{$_}++ 
                    for split //,$foo;
                } else {
                    $main::options{$foo}++;
                }
            } else {
                # Don't know this.
                print STDERR "Unrecognised option $foo\n";
                helpme();
            }
       }
   }
   if (exists &main::default) { main::default() }
}

package Getopt::Auto::PodExtract;
use base 'Pod::Parser';

sub command {
    my $self = shift;
    my ($command, $text, $line_num) = @_;
    if ($command eq 'item' || $command =~ /^head(?:2|3|4)/) {
        no strict 'refs';

        if (/C<([^>]+)> - (.*)/ or /(\w+) - (.*)/ and exists &{"main::$1"})
        {
            $self->{funcs}{$1} = {
                shorthelp => $2,
                     code => *{"main::$1"}{CODE}
            };
            $self->{copying} = 1;
            $self->{latest}  = $1;
        }
    }
}

sub verbatim {
    my ($self, $paragraph, $line_num) = @_;
    $self->{funcs}{ $self->{latest} }{longhelp} .= $paragraph
      if $self->{copying};
}

sub textblock {
    my ($self, $paragraph, $line_num) = @_;
    $self->{funcs}{ $self->{latest} }{longhelp} .=
      $self->interpolate($paragraph, $line_num)
      if $self->{copying};
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Getopt::Auto - Framework for command-line applications

=head1 SYNOPSIS

Not very magical:

  use Getopt::Auto 
    (
        [ "--wibble", "Wibble to standard output" ],
        [ "--wobble", "Wobble to standard output", \&Something::Wobble ]
        [ "--wubble", "Wubble to standard output",
  "We're not entirely sure what a wubble is, but this option does it.",
  \&Something::Wubble ]
    );
  our $VERSION = "1.0";

Now C<yourprogram --wibble foo> will call C<wibble("foo")>.

Pretty magical:

    use Getopt::Auto; # We'll work it out from the POD.
    
=head1 DESCRIPTION

Unix command line applications, rather than simple filters, are pretty
unpleasant to write; as well as actually writing the functionality,
there's the boring parsing of the command line arguments and so on. Even
with C<Getopt::Long> or equivalent, you still have to dispatch the
appropriate commands to the right subroutines, write a C<--help> and
C<--version> handler, and so on. This module abstracts out that code,
leaving you free just to concentrate on the functional part.

In the "non-magical" mode, you provide a list of lists. Each element
contains the name of the command and a short help message; this may be
followed by a longer help message, to be given when something like
C<--help foo> is passed, and/or a code reference for the function to be
called. If there isn't a code reference given, we assume it will be
C<&main::foo>. If your command name contains hyphens, they will be
flattened to semicolons: C<--foo-bar> will call C<foo_bar>.

C<Getopt::Auto> is happy for you to use "long" (C<--gnu-style>),
"short" (C<-oldstyle>) or even "bare" command names,
(C<myprogram edit foo.txt>, CVS-style) on the condition that you are
consistent. Additionally, if you use bare or long style commands, then
any short options passed before a command name will be sent into
C<%main::options>. For instance, given

    use Getopt::Auto (
        "edit" => "open a file for editing",
        "export" => "write out the data as an ASCII file"
    );

C<yourprog -vt edit -x foo.txt> will perform the following:

    $main::options{v} = 1
    $main::options{t} = 1
    edit("-x", "foo.txt");

=head2 HELP AND VERSION

C<Getopt::Auto> automatically provides C<help> and C<version> commands,
following your chosen style (long, short or bare).

C<help> lists the commands available and the short help messages. If a
C<help I<command>> is given for a command name with a long message, the
longer message will be printed instead. 

C<version> displays your program name, plus C<$main::VERSION>. This
means you must set C<our $VERSION = "whatever"> in your application!

=head2 MAGICAL MODE

Now, the premise of C<Getopt::Auto> is that it frees you from the
boring stuff, right? And it could be argued that writing a specification
to hand to C<Getopt::Auto> is itself boring stuff. Well, never fear.

If you don't want to write such a specification, you don't have to.

All you need to do is write your commands, and then write some POD in
front of them, like so:

    use Getopt::Auto;
    our $VERSION = "1.0";

    =head2 wibble - wibble to standard output

    This command emits a simple wibble to standard output. It takes no
    other options.

    =cut

    sub wibble { print "Aaargh!\n" }

C<Getopt::Auto> will go through and find the subroutines which have a
corresponding bit of POD documentation, and turn them into long options;
you can now say C<yourprogam --wibble>, and C<wibble()> will be called.
C<--help> and C<--version> work as normal, and the documentation
following the C<head2> will be taken as the long help text.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

L<Config::Auto>, L<Getopt::Long>

=cut
