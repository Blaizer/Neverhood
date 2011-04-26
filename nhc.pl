#!/usr/bin/perl
# nhc.pl
# Script that calls bin/nhc and sets it up with the local share dir and lib
# no matter where nhc.pl is called from. Also runs it in a frame-less window.
# You need not install Neverhood to run the game with this script.

use strict;
use warnings;
use 5.01;

use FindBin ();
use File::Spec ();
use lib File::Spec->catdir($FindBin::Bin, 'lib');
unshift @ARGV, '--share-dir', File::Spec->catdir($FindBin::Bin, 'share'), '--window';
$0 = File::Spec->catfile($FindBin::Bin, 'bin', 'nhc');
require $0;
