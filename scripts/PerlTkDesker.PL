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

#
# A simpler version of the pager, that only switches between desktops without
# the outlines of windows. Patterned after the built-in pager that comes with
# tkGoodStuff.
#
# Randy J. Ray
#

use 5.003;
use strict;
use vars qw($TOP $fvwm %opts $current_desk $frame @buttons @desk_focus);
use Carp;

use Tk;
use X11::Fvwm::Tk;
use X11::Fvwm::Defaults 'TkFvwmError';

my $TOP = new MainWindow;
my $fvwm = new X11::Fvwm::Tk $TOP,
                             INIT => 1,
                             CONFIG => 1,
                             MASK => (M_NEW_DESK | M_FOCUS_CHANGE | M_ERROR);
&ReadDeskerOptions($fvwm, $TOP);

$frame = $TOP->Frame;
$TOP->title($opts{Title} || "PerlTkDesker");
$TOP->geometry($opts{Geometry}) if (defined $opts{Geometry});
&makeButtons($frame, $fvwm);
$frame->pack(-expand => 1, -fill => 'both', -anchor => 'nw');

$fvwm->addHandler(M_NEW_DESK,
                  sub {
                      my ($self, $type, $desk) = @_;

                      &unhilite($current_desk);
                      return $self
                          if ($desk < $opts{START} or
                              $desk > $opts{'END'});
                      $current_desk = $desk;
                      &hilite($current_desk, $self);

                      $self;
                  });
$fvwm->addHandler(M_FOCUS_CHANGE,
                  sub {
                      my ($self, $type, $id, $frameid, $ptr) = @_;

                      $desk_focus[$current_desk] = $id;

                      $self;
                  });
# M_ERROR will be handled by a default:
$fvwm->addHandler(M_ERROR, \&TkFvwmError);

#
# Any signals we need to be wary of?
#
$SIG{PIPE} = sub { exit };

$current_desk = &currentDesk($fvwm);
&hilite($current_desk);

$fvwm->eventLoop; # Never returns

exit;

sub ReadDeskerOptions
{
    my $mod = shift;
    my $top = shift;

    my @args = $mod->argv;

    croak "Usage: $0 #start #end [ -name name_string ]\n"
        if (@args < 2);

    my $START = shift(@args);
    my $END   = shift(@args);

    for ($START .. $END) { $desk_focus[$_] = undef }

    if ($args[0] eq '-name' and defined($args[1]))
    {
        $mod->name($args[1]);
    }

    %opts = $mod->getConfigInfo(-trimname);

    $top->optionAdd('*foreground', $opts{Foreground})
        if (exists $opts{Foreground});
    $top->optionAdd('*background', $opts{Background})
        if (exists $opts{Background});
    $top->optionAdd('*font', $opts{Font}) if (exists $opts{Font});

    $opts{COLS} = $opts{Columns} || 1;
    $opts{ROWS} = $opts{Rows} || 1;
    $opts{START} = $START;
    $opts{'END'} = $END;

    1;
}

sub makeButtons
{
    my $top = shift;
    my $mod = shift;

    my ($start, $end, $cols, $rows) = ($opts{START}, $opts{'END'},
                                       $opts{COLS},  $opts{ROWS});
    my ($x, $y, $text, $button, $frame, @labels);

    die "Managed desks ($start to $end) must exactly fit in ${cols}x$rows " .
        "space, stopped"
            if (($cols * $rows) != ($end - $start + 1));

    if (exists $opts{Label} and ref($opts{Label}) eq 'ARRAY')
    {
        my ($each, $pos, $string);

        for $each (@{$opts{Label}})
        {
            ($pos, $string) = split(/ /, $each, 2);
            $labels[$pos] = $string;
        }
    }

    for ($x = 0; $x < $cols; $x++)
    {
        $frame = $top->Frame;
        for ($y = 0; $y < $rows; $y++)
        {
            my $pos = $start + $x + ($y * $cols);

            $button = $frame->Label(-relief => 'raised');
            $button->bind('<1>',
                          sub {
                              $mod->sendInfo(0, "Desk 0 $pos");
                          });
            $text = $labels[$pos] || "Desk $pos";
            $button->configure('text' => "$text") unless
                (exists $opts{NoLabels} and $opts{NoLabels} !~ /no/oi);

            $button->pack(-side => 'top', -expand => 1, -fill => 'both');

            # This index happens to match the desk #, for (un)hilite
            $buttons[$pos] = $button;
        }
        $frame->pack(-side => 'left', -expand => 1, -fill => 'both');
    }

    1;
}

sub hilite
{
    my $desk = shift;
    my $mod = shift;

    my $button = $buttons[$desk];

    if (exists $opts{CurrentDeskBackground})
    {
        $button->configure(-background => $opts{CurrentDeskBackground});
        $button->configure(-foreground => $opts{CurrentDeskForeground})
            if (exists $opts{CurrentDeskForeground});
    }
    else
    {
        $button->configure(-relief => 'sunken');
    }
    #$mod->sendInfo($desk_focus[$desk], "Focus")
    #    if (defined $desk_focus[$desk]);

    1;
}

sub unhilite
{
    my $desk = shift;

    my $button = $buttons[$desk];

    if (exists $opts{CurrentDeskBackground})
    {
        $button->configure(-background => $opts{Background});
        $button->configure(-foreground => $opts{Foreground})
            if (exists $opts{CurrentDeskForeground});
    }
    else
    {
        $button->configure(-relief => 'raised');
    }

    1;
}

sub currentDesk
{
    my $mod = shift;

    my ($len, $packet, $type, @args);
    my $current = 0;

#     my $old_mask = $mod->mask(M_CONFIGURE_WINDOW | M_END_WINDOWLIST);
#     $mod->sendInfo(0, "Send_WindowList");
#     while (1)
#     {
#         ($len, $packet, $type) = $mod->readPacket;
#         last if ($type & M_END_WINDOWLIST);
#         last if ($len < 0);

#         @args = unpack($self->{packetTypes}->{$type}, $packet);
#         if ($args[2] == $self->{

    $current;
}
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
