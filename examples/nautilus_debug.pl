#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use UDPM;


chomp(my $DIALOG = `/usr/bin/which gdialog`);
if (!-x $DIALOG) {
  chomp($DIALOG = `/usr/bin/which kdialog`);
  if (!-x $DIALOG) {
    print STDERR "Couldn't find a suitable gui-based dialog variant\n";
    exit(1);
  }
}

my $d = new UDPM ({'backtitle'=>'UDPM "Nautilus" Debug ('.$UDPM::VERSION.')',
		   'beep'=>0,'dialogbin'=>$DIALOG });

$d->nautilus_debug();

exit(0);
