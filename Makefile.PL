# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.2 1997/04/30 18:04:34 rjray Exp $

require 5.002;
use ExtUtils::MakeMaker;

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

$NAME     = 'X11::Fvwm';
$VERSION  = '0.3';

chk_version(Tk => 400.200) or
    warn "\n\tThe Tk extension (400.200 or newer) was not found. You will\n" .
    "\tnot be able to use Tk as a GUI (via X11::Fvwm::Tk) without it.\n\n";

chk_version(X11::Xforms => 0.7) or
    warn "\n\tThe X11::Xforms extension (0.7 or newer) was not found. You\n" .
    "\twill not be able to use X11::Xforms as a GUI (via X11::Fvwm::Xforms)\n".
    "\twithout it.\n\n";

@DEMO_SCRIPTS = qw(scripts/PerlTkWL scripts/PerlWinList scripts/TkPerlConsole
                   scripts/pDebug);

%PL_SCRIPTS = map { sprintf("%s.PL", $_) => "$_" } @DEMO_SCRIPTS;

WriteMakefile(
              NAME          => $NAME,
              VERSION       => $VERSION,
              LIBS          => [''],
              DEFINE        => '',
              INSTALLSCRIPT => '/usr/local/lib/X11/fvwm2',
              INC           => '-I$(FVWMSRCDIR)',
              macro         => { 'FVWMSRCDIR' => '/usr/local/src/fvwm' },
              dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              EXE_FILES     => [@DEMO_SCRIPTS],
              PL_FILES      => \%PL_SCRIPTS,
              PMLIBDIRS     => ['Fvwm'],
              clean => { FILES => join(' ', @DEMO_SCRIPTS) },
              realclean => { FILES => join(' ', @DEMO_SCRIPTS) }
             );

exit 0;
