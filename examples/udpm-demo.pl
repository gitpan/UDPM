#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use lib ".";
use UDPM;


# Try uncommenting the variaous 'dialogbin' lines to see how this
# script works with the different dialog variants. This is my
# "test-every-feature-possible" script.

my $d = new UDPM ({'colours'=>1,'cr-wrap'=>1,'no-shadow'=>1,'auto-clear'=>0,'auto-scale'=>1,
		   'height'=>22,'ascii'=>0,'max-scale'=>79,'backtitle'=>'UDPM Demo ('.$UDPM::VERSION.')',
		   'ESC-SUB'=>\&ESC,'CANCEL-SUB'=>\&CANCEL,'EXTRA-SUB'=>\&EXTRA,'HELP-SUB'=>\&HELP,
#		   'beep'=>undef,
#		   'dialogbin'=>'/usr/bin/dialog'
#		   'dialogbin'=>'/usr/bin/whiptail'
#		   'dialogbin'=>'/usr/bin/gdialog'
#		   'dialogbin'=>'/usr/bin/kdialog'
		  });
my $d2 = new UDPM ({'colours'=>1,'cr-wrap'=>1,'no-shadow'=>1,'auto-clear'=>0,'auto-scale'=>1,
		   'height'=>22,'ascii'=>0,'max-scale'=>79,'backtitle'=>'UDPM Callback Demo ('.$UDPM::VERSION.')',
#		   'beep'=>undef,
#		   'dialogbin'=>'/usr/bin/dialog'
#		   'dialogbin'=>'/usr/bin/whiptail'
#		   'dialogbin'=>'/usr/bin/gdialog'
#		   'dialogbin'=>'/usr/bin/kdialog'
		  });


sub HELP {
  $d2->infobox({'title'=>'HELP','sleep'=>2,'text'=>'this is a coderef being executed because you pressed <help>!'});
}
sub EXTRA {
  $d2->infobox({'title'=>'EXTRA','sleep'=>2,'text'=>'this is a coderef being executed because you pressed <extra>!'});
}
sub ESC {
  $d2->infobox({'title'=>'ESC','sleep'=>2,'text'=>'this is a coderef being executed because you pressed <esc>!'});
}
sub CANCEL {
  $d2->infobox({'title'=>'CANCEL','sleep'=>2,'text'=>'this is a coderef being executed because you pressed <cancel>!'});
}

# I un-comment this when debbuging the list widgets...
#WALKTHROUGH(); exit();

$d->msgbox({'title'=>'msgbox widget','beep'=>1,
	    'text'=>'[B]Welcome[/B] to a [u]demo[/u] of [c=blue]UDPM::Dialog[c=white].'});


#
#
# this is where it all really happens...
#
#

my $m = "NOT_EXIT";
while ($m ne "Exit") {

  # our main menu...
  $m = $d->menu({'title'=>'menu widget',
		 'text'=>'select:', 'list-height'=>15, 'height'=>25, 'nocancel'=>1,
		 'help-button'=>1, 'extra-button'=>1, 'extra-label'=>'Test',
		 'menu'=>['1','checklist',
			  '2','yesno',
			  '3','infobox',
			  '4','msgbox',
			  '5','inputbox',
			  '6','passwordbox',
			  '7','calendar',
			  '8','timebox',
			  '9','textbox',
			  '10','tailbox',
			  '11','gauge',
			  '12','fselect',
			  '13','radiolist',
			  'Exit','quit the demo'
			 ]
		});

  # did they want application specific help?
  if ($d->state() eq "HELP") {

    $d->msgbox({'title'=>'help','text'=>['Select from the list or ',
					 'hit the "Test" button to',
					 'run a walk through.']});

  # did they press the ESC button?
  } elsif ($d->state() eq "ESC") {

    $d->msgbox({'title'=>'escape','text'=>['You pressed the "ESC" button!','Exiting now!']});
    $d->clear();
    exit();

  # did the press the Extra button?
  # for the end-user they saw a "Test" button but in our scipting
  # we're looking for an rv() of 3 or a state() of "EXTRA"
  } elsif ($d->state() eq "EXTRA") {

    # let's do a massive walkthrough of all the widgets

    $d->clear();
    $d->infobox({'title'=>'msgbox widget','sleep'=>2,'text'=>["This is a demo for the User Dialog Perl Module."]});

    $d->msgbox({'title'=>'msgbox widget',
		'text'=>["[B]BOLD[/B]","[U]UNDERLINE[/U]","[R]REVERSED[/R]",
			 "[c=black]black[n] [c=red]red[n] [c=blue]blue[n]"]}) if ($d->is_cdialog());
    $d->msgbox({'title'=>'msgbox widget','width'=>'60',
		'text'=>["[a=left]Left align","[a=center]Center align","[a=right]Right align"]});

    $d->textbox({'title'=>'textbox widget',
		 'file'=>$0});

    $d->tailbox({'title'=>'tailbox','file'=>$0});

    if ($d->yesno({'title'=>'yesno','text'=>"Yes? No? (default yes)"})) {
      $d->msgbox({'title'=>'msgbox widget','text'=>'you selected YES'});
    } else {
      $d->msgbox({'title'=>'msgbox widget','text'=>'you selected NO'});
    }

    if ($d->noyes({'title'=>'noyes','text'=>"Yes? No? (default no)"})) {
      $d->msgbox({'title'=>'msgbox widget','text'=>'you selected YES'});
    } else {
      $d->msgbox({'title'=>'msgbox widget','text'=>'you selected NO'});
    }

    my $s = $d->inputbox({'title'=>'inputbox','text'=>'enter some text'});
    $d->msgbox({'title'=>'msgbox widget','text'=>'you entered: '.($s||' ')});

    if (!$d->is_gdialog() && !$d->is_kdialog()) {
      my $p = $d->passwordbox({'title'=>'passwordbox','text'=>'enter a fake password:'});
      $d->msgbox({'title'=>'msgbox widget','text'=>'you entered: '.$p});
    } else {
      $d->msgbox({'title'=>'msgbox widget','text'=>'passwordbox not supported by (g|k)dialog.'});
    }

    WALKTHROUGH();

    if (!$d->is_gdialog() && !$d->is_kdialog() && !$d->is_ascii()) {
      $d->start_gauge({'title'=>'gauge','text'=>'initial text','percent'=>10});
      sleep(1);
      $d->set_gauge(25);
      sleep(1);
      for (1 .. 10) { $d->inc_gauge(3); }
      sleep(1);
      $d->msg_gauge("msg_gauge: updated text area...");
      sleep(1);
      $d->set_gauge(100);
      sleep(1);
      $d->set_gauge(50);
      sleep(1);
      $d->end_gauge();
    }



    my $file = $d->fselect({'title'=>'fselect','path'=>"/",'height'=>20,'list-height'=>12});
    $d->msgbox({'title'=>'msgbox widget','text'=>'you selected: '.$file});

    if ($d->is_cdialog()) {
      if ($d->noyes({'title'=>'noyes','text'=>"test cdialog's advanced widgets?"})) {
	my ($hour,$minute,$second) = $d->timebox({'title'=>'timebox','text'=>'select a time:'});
	$d->msgbox({'title'=>'msgbox widget','text'=>'hour: '.$hour.' minute: '.$minute.' second: '.$second});
	my ($day,$month,$year) = $d->calendar({'title'=>'calendar','text'=>'select a date:'});
	$d->msgbox({'title'=>'msgbox widget','text'=>'day: '.$day.' month: '.$month.' year: '.$year});
      }
    }

    $d->msgbox({'title'=>'msgbox widget','text'=>["I [r]hope[/r] you've [b]enjoyed[/b] this little tour!",
					   "Remeber to send feedback to [u]Kevin C. Krinke <kckrinke\@opendoorsoftware.com>[/u]"]});

  # did they actually pick something form the list?
  } elsif ($d->state() eq "OK") {

    if ($m eq "1") {
      my @l = $d->checklist({'title'=>'checklist widget',
			     'text'=>'select some things',
			     'menu'=>['tag1','description one','off',
				      'tag2','description two','off',
				      'tag3','description three','on'
				     ]
			    });
      $d->infobox({'title'=>'infobox widget','sleep'=>2,
		   'text'=>'you selected: "'.join('" "',@l).'"'});

    } elsif ($m eq "2") {

      if ($d->yesno({'text'=>'yes or no?'})) {
	$d->infobox({'title'=>'infobox widget','sleep'=>2,
		     'text'=>'yes!'});
      } else {
	$d->infobox({'title'=>'infobox widget','sleep'=>2,
		     'text'=>'no!'});
      }

    } elsif ($m eq "3") {

      $d->infobox({'title'=>'infobox widget', 'sleep'=>3,
		   'text'=>'This is an infobox. This will sleep for 3 seconds.'});

    } elsif ($m eq "4") {

      $d->msgbox({'title'=>'msgbox widget',
		  'text'=>'this is a message.'});

    } elsif ($m eq "5") {

      my $s = $d->inputbox({'title'=>'inputbox widget',
			    'text'=>'enter some text...'});
      $d->infobox({'title'=>'infobox widget','sleep'=>1,
		   'text'=>'you entered in: "'.$s.'"'});

    } elsif ($m eq "6") {

      if (!$d->is_gdialog() && !$d->is_kdialog()) {
	my $p = $d->passwordbox({'title'=>'passwordbox widget',
				 'text'=>'notice nothing as you type...'});
	$d->infobox({'title'=>'infobox widget','sleep'=>1,
		     'text'=>'you entered in: "'.$p.'"'});
      } else {
	$d->msgbox({'title'=>'msgbox widget','text'=>'passwordbox not supported by (g|k)dialog.'});
      }

    } elsif ($m eq "7") {

      my @date = $d->calendar({'title'=>'calendar widget'});
      $d->infobox({'title'=>'infobox widget','sleep'=>1,
		   'text'=>'you entered: '.join(' ',@date)});

    } elsif ($m eq "8") {

      my @time = $d->timebox({'title'=>'timebox widget'});
      $d->infobox({'title'=>'infobox widget','sleep'=>1,
		   'text'=>'you entered: '.join(' ',@time)});

    } elsif ($m eq "9") {

      $d->textbox({'title'=>'textbox widget',
		   'file'=>$0});

    } elsif ($m eq "10") {

      $d->tailbox({'title'=>'tailbox widget',
		   'file'=>$0});

    } elsif ($m eq "11") {

      $d->start_gauge({'text'=>'stage one','title'=>'gauge widget'});
      $d->set_gauge(20);
      sleep(1);
      for (21 .. 50) { $d->inc_gauge(1); }
      sleep(1);
      for (21 .. 31) { $d->dec_gauge(1); }
      sleep(1);
      $d->msg_gauge("stage two");
      $d->set_gauge(80);
      $d->msg_gauge("stage three");
      $d->end_gauge();

    } elsif ($m eq "12") {

      my $path = $d->fselect({'title'=>'fselect widget','height'=>22,'list-height'=>12,
			      'path'=>'./'});
      $d->infobox({'title'=>'infobox widget','sleep'=>2,
		   'text'=>'you selected: "'.$path.'"'});

    } elsif ($m eq "13") {
      my @l = $d->radiolist({'title'=>'checklist widget',
			     'text'=>'select some things',
			     'menu'=>['tag1','description one','off',
				      'tag2','description two','on',
				      'tag3','description three','off'
				     ]
			    });
      $d->infobox({'title'=>'infobox widget','sleep'=>2,
		   'text'=>'you selected: "'.join('" "',@l).'"'});

    }
  }
}

exit();

# This walkthrough function serves only to make debugging easier for
# the various list widgets.

sub WALKTHROUGH {
# here's a massive list to help demonstrate how the variants handle
# the extremeties.
my $list = ['01','one','off',		'02','two','on',	'03','three','off',
	    '04','four','off',		'05','five','on',	'06','six','off',
	    '07','seven','off',		'08','eight','on',	'09','nine','off',
	    '10','ten','off',		'11','one','off',	'12','two','on',
	    '13','three','off', 	'14','four','off',	'15','five','on',
	    '16','six','off',   	'17','seven','off',	'18','eight','on',
	    '19','nine','off',  	'20','ten','off',	'21','one','off',
	    '22','two','on',		'23','three','off',	'24','four','off',
	    '25','five','on',		'26','six','off',	'27','seven','off',
	    '28','eight','on',		'29','nine','off',	'30','ten','off',

	    '31','one','off',   	'32','two','on',	'33','three','off',
	    '34','four','off',		'35','five','on',	'36','six','off',
	    '37','seven','off',		'38','eight','on',	'39','nine','off',
	    '40','ten','off',		'41','one','off',	'42','two','on',
	    '43','three','off',		'44','four','off',	'45','five','on',
	    '46','six','off',		'47','seven','off',	'48','eight','on',
	    '49','nine','off',		'50','ten','off',	'51','one','off',
	    '52','two','on',		'53','three','off',	'54','four','off',
	    '55','five','on',		'56','six','off',	'57','seven','off',
	    '58','eight','on',		'59','nine','off',	'60','ten','off',

	    '61','one','off',   	'62','two','on',	'63','three','off',
	    '64','four','off',		'65','five','on',	'66','six','off',
	    '67','seven','off',		'68','eight','on',	'69','nine','off',
	    '70','ten','off',		'71','one','off',	'72','two','on',
	    '73','three','off',		'74','four','off',	'75','five','on',
	    '76','six','off',		'77','seven','off',	'78','eight','on',
	    '79','nine','off',		'80','ten','off',	'81','one','off',
	    '82','two','on',		'83','three','off',	'84','four','off',
	    '85','five','on',		'86','six','off',	'87','seven','off',
	    '88','eight','on',		'89','nine','off',	'90','ten','off',

	    '91','one','off',   	'92','two','on',	'93','three','off',
	    '94','four','off',		'95','five','on',	'96','six','off',
	    '97','seven','off',		'98','eight','on',	'99','nine','off',
	    '100','ten','off',		'101','one','off',	'102','two','on',
	    '103','three','off',	'104','four','off',	'105','five','on',
	    '106','six','off',		'107','seven','off',	'108','eight','on',
	    '109','nine','off',		'100','ten','off',	'101','one','off',
	    '102','two','on',		'103','three','off',	'104','four','off',
	    '105','five','on',		'106','six','off',	'107','seven','off',
	    '108','eight','on',		'109','nine','off',	'110','ten','off',

	   ];

my $menu = ['01','one',		'02','two',	'03','three',
	    '04','four',	'05','five',	'06','six',
	    '07','seven',	'08','eight',	'09','nine',
	    '10','ten',		'11','one',	'12','two',
	    '13','three', 	'14','four',	'15','five',
	    '16','six',   	'17','seven',	'18','eight',
	    '19','nine',  	'20','ten',	'21','one',
	    '22','two',		'23','three',	'24','four',
	    '25','five',	'26','six',	'27','seven',
	    '28','eight',	'29','nine',	'30','ten',

	    '31','one',   	'32','two',	'33','three',
	    '34','four',	'35','five',	'36','six',
	    '37','seven',	'38','eight',	'39','nine',
	    '40','ten',		'41','one',	'42','two',
	    '43','three',	'44','four',	'45','five',
	    '46','six',		'47','seven',	'48','eight',
	    '49','nine',	'50','ten',	'51','one',
	    '52','two',		'53','three',	'54','four',
	    '55','five',	'56','six',	'57','seven',
	    '58','eight',	'59','nine',	'60','ten',

	    '61','one',   	'62','two',	'63','three',
	    '64','four',	'65','five',	'66','six',
	    '67','seven',	'68','eight',	'69','nine',
	    '70','ten',		'71','one',	'72','two',
	    '73','three',	'74','four',	'75','five',
	    '76','six',		'77','seven',	'78','eight',
	    '79','nine',	'80','ten',	'81','one',
	    '82','two',		'83','three',	'84','four',
	    '85','five',	'86','six',	'87','seven',
	    '88','eight',	'89','nine',	'90','ten',

	    '91','one',   	'92','two',	'93','three',
	    '94','four',	'95','five',	'96','six',
	    '97','seven',	'98','eight',	'99','nine',
	    '100','ten',	'101','one',	'102','two',
	    '103','three',	'104','four',	'105','five',
	    '106','six',	'107','seven',	'108','eight',
	    '109','nine',	'100','ten',	'101','one',
	    '102','two',	'103','three',	'104','four',
	    '105','five',	'106','six',	'107','seven',
	    '108','eight',	'109','nine',	'110','ten',

	   ];
  if ($d->noyes({'title'=>'noyes() widget',
		 'text'=>'test the error handling of menu/list based widgets?'})) {
    $d->menu({'title'=>'menu','text'=>'valid (list)','list'=>['1','one','2','two']});
    $d->menu({'title'=>'menu','text'=>'valid (menu)','menu'=>['1','one','2','two']});
    $d->checklist({'title'=>'checklist','text'=>'valid (menu)','menu'=>['1','one','off','2','two','off']});
    $d->checklist({'title'=>'checklist','text'=>'valid (list)','list'=>['1','one','off','2','two','off']});
    #And this is silently invalid:
    $d->menu({'title'=>'menu','text'=>'silently invalid','menu'=>['1','one','off','2','two','off']});
    #And these are invalid with a msgbox displaying an error message:
    $d->menu({'title'=>'menu','text'=>'flat out invalid','list'=>['1','one','2','two','3']});
    $d->checklist({'title'=>'menu','text'=>'flat out invalid','menu'=>['1','one','ogg','2','two','3']});
  }

  if ($d->noyes({'title'=>'noyes() widget',
		 'text'=>'test the menu, radiolist and checklist with '.
		 '_large_ numbers of menu entries?'})) {
    my $m = $d->menu({'title'=>'menu',
		      'text'=>'select:',
		      'menu'=>$menu});
    $d->msgbox({'title'=>'msgbox widget','text'=>'you selected: '.$m});
    my $r = $d->radiolist({'title'=>'radiolist',
			   'text'=>'select:',
			   'menu'=>$list});
    $d->msgbox({'title'=>'msgbox widget','text'=>'you selected: '.$r});
    my @c = $d->checklist({'title'=>'checklist',
			   'text'=>'select more than one:',
			   'menu'=>$list});
    $d->msgbox({'title'=>'msgbox widget',
		'text'=>"you selected: @c"});
  } else {
    my $m = $d->menu({'title'=>'menu',
		      'text'=>'select:',
		      'menu'=>['1','desc. for one',
			       '2','desc. for two',
			       '3','desc. for three']});
    $d->msgbox({'title'=>'msgbox widget','text'=>'you selected: '.$m});
    my $r = $d->radiolist({'title'=>'radiolist',
			   'text'=>'select:',
			   'menu'=>['1','desc. for one','off',
				    '2','desc. for two','on',
				    '3','desc. for three','off']});
    $d->msgbox({'title'=>'msgbox widget','text'=>'you selected: '.$r});
    my @c = $d->checklist({'title'=>'checklist',
			   'text'=>'select more than one:',
			   'menu'=>['1','desc. for one','on',
				    '2','desc. for two','on',
				    '3','desc. for three','off']});
    $d->msgbox({'title'=>'msgbox widget',
		'text'=>"you selected: @c"});
  }

}
