# This -*- perl -*- script makes the Makefile
# $Id: Makefile.PL,v 1.1 1997/03/29 01:08:44 rjray Exp $

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
$VERSION  = '0.2';

chk_version(Tk => 400.200) or
    warn "\nThe Tk extension was not found. You will not be able to use Tk\n" .
         "as a GUI (via X11::Fvwm::Tk) without it.\n\n";

# chk_version(Xforms => 0.5) or
#     warn "\nThe Xforms extension was not found. You will not be able to use\n".
#          "Xforms as a GUI (via X11::Fvwm::Xforms) without it.\n\n";

@DEMO_SCRIPTS = qw(scripts/PerlTkWL scripts/PerlWinList);

%PL_SCRIPTS = map { sprintf("%s.PL", $_) => "$_" } @DEMO_SCRIPTS;

WriteMakefile(
	      NAME	    => $NAME,
	      VERSION       => $VERSION,
              LIBS          => [''],
              DEFINE        => '',
              INSTALLSCRIPT => '/usr/local/lib/X11/fvwm2',
              INC           => '-I$(FVWMSRCDIR)',
              macro         => { 'FVWMSRCDIR' => '/usr/local/src/fvwm' },
              dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
              EXE_FILES     => [@DEMO_SCRIPTS],
              PL_FILES      => \%PL_SCRIPTS,
              clean => { FILES => join(' ', @DEMO_SCRIPTS) },
              realclean => { FILES => join(' ', @DEMO_SCRIPTS) }
             );

exit 0;
