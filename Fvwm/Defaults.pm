##############################################################################
#
#   @(#)$Id: Defaults.pm,v 1.3 1997/07/06 23:23:33 rjray Exp $  
#
#   Description:    This module is to provide some basic default handlers
#                   for the more common packet types, or those that will
#                   rarely need any other behavior.
#
#   Functions:      FvwmError
#                   TkFvwmError
#
#   Libraries:      X11::Fvwm
#
##############################################################################

package X11::Fvwm::Defaults;

require 5.002;

use strict;
use vars qw($VERSION @EXPORT_OK @ISA);

use Exporter;
use AutoLoader;
use Carp;

use X11::Fvwm;

@ISA = qw(Exporter AutoLoader);
@EXPORT_OK = qw(
                FvwmError
                TkFvwmError
               );

$VERSION = sprintf("%d.%02d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/o);

1;

__END__

##############################################################################
#
#   Sub Name:       FvwmError
#
#   Description:    Handle an error message from Fvwm. This assumes we are
#                   running in a text mode, not under Tk.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       X11::Fvwm object
#                   $type     in      scalar    Packet type
#                   @args     in      list      Additional args
#
#   Globals:        M_ERROR
#
##############################################################################
sub FvwmError
{
    my ($self, $type, @args) = @_;

    return unless ($type == M_ERROR);

    carp "$0 [$$]: An Fvwm error has been detected: $args[3]\n";
}

##############################################################################
#
#   Sub Name:       TkFvwmError
#
#   Description:    Basically similar to FvwmError, except it uses a Tk
#                   Dialog widget for the reporting.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      ref       X11::Fvwm object
#                   $top      in      ref       Tk top-level object
#                   $type     in      scalar    Packet type
#                   @args     in      list      Additional args
#
#   Globals:        M_ERROR
#
#   Returns:        1 if the application should continue
#                   0 if the application should exit
#
##############################################################################
sub TkFvwmError
{
    my ($self, $type, @args) = @_;

    return 1 unless ($type == M_ERROR);

    my $top = $self->{topLevel};

    my $err = $top->Dialog(-title => 'FVWM Error',
                           -bitmap => 'error',
                           -default_button => 'Dismiss',
                           -text => $args[3],
                           -buttons => ['Dismiss', 'Exit']);
    my $btn = $err->Show(-global);

    return ($btn eq 'Exit') ? 0 : 1;
}

=head1 NAME

X11::Fvwm::Defaults - X11::Fvwm default packet handlers for some packet types

=head1 SYNOPSIS

    use X11::Fvwm;
    use X11::Fvwm::Defaults 'FvwmError';

    $handle = new X11::Fvwm;

    $handle->initModule;

    $handle->addHandler(M_ERROR, \&FvwmError);
    ...

    $handle->eventLoop;
    $handle->endModule;

=head1 DESCRIPTION

The B<X11::Fvwm> package is designed to provide access via Perl 5 to the
module API of Fvwm 2. This code is based upon Fvwm 2.0.45 beta.

The B<X11::Fvwm::Defaults> package is intended to offer some simple handlers
for those packets that lend themselves to such, in an effort to enourage
code-reuse and to simplify development.

=head1 ROUTINES

There are currently two routines available for import. Neither are exported
by default, so you must explicitly request those routines desired when you
use the B<Defaults> package. Both of these are for the B<M_ERROR> packet:

=over 8

=item FvwmError

This packet emits the text of the error sent by Fvwm to STDERR using the Carp
package from the Perl core, specifically the routine B<carp>. This routine
by default includes some stack-trace information in the generated output,
which may aid in tracking down the problem in question. You may also wish
to look at the special signal-class C<__WARN__>, documented in L<perlfunc>.


This does not suppress the error message that Fvwm itself displays to STDERR,
which will be the same source to which your application writes (unless you
use $SIG{__WARN__} to completely re-direct the messages). 

=item TkFvwmError

This handler creates a dialog box using the Tk widgets to notify you that
an error has been reported by Fvwm. The dialog has three buttons, labelled
"Exit", "Stack Trace" and "Dismiss". Selecting the "Dismiss" button closes the
dialog, and allows your application to continue (the B<TkFvwmError> routine
grabs the pointer until the dialog is closed). Choosing the "Exit" button
causes the handler to return a zero (0) exit code to the B<processPacket>
method, which in turn triggers the exit handlers and terminates the running
module. If the "Stack Trace" button is pressed, then a current trace of the
stack will be produced, showing the sequence of calls that led up to the
error. After exiting that window, the application will continue as if the
"Dismiss" button had been pressed.


As with the non-Tk routine above, Fvwm will still produce its own error
message that this routine has no power to suppress.

=back

=head1 EXAMPLES

The B<PerlTkWL> sample script uses the B<TkFvwmError> default to handle any
instances of Fvwm errors. To force this behavior, bind a mouse-button to
invoke a non-existant module, then click that button in an active B<PerlTkWL>.

=head1 BUGS

None known.

=head1 CAVEATS

Currently, only the B<M_ERROR> packet type has any defaults to offer. Other
types don't appear to lend themselves well to default handlers.

I don't really like the way stack traces are displayed in the B<TkFvwmError>
routine, but it will have to do for now.

=head1 AUTHOR

Randy J. Ray <randy@byz.org>

=head1 SEE ALSO

For more information, see L<fvwm>, L<X11::Fvwm> and L<Tk>

=cut
