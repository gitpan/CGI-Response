use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME => "CGI::Response",
	      DISTNAME => "CGI-Response",
	      linkext => {
		LINKTYPE => '', # not needed for MakeMakers >= 5
	      }, 
	      VERSION => "0.03",
	      dist => {
		COMPRESS=>'gzip -9f', 
		SUFFIX=>'gz',
	      },
);
