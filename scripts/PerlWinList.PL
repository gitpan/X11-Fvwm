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

# PerlWinList - small, instructive example of a fvwm module implemented
# in Perl 5.
# Based on code (c)1996 Dan Astoorian <djast@utopia.csas.com>

# Note: This requires X11::Fvwm installed in your @INC path:
use strict;
use X11::Fvwm qw(M_WINDOW_NAME M_END_WINDOWLIST);
use IO::File;

my $fh = new IO::File "> /dev/console";

my $module = new X11::Fvwm;

$module->initModule(M_WINDOW_NAME | M_END_WINDOWLIST);

# Register the event handlers
$module->addHandler(M_WINDOW_NAME,
		    sub {
			my ($self, $type, $id, $frameid, $ptr, $name) = @_;
			printf $fh ("Window ID  %8lx: %s\n", $id, $name);
			# return 1, to signal the event loop to continue
			1;
		    });
# This one returns 0 to signal that it terminates the module.
$module->addHandler(M_END_WINDOWLIST,
		    sub { print $fh "---end of window list\n"; return 0; });

print $fh "---start of window list\n";
# Ask FVWM to send us its list of windows
$module->sendInfo(0, "Send_WindowList");

# Enter the main loop
$module->eventLoop;

# We're done; clean up.
$module->endModule;

exit;
__END__

=head1 NAME

PerlWinList - Simple example of basic X11::Fvwm usage

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

=head1 SEE ALSO
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
