#!/usr/bin/perl -Tw
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More 'no_plan';
use Test::More tests => 178;
BEGIN { use_ok('UDPM') };

#########################

my $ATTRS = {'scalar'=>{'title'=>undef(),
			'backtitle'=>'UDPM: make test',
			'text'=>undef(),
			'height'=>18,
			'width'=>76,
			'menu-height'=>3,
			'list-height'=>3,
			'defaultno'=>0,
			'aspect'=>9,
			'beep'=>0,
			'beep-after'=>0,
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
		       },
	     'array'=>{'begin'=>'ref',
		       'envpaths'=>['/bin/','/usr/bin','/usr/local/bin'],
		       'variants'=>['dialog','whiptail'],
		       'gui-variants'=>['gdialog','kdialog'],
		      },
	     'misc'=>{'auto-clear'=>0,
		      'auto-scale'=>0,
		      'max-scale'=>76,
		      'dialogrc'=>undef(),
		      'pager'=>'/usr/bin/pager',
		      'tail'=>'/usr/bin/tail',
		      'tailopt'=>'-f',
		      'tmpdir'=>'/tmp'
		     }
		 };

my @METHODS = qw( new __CAT_ONCE __TEST_VARIANTS __WHICH_DIALOG __debug_this
                  __GET_DIR __TRANSLATE __TRANSLATE_FILTER __TRANSLATE_CLEAN
                  __TEST_MENU_ARGS __TEST_LIST_ARGS __ASCII_NAV_HELP __ASCII_BUTTONS
                  __ASCII_WRITE_TEXT __ASCII_WRITE_MENU __ASCII_WRITE_LIST __CLEAR
                  __CALLBACKS __BEEP __CLEAN_ATTRS __GET_ATTR_STR __RUN_DIALOG
                  __CLEAN_RVALUES is_attr attribute is_linux is_bsd is_ascii
                  is_cdialog is_gdialog is_kdialog is_dialog is_whiptail
                  __ATTRIBUTE nautilus_paths nautilus_uris nautilus_path
                  nautilus_uri nautilus_geometry nautilus_debug state rv rs ra
                  clear yesno noyes __ascii_yesno __dialog_yesno msgbox
                  __ascii_msgbox __dialog_msgbox infobox __ascii_infobox
                  __dialog_infobox inputbox __ascii_inputbox __dialog_inputbox
                  passwordbox __ascii_passwordbox __dialog_passwordbox textbox
                  __ascii_textbox __dialog_textbox menu __ascii_menu
                  __dialog_menu radiolist __ascii_radiolist __dialog_radiolist
                  checklist __ascii_checklist __dialog_checklist calendar
                  __dialog_calendar fselect __cdialog_fselect __dialog_fselect
                  tailbox __ascii_tailbox __dialog_tailbox timebox __dialog_timebox
                  start_gauge msg_gauge inc_gauge dec_gauge end_gauge ascii_spinner
		);

my $d = new UDPM ({'backtitle'=>'UDPM: make test','ascii'=>1});
isa_ok( $d, 'UDPM');

ok( $d->is_ascii(),"  is_ascii()" );

foreach my $attr (sort(keys(%{$ATTRS->{'scalar'}}))) {
  ok( $d->is_attr($attr), "  scalar: is_attr('$attr')" );
  is( $d->attribute($attr), $ATTRS->{'scalar'}{$attr}, "  scalar: attribute('$attr')" );
}

foreach my $attr (sort(keys(%{$ATTRS->{'array'}}))) {
  ok( ref($d->{'clone'}{$attr}), "  arrayref: is ref" );
  if ($ATTRS->{'array'}{$attr} eq 'ref') {
    ok( !@{$d->{$attr}},  "  arrayref: is empty" );
  } else {
    for (my $i = 0; $i < @{$d->{'clone'}{$attr}}; $i++) {
      is( $d->{'clone'}{$attr}->[$i], $ATTRS->{'array'}{$attr}[$i],
	  "  arrayref_elem: '".($d->{'clone'}{$attr}[$i]||'')."' eq '".($ATTRS->{'array'}{$attr}[$i]||'')."'" );
    }
  }
}

foreach my $meth (sort(@METHODS)) { can_ok($d,$meth); }

