use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME	    => 'X11::Fvwm',
	      VERSION_FROM  => 'Fvwm.pm',
	      LIBS	    => [''],
	      DEFINE	    => '',
	      INSTALLSCRIPT => '/usr/local/lib/X11/fvwm2',
	      INC	    => '-I$(FVWMSRCDIR)',
	      macro         => { 'FVWMSRCDIR' => '/usr/local/src/fvwm' },
	      dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	      EXE_FILES     => [qw(scripts/PerlWinList scripts/PerlTkWL)],
	     );
