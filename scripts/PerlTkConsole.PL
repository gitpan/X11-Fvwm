#!/usr/local/bin/perl

use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
	if ($Config{'osname'} eq 'VMS' or
	    $Config{'osname'} eq 'OS2');  # "case-forgiving"

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
	if 0;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
    eval 'exec perl -S $0 "$@"'
	if 0;
#
# PerlConsole - a blend of FvwmTalk and FvwmDebug. Based upon:
#
# console.pl - combination FvwmTalk/FvwmDebug using fvwmmod.pl
#
# Only this version uses X11::Fvwm

require 5.002;

use strict;
use vars qw($MW $FVWM $epacketlimit $packetlimit $defFont $cmd $winid $contxt
            @args %opt @history $histindx $pf $packetlog $pl $ef $errlog $el
            $tf $quitbut $bufentry $buflbl $lbl $mask %options);

use Tk;
use X11::Fvwm::Tk;
use Getopt::Std;

$MW = MainWindow->new;

$FVWM = new X11::Fvwm::Tk $MW;
($winid, $contxt, @args) = $FVWM->initModule;

{
    local (@ARGV) = @args;
    getopt('dcw', \%opt);
}

#
# Set the mask to use based on whether the user requested the debugging window.
# If that window is not used, then we really only care about M_ERROR.
#
if (exists $opt{d} and $opt{d})
{
    $mask = M_NEW_PAGE | M_NEW_DESK | M_ADD_WINDOW | M_CONFIGURE_WINDOW |
            M_LOWER_WINDOW | M_RAISE_WINDOW | M_DESTROY_WINDOW |
            M_DEICONIFY | M_MAP | M_FOCUS_CHANGE | M_ICONIFY |
            M_ICON_LOCATION | M_WINDOW_NAME | M_ICON_NAME | M_RES_CLASS |
            M_RES_NAME | M_CONFIG_INFO | M_ERROR | M_END_WINDOWLIST |
            M_END_CONFIG_INFO;
}
else
{
    $mask = M_ERROR;
}

$FVWM->mask($mask);

%options = &readConfig($FVWM, $MW);

if (exists $opt{d} and $opt{d})
{
    $FVWM->addHandler(M_NEW_PAGE, \&ListNewPage);
    $FVWM->addHandler(M_NEW_DESK, \&ListNewDesk);
    $FVWM->addHandler(M_ADD_WINDOW | M_CONFIGURE_WINDOW, \&ListConfigWin);
    $FVWM->addHandler(M_LOWER_WINDOW | M_RAISE_WINDOW | M_DESTROY_WINDOW |
                      M_DEICONIFY | M_MAP, \&ListWindow);
    $FVWM->addHandler(M_FOCUS_CHANGE, \&ListFocus);
    $FVWM->addHandler(M_ICONIFY | M_ICON_LOCATION, \&ListIcon);
    $FVWM->addHandler(M_WINDOW_NAME | M_ICON_NAME | M_RES_CLASS | M_RES_NAME,
                      \&ListName);
    $FVWM->addHandler(M_CONFIG_INFO | M_ERROR, \&ListConfigInfo);
    $FVWM->addHandler(M_END_WINDOWLIST | M_END_CONFIG_INFO,
                      \&ListEndConfigInfo);

    #
    # These are only meaningful if we have the debugging window open
    #
    $FVWM->sendInfo($winid, "Send_ConfigInfo") if ($opt{c});
    $FVWM->sendInfo($winid, "Send_WindowList") if ($opt{w});
}
$FVWM->addHandler(M_ERROR, \&handleError);

@history = ();
# Initial 500 line limit (arbitrary)
if (defined $options{limit})
{
    $packetlimit = $options{limit};
}
else
{
    $packetlimit = 500;
}
$epacketlimit = $packetlimit;

$cmd = $MW->Entry(-width => 80);
$cmd->bind('<Return>' =>
           sub {
               my $line = $cmd->get;
               unshift(@history, $line);
               pop(@history) if (@history > 20);
               $FVWM->sendInfo(0, $line);
               $cmd->delete(0, 'end');
               $histindx = @history;
           });

$cmd->bind('<Control-p>' => \&histprev);
$cmd->bind('<Up>' => \&histprev);
$cmd->bind('<Control-n>' => \&histnext);
$cmd->bind('<Down>' => \&histnext);

if (exists $opt{d} and $opt{d})
{
    ($pf, $packetlog, $pl) = &ScrollBox($MW, "Packets:", 20, 'yes');
    $tf = $MW->Frame();
    $tf->pack(-fill => 'x', -before => $pf);

    $quitbut = $tf->Button(-text => "Quit",
                           -foreground => 'red',
                           -command => sub { $FVWM->endModule ; exit });
    $quitbut->pack(-side => 'right', -anchor => 'e');

    $bufentry = $tf->Entry(-width => 5, -textvariable => \$epacketlimit,
                           -justify => 'right');
    $bufentry->bind('<Return>' =>
                    sub {
                        my ($size, $lines);
                        if ($epacketlimit > 0) {
                            $packetlimit = $epacketlimit;
                        }
                        $bufentry->delete(0, 'end');
                        $bufentry->insert(0,$packetlimit);
                        $size = $packetlog->index('end');
                        $lines = ($size - $packetlimit);
                        $packetlog->delete(0, $lines)
                            if ($size > $packetlimit);
                    });

    $buflbl = $tf->Label(-text => 'Packet buffer limit (lines):');

    $bufentry->pack(-side => 'right', -anchor => 'e');
    $bufentry->bind('<Control-u>' => sub {$bufentry->delete(0, 'end')});
    $buflbl->pack(-side => 'right');

    $tf->bind('<Enter>' => sub { $bufentry->focus });
}

($ef, $errlog, $el) = &ScrollBox($MW, "Errors:", 5, 'no');
if (! $opt{d})
{
    my $qf = $MW->Frame;
    $qf->pack(-fill => 'x', -before => $ef);
    $quitbut = $qf->Button(-text => "Quit",
                           -foreground => 'red',
                           -command => sub { $FVWM->endModule ; exit });
    $quitbut->pack(-side => 'right', -anchor => 'e');
}

$lbl = $MW->Frame;
$lbl->pack(-fill => 'x');
$lbl->Label(-text => "Commands:")->pack(-anchor => 'sw');

sub histprev {
    $cmd->delete(0, 'end');
    $histindx = 0 if (++$histindx > @history);
    $cmd->insert(0, "$history[$histindx]");
}

sub histnext {
    $cmd->delete(0, 'end');
    $histindx = @history if (--$histindx < 0);
    $cmd->insert(0, "$history[$histindx]") if ($histindx >= 0);
}

$cmd->bind('<Control-u>' => sub { $cmd->delete(0, 'end') });
$cmd->pack(-fill => 'x');

$MW->focusFollowsMouse;
$MW->title("PerlConsole");

$FVWM->eventLoop;

$FVWM->endModule;
exit;

########################################################################
# Subroutines
########################################################################
sub readConfig
{
    my $mod = shift;
    my $top = shift;

    my ($widget, $spec, $key);

    my %opts = $mod->getConfigInfo(-trimname, -nocase);

    #
    # These are the most high-level specifications. We assign them defaults.
    #
    $opts{font}       = '*helvetica*m*o*n*14*' unless (defined $opts{font});
    $opts{foreground} = 'black' unless (defined $opts{foreground});
    $opts{background} = 'moccasin' unless (defined $opts{background});
    $opts{labelfont}  = '*helvetica*m*o*n*14*'
        unless (defined $opts{labelfont});

    #
    # Now set these values into the options database. We will assign the high-
    # level defaults to very generic options, then we will look to see if the
    # user defined any more-specific values for individual widget types.
    #
    $top->optionAdd('*foreground' => $opts{foreground});
    $top->optionAdd('*background' => $opts{background});
    $top->optionAdd('*font'       => $opts{font});
    $top->optionAdd('*activeforeground' => $opts{activeforeground})
        if (exists $opts{activeforeground});
    $top->optionAdd('*activebackground' => $opts{activebackground})
        if (exists $opts{activebackground});

    for $widget (qw(Button Label Listbox Entry Scrollbar))
    {
        for $key (qw(foreground background))
        {
            $spec = lc "${widget}$key";
            $top->optionAdd("*$widget.$key" => $opts{$spec})
                if (exists $opts{$spec});
        }
        # font is special, because the default looks silly in the scrollbox
        $spec = lc  "${widget}font";
        $top->optionAdd("*$widget.font" =>
                        (exists $opts{$spec}) ? $opts{$spec} : 'fixed');
    }
    $top->optionAdd('*Scrollbar.troughColor', $opts{scrollbartroughcolor})
        if (exists $opts{scrollbartroughcolor});

    %opts;
}

sub ScrollBox {
    my ($parent, $label, $initheight, $expand) = @_;

    my $frame = $parent->Frame();
    $frame->bind('<Enter>' => sub {$cmd->focus});
    $frame->pack(-side => 'top', -expand => $expand, -fill => 'both');
    my $lbl = $frame->Label(-text => $label);
    $lbl->pack(-anchor => 'sw');
    my $sbar = $frame->Scrollbar;
    $sbar->pack(-side => 'right', -fill => 'y');
    my $lbox = $frame->Listbox(-yscrollcommand => [$sbar => 'set'],
                               -height => $initheight,
                               -selectmode => 'single');
    $sbar->configure(-command => [$lbox => 'yview']);
    $lbox->pack(-expand => $expand, -fill => 'both',);
    ($frame, $lbox, $lbl, $sbar);
}

# tohex - convert a list of values from decimal to hex
sub tohex {
    map { sprintf("%lX", $_) } (@_);
}

sub Quit {
    &showline( "$0 exiting\n");
    $FVWM->endModule;
    exit;
}

sub ListNewPage { 
    my ($self, $type, $x, $y, $desk) = @_;

    &showline("new page\n     x $x\n     y $y\n     desk $desk\n");
    1;
}
sub ListNewDesk {
    my ($self, $type, $desk) = @_;

    &showline("new desk\n     desk $desk\n");
    1;
}

sub ListConfigWin { 
    my ($self, $type, $id, $fid, $ptr, $x, $y, $w, $h,
        $desk, $flags, $th, $bw, $wbw, $wbh,
        $wrwi, $wrhi, $minw, $minh, $maxw, $maxh,
        $lblid, $pmid, $grav, $tc, $bc) = @_;

    my $stype = "Add Window" if ($type == M_ADD_WINDOW);
    $stype = "Config Window" if ($type == M_CONFIGURE_WINDOW);
    ($id, $fid, $ptr, $flags, $lblid, $pmid, $grav, $tc, $bc) =
        &tohex($id, $fid, $ptr, $flags, $lblid, $pmid, $grav, $tc, $bc);
    &showline(<<"END");
$stype
     ID $id
     frame ID $fid
     fvwm ptr $ptr
     frame x $x
     frame y $y
     frame w $w
     frame h $h
     desk $desk
     flags $flags
     title height $th
     border width $bw
     window base width $wbw
     window base height $wbh
     window resize width increment $wrwi
     window resize height increment $wrhi
     window min width $minw
     window min height $minh
     window max width $maxw
     window max height $maxh
     icon label window $lblid
     icon pixmap window $pmid
     window gravity $grav
     text color pixel value $tc
     border color pixel value $bc
END
    1;
}

sub ListWindow {
    my ($self, $type, $id, $fid, $ptr) = @_;

    my $stype = "raise" if ($type == M_RAISE_WINDOW);
    $stype = "lower" if ($type == M_LOWER_WINDOW);
    $stype = "destroy" if ($type == M_DESTROY_WINDOW);
    $stype = "map" if ($type == M_MAP);
    $stype = "de-iconify" if ($type == M_DEICONIFY);
    ($id, $fid, $ptr) = &tohex($id, $fid, $ptr);

    &showline("$stype\n     ID $id\n     frame ID $fid\n     fvwm ptr $ptr\n");
    1;
}

sub ListFocus { 
    my ($self, $type, $id, $fid, $ptr, $tc, $bc) = @_;

    ($id, $fid, $ptr) = &tohex($id, $fid, $ptr);
    &showline("focus\n     ID $id\n     frame ID $fid\n     fvwm ptr $ptr\n");
    &showline("     text color pixel value $tc\n     border color pixel value $bc\n");
    1;
}

sub ListIcon {
    my ($self, $type, $id, $fid, $ptr, $x, $y, $w, $h) = @_;

    my $stype = "iconify" if ($type == M_ICONIFY);
    $stype = "icon location" if ($type == M_ICON_LOCATION);
    ($id, $fid, $ptr) = &tohex($id, $fid, $ptr);
    &showline("$stype\n     ID $id\n     frame ID $fid\n     fvwm ptr $ptr\n");
    &showline("     icon x $x\n     icon y $y\n     icon w $w\n     icon h $h\n");
    1;
}

sub ListName {
    my ($self, $type, $id, $fid, $ptr, $value) = @_;

    my $stype = "window name" if ($type == M_WINDOW_NAME);
    $stype = "icon name" if ($type == M_ICON_NAME);
    $stype = "window class" if ($type == M_RES_CLASS);
    $stype = "class resource name" if ($type == M_RES_NAME);
    ($id, $fid, $ptr) = &tohex($id, $fid, $ptr);
    &showline("$stype\n     ID $id\n     frame ID $fid\n     fvwm ptr $ptr\n");
    &showline("     $stype $value\n");
    1;
}

sub ListConfigInfo {
    my ($self, $type, $empty1, $empty2, $empty3, $txt) = @_;

    my $stype = "config_info" if ($type == M_CONFIG_INFO);
    $stype = "error" if ($type == M_ERROR);
    &showline( "$stype\n    $txt\n");
    1;
}

sub ListEndConfigInfo {
    &showline("end_config_info\n");
    1;
}

sub handleError {
    my ($self, $type, $win, $frame, $ptr, $err) = @_;

    my $errlimit = 20;
    my ($size, $lines);

    $errlog->insert('end', "$err\n");
    $size = $errlog->index('end');
    $lines = ($size - $errlimit);
    $errlog->delete(0, $lines) if ($size > $errlimit);
    $errlog->see('end');
    1;
};

sub showline {
    my ($size, $line, $lines);

    for $line (split(/\n/, $_[0])) {
        $packetlog->insert('end', "$line");
    }
    $size = $packetlog->index('end');
    $lines = ($size - $packetlimit);
    $packetlog->delete(0, $lines) if ($size > $packetlimit);
    $packetlog->see('end');
}
__END__

=head1 NAME

TkPerlConsole - a console and debugging window implemented in Perl/Tk

=head1 SYNOPSIS

B<TkPerlConsole> can only be spawned by I<fvwm>. No command-line invocation is
possible.

=head1 DESCRIPTION

B<TkPerlConsole> is a sample application distributed with the B<X11::Fvwm>
extension to Perl 5. It combines the functionality of the B<FvwmConsole> and
B<FvwmDebug> modules (from the I<extras> directory of the Fvwm2 distribution)
into one application.

=head1 INITIALIZATION

When run, B<TkPerlConsole> reads the configuration lines specified in the
configuration file I<fvwm> itself used. It specifically looks for options
whose names begin with the name of the application. You can link B<TkPerlConsole>
under additional names to specify different sets of options.

=head1 INVOCATION

B<TkPerlConsole> can be invoked by fvwm during initialization by inserting
the line 'Module TkPerlConsole' in the .fvwmrc (or .fvwm2rc) file.

B<TkPerlConsole> must reside in a directory that is listed in the
I<ModulePath> option of Fvwm for it to be executed by Fvwm.

=head1 CONFIGURATION OPTIONS

=head2 Invocation options

When spawned by Fvwm, B<TkPerlConsole> will recognize these switches:

=over

=item B<-d>

Turn on the packet debugger as well as the console window itself. Creates a
second display area above the console in which packet traffic from Fvwm is
summarized.

=item B<-c>

Send an initial B<Send_ConfigInfo> message to Fvwm. Causes the start-up debug
box to already contain all configuration options for all modules. This has no
visible effect unless B<-d> is also specified.

=item B<-w>

Send an initial B<Send_WindowList> message to Fvwm, causing the debug box to
already contain a listing of all windows currently managed by Fvwm. This has no
visible effect unless B<-d> is also specified.

=back

=head2 Run-time options from Fvwm

B<TkPerlConsole> recognizes the following list of options that it receives
from the running Fvwm process. Note that the leading part of the name is based
on the application name. Were the user to make a link to B<TkPerlConsole>
under the name I<TransientWL> (for calling as a transient application), then
you would replace C<TkPerlConsole> with C<TransientWL> in all the names below:


=over

=item *TkPerlConsoleFont

Default font to use for text in the widgets. This font is not applied to
Label widgets, however. See below for specifying defaults on a per-widget
basis.

=item *TkPerlConsoleForeground

=item *TkPerlConsoleBackground

Default foreground and background colors for widgets.

=item *TkPerlConsoleActiveForeground

=item *TkPerlConsoleActiveBackground

Foreground and background colors used by buttons to indicate the pointer
(or keyboard focus) is over that button.

=back

The following detail specifying defaults to be used for classes of widgets.
Three characteristics are recognized: Font, Foreground and Background. These
are represented below by the symbol B<(CLASS)>. These are applied to the
following set of widgets: Button, Label, Listbox, Entry and Scrollbar. These
are represented below by the symbol B<WIDGET>. Thus, there are 15 possible
expansions for the item below:

=over

=item *TkPerlConsole(WIDGET)(CLASS)

Set the default value for I<CLASS> as it should be applied to all widgets of
type I<WIDGET>. The value B<*TkPerlConsoleButtonFont> will then set the font
to be used on all buttons.

=back

Note: The default font for all widgets except labels is I<fixed>. Labels
default to a larger, italic Helvetica. Using the above specification is the
only way to change the font for Label widgets. They are not affected by the
general-default font specification. Also note that scrollbars have one extra
element of note from the other widgets, the color of the trough in which the
scrollbar thumb sits:

=over

=item *TkPerlConsoleScrollbarTroughColor

Set the color of the rectangular trough area that makes up the part of a
scrollbar not covered by the thumb.

=back

=head1 SAMPLE CONFIGURATION

Here is a sample configuration, used by the author and annotated here for
clarity:

    # General application to all widgets
    *TkPerlConsoleFont                  9x15
    *TkPerlConsoleForeground            AntiqueWhite
    *TkPerlConsoleBackground            gray30
    # Change the color of the label text
    *TkPerlConsoleLabelForeground       gold1
    # The listboxes are the areas in which data from fvwm is displayed
    *TkPerlConsoleListboxBackground     NavyBlue
    *TkPerlConsoleListboxForeground     gold1
    # Set the color of the back area of the scroll bars
    *TkPerlConsoleScrollbarTroughColor  AntiqueWhite

=head1 CAVEATS

B<TkPerlConsole> is meant primary as an example of coding with the B<X11::Fvwm>
(see L<X11::Fvwm>) module and the Tk module. While it can be useful, it is
not supported to the degree that the Fvwm module itself is.

It is also coded for clarity at the expense of efficiency.

Specifying widget characteristics by class is nice, but to truly emulate
X resources, it will have to allow specifications by given widget name as
well as class, and it doesn't (yet).

=head1 COPYRIGHT

B<TkPerlConsole> is copyright (c) 1997 by the author, all rights reserved. It
may be copied and distributed under the same terms as the B<X11::Fvwm>
module itself. See the I<README> file that was packaged with the distribution.

=head1 AUTHOR

Randy J. Ray <randy@byz.org>, based on the code from the B<fvwmperl>
module by Dan Astoorian <djast@utopia.csas.com>
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
