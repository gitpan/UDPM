#!/usr/bin/perl -Tw
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';
use Test::More tests => 31;
BEGIN { use_ok('UDPM') };

#########################

print STDERR "\nRun optional ASCII Interface test suite? (y|n) ";
chomp(my $RESP = <STDIN>);

SKIP: {
  skip "ASCII Interface test suite bypassed.", 30 if $RESP !~ /^(y|ye|yes)$/i;
  my $d = new UDPM ({'backtitle'=>'UDPM: make test',
		     'ascii'=>1,'use_stderr'=>1});
  isa_ok( $d, 'UDPM');
  ok( $d->is_ascii(),"  is_ascii()" );

  my $PRE_N = 'It is normal to see the string "t/2....ok ';
  my $SUF_N = '/31" instead of the regular prompt for this widget.';

  print STDERR "

This is the User Dialog Perl Module ascii widget interface test.

During these tests you will be instucted to enter specific responses
to the displayed widget. It is imperative to follow these instructions
accurately, otherwise the 'make test' will fail.

[PRESS ENTER TO CONTINUE]";
  <STDIN>;

  #: MSGBOX
  ok( !$d->msgbox({'title'=>'msgbox()',
		   'text'=>'Please press the <ENTER> key to continue testing. '.$PRE_N.'4'.$SUF_N}),
      "msgbox test"
    );
  ok( $d->state() eq "OK", "  msgbox state check" );

  #: YESNO
  ok( $d->yesno({'title'=>'yesno()',
		 'text'=>'Please type "yes" and then <ENTER>. '.$PRE_N.'5'.$SUF_N}),
      "yesno test"
    );
  ok( $d->state() eq "OK", "  yesno(1/4) state check" );
  ok( !$d->yesno({'title'=>'yesno()',
		  'text'=>'Please type "no" and then <ENTER>. '.$PRE_N.'7'.$SUF_N}),
      "yesno test"
    );
  ok( $d->state() eq "CANCEL", "  yesno(2/4) state check" );
  ok( $d->noyes({'title'=>'noyes()',
		 'text'=>'Please type "yes" and then <ENTER>. '.$PRE_N.'9'.$SUF_N}),
      "noyes test"
    );
  ok( $d->state() eq "OK", "  yesno(3/4) state check" );
  ok( !$d->noyes({'title'=>'noyes()',
		  'text'=>'Please type "no" and then <ENTER>. '.$PRE_N.'11'.$SUF_N}),
      "noyes test"
    );
  ok( $d->state() eq "CANCEL", "  yesno(4/4) state check" );

  #: INFOBOX
  ok( !$d->infobox({'title'=>'infobox()','sleep'=>3,
		    'text'=>'Please wait 3 seconds. '.$PRE_N.'13'.$SUF_N}),
      "infobox test"
    );
  ok( $d->state() eq "OK", "  infobox state check" );

  #: INPUTBOX
  ok( $d->inputbox({'title'=>'inputbox()','init'=>'INPUT',
		    'text'=>'Please type the (case-sensitive) string "INPUT" and press <ENTER>. '.$PRE_N.'15'.$SUF_N}),
      "inputbox test"
    );
  ok( $d->state() eq "OK", "  inputbox state check" );
  ok( $d->rs() eq "INPUT", "  inputbox value check" );

  #: PASSWORDBOX
  ok( $d->passwordbox({'title'=>'passwordbox()','init'=>'PASSWORD',
		       'text'=>'Please type the (case-sensitive) string "PASSWORD" (hidden by asterisks as you type) and press <ENTER>. '.$PRE_N.'18'.$SUF_N}),
      "passwordbox test"
    );
  ok( $d->state() eq "OK", "  passwordbox state check" );
  ok( $d->rs() eq "PASSWORD", "  passwordbox value check" );

  #: MENU
  my $MENU = ['one','TRUE',
	      'zero','FALSE',
	      'two','BEYOND'];
  ok( $d->menu({'title'=>'menu()','menu'=>$MENU,
		'text'=>'Please type "one" and press <ENTER>. '.$PRE_N.'21'.$SUF_N}),
      "menu test"
    );
  ok( $d->state() eq "OK", "  menu state check" );
  ok( $d->rs() eq "one", "  menu value check" );

  #: RADIOLIST
  my $RADIOLIST = ['one','TRUE','off',
		   'zero','FALSE','on',
		   'two','BEYOND','off'];
  ok( $d->radiolist({'title'=>'radiolist()','menu'=>$RADIOLIST,
		     'text'=>'Please type "zero" and press <ENTER>. '.$PRE_N.'24'.$SUF_N}),
      "radiolist test"
    );
  ok( $d->state() eq "OK", "  radiolist state check" );
  ok( $d->rs() eq "zero", "  radiolist value check" );

  #: CHECKLIST
  my $CHECKLIST = ['one','TRUE','on',
		   'zero','FALSE','off',
		   'two','BEYOND','on'];
  ok( $d->checklist({'title'=>'checklist()','menu'=>$CHECKLIST,
		     'text'=>'Please type "one two" and press <ENTER>. '.$PRE_N.'27'.$SUF_N}),
      "radiolist test"
    );
  ok( $d->state() eq "OK", "  checklist state check" );
  my @return_array = $d->ra();
  foreach my $elem (@return_array) {
    ok( grep { /\Q$elem\E/ } @{$CHECKLIST}, "  checklist value check" );
  }

}
