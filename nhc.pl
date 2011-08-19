#!/usr/bin/perl
# nhc.pl
# Script that calls bin/nhc and sets it up with the local share dir and lib
# no matter where nhc.pl is called from. Also runs it in a frame-less window.
# This should work without installing as long as you have what the README says

use strict;
use warnings;
use 5.01;

use FindBin ();
use File::Spec ();
use lib File::Spec->catdir($FindBin::Bin, 'lib');
unshift @ARGV, '--share-dir', File::Spec->catdir($FindBin::Bin, 'share'), '--window';
$0 = File::Spec->catfile($FindBin::Bin, 'bin', 'nhc');
require $0;
