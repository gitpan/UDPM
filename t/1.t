#!/usr/bin/perl -Tw
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';
use Test::More tests => 118;
BEGIN { use_ok('UDPM') };

#########################

my $ATTRS = { 'title'=>'Test',
	      'backtitle'=>'CPAN',
	      'height'=>10,
	      'width'=>40,
	      'menu-height'=>3,
	      'list-height'=>3,
	      'defaultno'=>0,
	      'aspect'=>9,
	      'beep'=>0,
	      'beep-after'=>0,
#	      'begin'=>[],
	      'cancel-label'=>undef(),
	      'clear'=>0,
	      'colours'=>0,
	      'cr-wrap'=>0,
	      'default-item'=>undef(),
	      'exit-label'=>undef(),
	      'extra-button'=>0,
	      'extra-label'=>undef(),
	      'help-button'=>0,
	      'help-label'=>undef(),
	      'ignore'=>0,
	      'item-help'=>0,
	      'max-input'=>2000,
	      'nocancel'=>0,
	      'no-collapse'=>0,
	      'no-shadow'=>0,
	      'ok-label'=>undef(),
	      'shadow'=>0,
	      'sleep'=>0,
	      'tab-correct'=>0,
	      'tab-len'=>undef(),
	      'timeout'=>undef(),
	      'trim'=>0,
	      'fb'=>0,
	      'scrolltext'=>0,
	      'noitem'=>0,
	    };

my @METHODS = qw( new state rv rs ra attribute
		  is_attr is_linux is_bsd
		  is_ascii is_dialog is_cdialog is_whiptail is_gdialog is_kdialog
		  clear infobox msgbox textbox yesno noyes inputbox passwordbox
		  menu radiolist checklist start_gauge msg_gauge inc_gauge dec_gauge
		  set_gauge end_gauge tailbox fselect timebox calendar ascii_spinner
		  nautilus_paths nautilus_path nautilus_uris nautilus_uri
		  nautilus_geometry nautilus_debug
		);

my $d = new UDPM ({'ascii'=>1,'title'=>'Test','backtitle'=>'CPAN'});
isa_ok( $d, 'UDPM');

ok( $d->is_ascii(),"  is_ascii()" );

foreach my $attr (sort(keys(%{$ATTRS}))) {
  ok( $d->is_attr($attr),	"  is_attr('$attr')");
  is( $d->attribute($attr), $ATTRS->{$attr}, "  attribute('$attr')");
}

foreach my $meth (sort(@METHODS)) { can_ok($d,$meth); }

