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
# Adaption of Dan Astoorian's FvwmDebug.pl script to X11::Fvwm syntax
#

use strict;
use vars qw(%opt $FVWM $winid $contxt @args);

use X11::Fvwm;
use Getopt::Std;

if (grep(($_ eq '-h'), @ARGV))
{
    print STDERR "
-h:        This help message
-s <secs>: Exit after <secs> seconds
-f <file>: Send output to <file> instead of FVWM's stdout
-m <mask>: Show only packets with types in <mask>
-M <mask>: Show only packets with types NOT in <mask>
-c:        Send an initial Send_ConfigInfo packet to FVWM
-w:        Send an initial Send_WindowList packet to FVWM
";
    exit 0;
}

$FVWM = new X11::Fvwm;
($winid, $contxt, @args) = $FVWM->initModule(M_NEW_PAGE | M_NEW_DESK |
                                             M_ADD_WINDOW |
                                             M_CONFIGURE_WINDOW |
                                             M_MINI_ICON |
                                             M_LOWER_WINDOW | M_RAISE_WINDOW |
                                             M_DESTROY_WINDOW |
                                             M_DEICONIFY | M_MAP |
                                             M_FOCUS_CHANGE | M_ICONIFY |
                                             M_ICON_LOCATION | M_WINDOW_NAME |
                                             M_ICON_NAME | M_RES_CLASS |
                                             M_RES_NAME | M_CONFIG_INFO |
                                             M_ERROR | M_END_WINDOWLIST |
                                             M_END_CONFIG_INFO);

@ARGV = @args;
getopts('hs:f:m:M:cw', \%opt);

print "$0 started:\n\t window id $winid\n\t context $contxt\n\t args ",
    join(' ', map { "\"$_\"" } (@args)), "\n";

if (defined $opt{f})
{
    close(STDOUT);
    open(STDOUT, "> $opt{f}");
    select(STDOUT);
    $| = 1;
}

if (defined $opt{'s'})
{
    $SIG{ALRM} = \&Quit;
    alarm $opt{'s'};
}

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
$FVWM->addHandler(M_END_WINDOWLIST | M_END_CONFIG_INFO, \&ListEndConfigInfo);
$FVWM->addHandler(M_MINI_ICON, \&ListMiniIcon);

if (defined $opt{'m'} or defined $opt{M})
{
    my $mask = MAX_MASK;

    $mask &= oct($opt{'m'}) if (defined $opt{'m'});
    $mask &= (oct($opt{M}) ^ MAX_MASK) if (defined $opt{M});

    $FVWM->mask($mask);
}

$FVWM->sendInfo(0, "Send_ConfigInfo") if (defined $opt{c});
$FVWM->sendInfo(0, "Send_WindowList") if (defined $opt{w});

$FVWM->eventLoop;

&Quit;

########################################################################
# Subroutines
########################################################################
sub Quit {
    print "$0 exiting\n";
    $FVWM->endModule;
    exit;
}

# tohex - convert a list of values from decimal to hex
sub tohex {
    map { sprintf("%lX", $_) } (@_);
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

sub ListMiniIcon {
    my ($self, $type, $id, $fid, $ptr, $width, $height, $depth, $pid, $mid,
	$name) = @_;

    ($id, $fid, $ptr, $pid, $mid) = &tohex($id, $fid, $ptr, $pid, $mid);
    
    &showline(<<"END");
MiniIcon:
    Win ID:	$id
    Frame ID:	$fid
    Fvwm ptr:	$ptr
    Width:	$width
    Height:	$height
    Depth:	$depth
    Pixmap ID:	$pid
    Mask ID:	$mid
    Filename:	$name
END

    1;
}

sub showline {
    print STDOUT @_;
}
__END__

=head1 NAME

pDebug - Background packet stream echo utility, written in Perl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 SEE ALSO
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
