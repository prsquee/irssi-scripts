# tinyurl
use strict;
use warnings;
use WWW::Shorten::TinyURL;

sub do_shortme { return makeashorterlink(shift); }
