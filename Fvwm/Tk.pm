##############################################################################
#
#   Description:    This is part of X11::Fvwm. This sub-class isolates the
#                   Tk hooks for writing Fvwm modules with the Tk widgets.
#
#                   This code bears the following copyright:
#
#                           (c)1997 Randy J. Ray <randy@byz.org>
#                           All Rights Reserved.
#
#                           This code is covered under the terms of the
#                           Artistic License that covers Perl 5. See the file
#                           ARTISTIC in your distribution of Perl 5 for
#                           details.
#
#   Functions:      new
#                   toplevel
#                   eventLoop
#                   
##############################################################################

package X11::Fvwm::Tk;

require 5.002;

use strict;
use vars qw($VERSION @ISA @EXPORT);

use Exporter;
use AutoLoader;

use X11::Fvwm;
use Tk;

@ISA = qw(X11::Fvwm Exporter);
@EXPORT = @X11::Fvwm::EXPORT;

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/o);

1;

##############################################################################
#
#   Sub Name:       new
#
#   Description:    Constructor - Create a X11::Fvwm::Tk object. This is just
#                   a X11::Fvwm object with an extra instance variable,
#                   re-blessed into this class.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    This class
#                   $top      in      ref       Tk toplevel
#                   %params   in      hash      Extra initialization data
#
#   Returns:        Success:    blessed ref
#                   Failure:    undef
#
##############################################################################
sub new
{
    my $class = shift;
    my $top   = shift;
    my %params = @_;

    my $self = X11::Fvwm->new(%params) or return undef;

    $class = ref($class) || $class;

    bless $self, $class;
    $self->{topLevel} = $top;

    $self;
}

#
# Instance variable access method
#
sub toplevel { shift->{topLevel}; }

##############################################################################
#
#   Sub Name:       eventLoop
#
#   Description:    Enter a loop which waits for packets and uses processPacket
#                   to route them. Tie the input pipe from Fvwm to a fileevent
#                   under Tk, then fall through to Tk's MainLoop
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       Object of this class
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub eventLoop
{
    my $self = shift;

    $self->initModule unless ($self->{didInit});

    my $top = $self->{topLevel};
    $top->fileevent($self->{IFD},
                    readable =>
                    sub {
                        unless ($self->processPacket($self->readPacket))
                        {
                            $self->invokeHandler('EXIT');
                            $self->endModule;
                            $top->destroy;
                        }
                    });
    MainLoop;

    1;
}

__END__

=head1 NAME

X11::Fvwm::Tk - X11::Fvwm with the Tk widget library attached

=head1 SYNOPSIS

    use Tk;
    use X11::Fvwm::Tk;

    $top = new MainWindow;
    $handle = new X11::Fvwm::Tk $top;

    $handle->initModule;

    $handle->addHandler(M_CONFIGURE_WINDOW, \&configure_Toplevel);
    $handle->addHandler(M_CONFIG_INFO, \&some_other_sub);

    $handle->eventLoop;

    $handle->endModule;

=head1 DESCRIPTION

The B<X11::Fvwm> package is designed to provide access via Perl 5 to the
module API of Fvwm 2. This code is based upon Fvwm 2.0.45 beta.

The B<X11::Fvwm::Tk> package is a sub-class of B<X11::Fvwm> that overloads
the methods B<new> and B<eventLoop> to manage Tk objects as well.

This manual page details only those differences. For details on the
API itself, see L<X11::Fvwm>.

=head1 METHODS

Only those methods that are not available in B<X11::Fvwm>, or are overloaded
are covered here:

=over 8

=item new

$self = new X11::Fvwm::Tk $top, %params

Create and return an object of the B<X11::Fvwm::Tk> class. The return value is
the blessed reference. This B<new> method is identical to the parent class
method, with the exception that a Tk top-level of some sort (MainWindow,
TopLevel, Frame, etc.) must be passed before the hash of options. The options
themselves are as specified in L<X11::Fvwm>.

=item eventLoop 

$self->eventLoop

From outward appearances, this methods operates just as the parent
B<eventLoop> does. It is worth mentioning, however, that this version
enters into the Tk B<MainLoop> subroutine, ostensibly not to return.

=item toplevel

$self->toplevel

Returns the Tk toplevel that this object was created with. Unlike other
instance variable-related methods, the toplevel cannot be changed, so this
method ignores any arguments passed to it.

=back

=head2 Instance Variables

The following are instance variables not present in the parent class:

=over 8

=item topLevel

The Tk object that was passed as the toplevel this object will use, should
it need to call any Tk widget methods (such as dialog creation). It is
recommended that you use the access method B<toplevel> instead of reading
this directly.

=back

=head1 EXAMPLES

Examples are provided in the B<scripts> directory of the distribution.
These are:

=over 8

=item PerlTkWL

A much more robust WinList clone, it looks and acts very much like the
FvwmWinList module that comes with Fvwm. It differs in some subtle ways,
however. This one handles more packet types, as well as demonstrating
the interaction between X11::Fvwm and the Tk extension. Requires Tk 400.200
or better.

=item PerlTkConsole

A combination of the B<FvwmConsole> and B<FvwmDebug> modules from the
I<extras> directory of the Fvwm distribution. Allows the user to send commands
to Fvwm, and if the debugging is enabled, also shows traffic from Fvwm in a
format slightly cleaned up for ease of reading.

=back

=head1 BUGS

Would not surprise me in the least.

=head1 CAVEATS

In keeping with the UNIX philosophy, B<X11::Fvwm> does not keep you from
doing stupid things, as that would also keep you from doing clever things.
What this means is that there are several areas with which you can hang your
module or even royally confuse your running I<Fvwm> process. This is due to
flexibility, not bugs.

=head1 AUTHOR

Randy J. Ray <randy@byz.org>

=head1 ADDITIONAL THANKS TO

Nick Ing-Simmons <Nick.Ing-Simmons@tiuk.ti.com> for the incredible Tk Perl
extension.

=head1 SEE ALSO

For more information, see L<fvwm>, L<X11::Fvwm> and L<Tk>

=cut
