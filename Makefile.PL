# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.5 1997/10/21 21:26:38 rjray Exp $

require 5.003;
use ExtUtils::MakeMaker;
use Carp;
use IO::File;

$FVWM_DIR = '/usr/local/src/fvwm';
$FVWM_MOD_DIR = '/usr/local/lib/X11/fvwm2';

if (@ARGV)
{
    my @args;
    my ($name, $val);

    @args = grep(/^FVWM/, @ARGV);   # Save our args, but
    @ARGV = grep(! /^FVWM/, @ARGV); # let MM handle the rest

    for (@args)
    {
        ($name, $val) = split(/=/, $_, 2);
        $val = 1 unless (defined $val);
        $$name = $val;
    }
}

# This is borrowed almost verbatim from Graham Barr's MailTools package
sub chk_version
{
    my ($pkg, $wanted) = @_;

    $| = 1;
    print "Checking for $pkg...";

    eval { my $p; ($p = $pkg . ".pm") =~ s!::!/!g; require $p; };

    my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
                                    : "not found";
    my $vnum = ${"${pkg}::VERSION"} || 0;

    print $vnum >= $wanted ? "ok\n" : " " . $vstr . "\n";

    $vnum >= $wanted;
}

chk_version(Tk => 400.200) or
    warn "\n\tThe Tk extension (400.200 or newer) was not found. You will\n" .
    "\tnot be able to use Tk as a GUI (via X11::Fvwm::Tk) without it.\n\n";

chk_version(X11::Xforms => 0.7) or
    warn "\n\tThe X11::Xforms extension (0.7 or newer) was not found. You\n" .
    "\twill not be able to use X11::Xforms as a GUI (via X11::Fvwm::Xforms)\n".
    "\twithout it.\n\n";

sub chk_fvwm_version
{
    my ($dir, $need) = @_;

    if (-e "$dir/version.h")
    {
        my $fh = new IO::File "$dir/version.h" or
            croak "Could not open $dir/version.h: $!, stopped";
        while (defined($_ = <$fh>))
        {
            next unless /VERSION "(.*)"/o;
            $_ = $1;
            s/\.//go;          # Squeeze out '.' and we can compare these two
            $need =~ s/\.//go; # numerically.
            if ($need == $_)
            {
                print "Fvwm2 is rooted at $dir and is the correct version\n";
                undef $fh;
                return;
            }
        }
        undef $fh;
        croak "No VERSION definition found in $dir/version.h, stopped";
    }
    else
    {
        croak "Directory $dir is not valid, or Fvwm's version.h could not " .
            "be found, stopped";
    }
}

chk_fvwm_version $FVWM_DIR, "2.0.46";

@DEMO_SCRIPTS = qw(scripts/PerlTkWL  scripts/PerlWinList scripts/PerlTkConsole
                   scripts/PerlDebug scripts/PerlTkDesker);

%PL_SCRIPTS = map { sprintf("%s.PL", $_) => "$_" } @DEMO_SCRIPTS;

WriteMakefile(
              NAME          => 'X11::Fvwm',
              VERSION_FROM  => 'Fvwm.pm',
              LIBS          => [''],
              DEFINE        => '',
              INSTALLSCRIPT => $FVWM_MOD_DIR,
              INC           => '-I$(FVWMSRCDIR)',
              macro         => { 'FVWMSRCDIR' => $FVWM_DIR },
              dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              EXE_FILES     => [@DEMO_SCRIPTS],
              PL_FILES      => \%PL_SCRIPTS,
              PMLIBDIRS     => ['Fvwm'],
              clean => { FILES => join(' ', @DEMO_SCRIPTS) },
              realclean => { FILES => join(' ', @DEMO_SCRIPTS) }
             );

exit 0;
