##############################################################################
#
#   Description:    This is part of X11::Fvwm. This sub-class isolates the
#                   Xforms hooks for writing Fvwm modules with the Xforms
#                   library.
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
#                   topform
#                   eventLoop
#                   
##############################################################################

package X11::Fvwm::Xforms;

require 5.002;

use strict;
use vars qw($VERSION @ISA @EXPORT);

use Exporter;
use AutoLoader;

use X11::Fvwm;
use X11::Xforms;

@ISA = qw(X11::Fvwm Exporter);
@EXPORT = @X11::Fvwm::EXPORT;

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/o);

1;

##############################################################################
#
#   Sub Name:       new
#
#   Description:    Constructor - Create a X11::Fvwm::Xforms object. This is
#                   just a X11::Fvwm object with an extra instance variable,
#                   re-blessed into this class.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $class    in      scalar    This class
#                   $top      in      ref       Toplevel form
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
    $self->{topForm} = $top;

    $self;
}

#
# Instance variable access method
#
sub topform { shift->{topForm}; }

##############################################################################
#
#   Sub Name:       eventLoop
#
#   Description:    Enter a loop which waits for packets and uses processPacket
#                   to route them. Tie the input pipe from Fvwm to a file I/O
#                   callback. Any arguments beyond the object ref are passed
#                   to fl_do_forms.
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

    fl_add_io_callback(fileno($self->{IFD}), FL_READ,
		       sub {
			   unless ($self->processPacket($self->readPacket))
			   {
			       $self->invokeHandler('EXIT');
			       $self->endModule;
			   }
		       });
    fl_do_forms(@_);

    1;
}

__END__

=head1 NAME

X11::Fvwm::Xforms - X11::Fvwm with the Xforms widget library attached

=head1 SYNOPSIS

    use X11::Xforms;
    use X11::Fvwm::Xforms;

    fl_initialize("Xforms example");
    $top = fl_bgn_form(...);
    ...
    fl_end_form();
    fl_show_form($top, ...);

    $handle = new X11::Fvwm::Xforms $top;

    $handle->initModule;

    $handle->addHandler(M_CONFIGURE_WINDOW, \&configure_Toplevel);
    $handle->addHandler(M_CONFIG_INFO, \&some_other_sub);

    $handle->eventLoop;

    $handle->endModule;

=head1 DESCRIPTION

The B<X11::Fvwm> package is designed to provide access via Perl 5 to the
module API of Fvwm 2. This code is based upon Fvwm 2.0.45 beta.

The B<X11::Fvwm::Xforms> package is a sub-class of B<X11::Fvwm> that overloads
the methods B<new> and B<eventLoop> to manage Xforms GUI objects as well.

This manual page details only those differences. For details on the
API itself, see L<X11::Fvwm>.

=head1 METHODS

Only those methods that are not available in B<X11::Fvwm>, or are overloaded
are covered here:

=over 8

=item new

$self = new X11::Fvwm::Xforms $top, %params

Create and return an object of the B<X11::Fvwm::Xforms> class. The return
value is
the blessed reference. This B<new> method is identical to the parent class
method, with the exception that a Xforms form object
must be passed before the hash of options. The options
themselves are as specified in L<X11::Fvwm>. As B<Xforms> does not necessarily
require an object instance for most calls, this value can be passed as either
an empty string or C<undef> if it will not be needed in packet handlers. It
is provided as a means of giving access to the top-most form to subroutines.

=item eventLoop 

$self->eventLoop(@optional_args)

From outward appearances, this methods operates just as the parent
B<eventLoop> does. It is worth mentioning, however, that this version
enters into the Xforms B<fl_do_forms> subroutine, ostensibly not to return.
Any arguments passed to B<eventLoop> are passed along unmodified to
B<fl_do_forms>.

=item topform

$self->topform

Returns the Xforms form object that this object was created with. Unlike other
instance variable-related methods, the form cannot be changed, so this
method ignores any arguments passed to it.

=back

=head2 Instance Variables

The following are instance variables not present in the parent class:

=over 8

=item topForm

The Xforms object that was passed as the toplevel this object will use, should
it need to call any Xforms routines (such as dialog creation). It is
recommended that you use the access method B<topform> instead of reading
this directly.

=back

=head1 EXAMPLES

Examples are provided in the B<scripts> directory of the distribution.
No Xforms-related examples are available yet.

=head1 BUGS

Would not surprise me in the least.

=head1 CAVEATS

In keeping with the UNIX philosophy, B<X11::Fvwm> does not keep you from
doing stupid things, as that would also keep you from doing clever things.
What this means is that there are several areas with which you can hang your
module or even royally confuse your running I<Fvwm> process. This is due to
flexibility, not bugs.

The B<X11::Xforms> module itself is still in early development stages, and as
such may be somewhat noisy if C<-w> is used.

=head1 AUTHOR

Randy J. Ray <randy@byz.org>

=head1 ADDITIONAL THANKS TO

Martin Bartlett <martin@nitram.demon.co.uk>, who developed the X11::Xforms
Perl extension.

=head1 SEE ALSO

For more information, see L<fvwm>, L<X11::Fvwm> and L<X11::Xforms>

=cut
