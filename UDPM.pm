package UDPM;

use 5.006;
use strict;
use warnings;
use diagnostics;
use FileHandle;
use File::Basename;
use Cwd 'abs_path';
use Carp;

our $VERSION = '0.88';

#
# TODO:
# o tailboxbg() support
#

#
# Please read the POD for copyright and licensing issues.
#

BEGIN { use vars qw($VERSION); }

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Class (internal) Constants
#:

my $ATTRIBUTES = [ 'title',
		   'backtitle',
		   'text',
		   'height',
		   'width',
		   'menu-height',
		   'list-height',
		   'defaultno',
		   'aspect',
		   'beep',
		   'beep-after',
		   'begin',
		   'cancel-label',
		   'clear',
		   'colours',
		   'cr-wrap',
		   'default-item',
		   'exit-label',
		   'extra-button',
		   'extra-label',
		   'help-button',
		   'help-label',
		   'ignore',
		   'item-help',
		   'max-input',
		   'nocancel',
		   'no-collapse',
		   'no-shadow',
		   'ok-label',
		   'shadow',
		   'sleep',
		   'tab-correct',
		   'tab-len',
		   'timeout',
		   'trim',
		   'fb',
		   'scrolltext',
		   'noitem'
		 ];


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Constructor Method
#:

sub new {
  my $proto = shift();
  my $class = ref($proto) || $proto;
  my $cfg = shift() || {};
  my $self = {};
  bless($self, $class);

  $self->{'dialogrc'}		= $cfg->{'dialogrc'}		|| undef();
  $self->{'dialogbin'}		= $cfg->{'dialogbin'}		|| undef();
  $self->{'sttybin'}		= $cfg->{'sttybin'}		|| '/bin/stty';
  $self->{'envpaths'}		= $cfg->{'envpaths'}		|| ['/bin/','/usr/bin','/usr/local/bin'];
  $self->{'variants'}		= $cfg->{'variants'}		|| ['dialog','whiptail'];
  $self->{'gui-variants'}	= $cfg->{'gui-variants'}	|| ['gdialog','kdialog'];
  $self->{'gui'}		= $cfg->{'gui'}			|| 0;
  $self->{'ascii'}		= $cfg->{'ascii'}		|| 0;
  $self->{'auto-clear'}		= $cfg->{'auto-clear'}		|| 0;
  $self->{'auto-scale'}		= $cfg->{'auto-scale'}		|| 0;
  $self->{'max-scale'}		= $cfg->{'max-scale'}		|| 76;
  $self->{'pager'}		= $cfg->{'pager'}		|| '/usr/bin/pager';
  $self->{'tail'}		= $cfg->{'tail'}		|| '/usr/bin/tail';
  $self->{'tailopt'}		= $cfg->{'tailopt'}		|| '-f';
  $self->{'tmpdir'}		= $cfg->{'tmpdir'}		|| '/tmp';
  $self->{'use_stderr'}		= $cfg->{'use_stderr'}		|| 0;

  $self->__WHICH_DIALOG();
  $self->{'dialog'} = "DIALOGRC=".$self->{'dialogrc'}." ".$self->{'dialog'}
   if $self->{'dialogrc'} and $self->is_cdialog();

  if ($self->is_cdialog()) {
    chomp(my $str = `$self->{'dialog'} --stdout --print-maxsize 2> /dev/null`);
    if ($str =~ /MaxSize\: (\d+), (\d+)$/i) { $self->{'max-scale'} = $2 - 5; }
  }

  $self->{'title'}		= $cfg->{'title'}		|| undef();
  $self->{'backtitle'}		= $cfg->{'backtitle'}		|| undef();
  $self->{'height'}		= $cfg->{'height'}		|| 18;
  $self->{'width'} 		= $cfg->{'width'}		|| 76;
  $self->{'list-height'}	= ($cfg->{'list-height'}||$cfg->{'menu-height'}) || 3;
  $self->{'menu-height'}	= ($cfg->{'menu-height'}||$cfg->{'list-height'}) || 3;
  $self->{'defaultno'}		= $cfg->{'defaultno'}		|| 0;
  $self->{'aspect'}		= $cfg->{'aspect'}		|| 9;
  $self->{'beep'}		= $cfg->{'beep'}		|| 0;
  $self->{'beep-after'}		= $cfg->{'beep-after'}		|| 0;
  $self->{'begin'}		= $cfg->{'begin'}		|| [];
  $self->{'cancel-label'}	= $cfg->{'cancel-label'}	|| undef();
  $self->{'clear'}		= $cfg->{'clear'}		|| 0;
  $self->{'colours'}		= ($cfg->{'colours'} || $cfg->{'colors'} || $cfg->{'colour'} || $cfg->{'color'}) || 0;
  $self->{'cr-wrap'}		= $cfg->{'cr-wrap'}		|| 0;
  $self->{'default-item'}	= $cfg->{'default-item'}	|| undef();
  $self->{'exit-label'}		= $cfg->{'exit-label'}		|| undef();
  $self->{'extra-button'}	= $cfg->{'extra-button'}	|| 0;
  $self->{'extra-label'}	= $cfg->{'extra-label'}		|| undef();
  $self->{'help-button'}	= $cfg->{'help-button'}		|| 0;
  $self->{'help-label'}		= $cfg->{'help-label'}		|| undef();
  $self->{'ignore'}		= $cfg->{'ignore'}		|| 0;
  $self->{'item-help'}		= $cfg->{'item-help'}		|| 0;
  $self->{'max-input'}		= $cfg->{'max-input'}		|| 2000;
  $self->{'nocancel'}		= ($cfg->{'nocancel'} || $cfg->{'no-cancel'}) || 0;
  $self->{'no-collapse'}	= $cfg->{'no-collapse'}		|| 0;
  $self->{'no-shadow'}		= $cfg->{'no-shadow'}		|| 0;
  $self->{'ok-label'}		= $cfg->{'ok-label'}		|| undef();
  $self->{'shadow'}		= $cfg->{'shadow'}		|| 0;
  $self->{'sleep'}		= $cfg->{'sleep'}		|| 0;
  $self->{'tab-correct'}	= $cfg->{'tab-correct'}		|| 0;
  $self->{'tab-len'}		= $cfg->{'tab-len'}		|| undef();
  $self->{'timeout'}		= $cfg->{'timeout'}		|| undef();
  $self->{'trim'}		= $cfg->{'trim'}		|| 0;
  $self->{'fb'}			= $cfg->{'fb'}			|| 0;
  $self->{'scrolltext'}		= $cfg->{'scrolltext'}		|| 0;
  $self->{'noitem'}	       	= $cfg->{'noitem'}		|| 0;

  $self->{'handlers'} = {};
  $self->{'handlers'}->{'HELP'}	= $cfg->{'HELP-SUB'}		|| undef();
  $self->{'handlers'}->{'EXTRA'}= $cfg->{'EXTRA-SUB'}		|| undef();
  $self->{'handlers'}->{'ESC'} 	= $cfg->{'ESC-SUB'}		|| undef();
  $self->{'handlers'}->{'CANCEL'} = $cfg->{'CANCEL-SUB'}	|| undef();

  my $clone = {};
  foreach my $key (keys(%$self)) { $clone->{$key} = $self->{$key}; }
  $self->{'clone'} = $clone;

  if ($self->{'gui'} && !$ENV{'DISPLAY'}) { croak("could not find a DISPLAY to use."); }

  $self->__CLEAR();
  return($self);
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Class (internal) Methods
#:

#: slurp all the text from a readable regular text file
#: and return it as a single string;
sub __CAT_ONCE {
  my $file = shift();
  if (-r $file) {
    my $text;
    my $TS = $/;
    undef($/);
    open(CAT,"<".$file) or return($file);
    $text = <CAT>;
    close($file);
    $/ = $TS;
    undef($TS);
    unlink($file);
    return($text);
  }
}

#: figure out which dialog implementation is available
#: and return it's path and filename.
sub __TEST_VARIANTS {
  my $self = shift();
  my $path = shift();
  my @variants;
  if ($self->{'gui'}) { push(@variants,@{$self->{'gui-variants'}}); }
  else {
    push(@variants,@{$self->{'variants'}});
    if ($ENV{'DISPLAY'}) { push(@variants,@{$self->{'gui-variants'}}); }
  }
  foreach my $variant (@variants) {
    next unless $variant;
    if (-x $path."/".$variant) {
      $self->{'gui'} = 1 if grep { /^\Q$variant\E$/ } @{$self->{'gui-variants'}};
      return($path."/".$variant);
    }
  }
  return();
}

#: mark the dialog variant for internal use
sub __TEST_VARIANT {
  my $self = shift();
  my $bn = basename($self->{'dialog'});
  if ($self->{'ascii'}) { return("ascii"); }
  elsif ($bn eq "whiptail" || $bn eq "gdialog" || $bn eq "ascii") { return($bn); }
  elsif ($bn eq "dialog") {
    my $str = `$self->{'dialog'} --help 2>&1`;
    if ($str =~ /cdialog\s\(ComeOn\sDialog\!\)\sversion\s(\d+\.\d+.+)/) {
      # We consider cdialog to be a colour supporting version (0.9b-20030130)
      # all others are non-colourized and support only the base functionality :(
      if ($1 =~ /20030130|20030302|20030308$/) { return("cdialog"); } # Debian Sid
      if ($1 =~ /20020814$/) { return("dialog"); } # Debian Woody
      if ($1 =~ /20020519$/) { return("dialog"); } # RedHat 8
      return($bn); # unknown...
    } else { return($bn); }
  }
}

#: this is the method that ultimately detects the "correct"
#: dialog variant to use.
sub __WHICH_DIALOG {
  my $self = shift();
  if ($self->{'ascii'}) {
    $self->{'dialogbin'} = "NULL";
    $self->{'dialog'} = "NULL";
    $self->{'dialogtype'} = "ascii";
  } else {
    if ($self->{'dialogbin'} && -x $self->{'dialogbin'}) {
      $self->{'dialog'} = $self->{'dialogbin'};
    } else {
      my @paths;
      if ($ENV{'PATH'}) { @paths = split(/:/,$ENV{'PATH'}); }
      else { push(@paths,@{$self->{'envpaths'}}); }
    WDCHECK: foreach my $path (@paths) {
	$self->{'dialog'} = $self->__TEST_VARIANTS($path);
	last WDCHECK unless !$self->{'dialog'};
      }
      $self->{'dialog'} = "ascii" unless -x $self->{'dialog'};
    }
    $self->{'dialogtype'} = $self->__TEST_VARIANT();
    $self->{'ascii'} = 1 if $self->{'dialogtype'} eq "ascii";
    if ($ENV{'DISPLAY'} && ($self->is_gdialog() || $self->is_kdialog()) && !$self->{'ascii'}) { $self->{'gui'} = 1; }
    else { $self->{'gui'} = 0; }
  }
}

#: purely internal use; not intended for anything but
#: debugging methods in the module.
sub __debug_this {
  my $s;
  my $self = shift();
  if (ref($self)) { $s = shift(); }
  else { $s = $self; }
  chomp($s) unless !$s;
  open(LOG,">>./debug-udpm.log");
  print LOG "[".localtime(time())."] ".($s||"blank entry!")."\n";
  close(LOG);
}

#: gather a list of the contents of a directory and return it in
#: two forms, one is the "simple" list of all the filenames and the
#: other is a 'menu' list corresponding to the simple list.
sub __GET_DIR {
  my $self = shift();
  my $path = shift() || return();
  my $pref = shift();
  my (@listing,@list);
  opendir(GETDIR,$path) or return("failed to read directory: ".$path);
  my @dir_data = readdir(GETDIR);
  closedir(GETDIR);
  if ($pref) { push(@listing,@{$pref}); }
  foreach my $dir (sort(grep { -d $path."/".$_ } @dir_data)) { push(@listing,$dir."/"); }
  foreach my $item (sort(grep { !-d $path."/".$_ } @dir_data)) { push(@listing,$item); }
  my $c = 1;
  foreach my $item (@listing) { push(@list,"$c",$item); $c++; }
  return(\@list,\@listing);
}

#: Text Translator
#: this is responsible for alignments, colours and other
#: superflous font trickery
sub __TRANSLATE {
  my $self = shift();
  my $text = shift() || return();
  my @array;

  if (ref($text) eq "ARRAY") { push(@array,@{$text}); }
  elsif ($text =~ /\\n/) { @array = split(/\\n/,$text); }
  else { @array = split(/\n/,$text); }
  $text = undef();

  if ($self->{'ascii'}) {
    $text = join("\n",@array);
    $text =~ s!\[A\=\w+\]!!gmi;
  } else {
    if ($self->{'auto-scale'}) {
      foreach my $line (@array) {
	my $s_line = $self->__TRANSLATE_CLEAN($line);
	$s_line =~ s!\[A\=\w+\]!!gi;
	$self->{'width'} = length($s_line) + 5
	 if ($self->{'width'} - 5) < length($s_line)
	  && (length($s_line) <= $self->{'max-scale'});
      }
    }
    foreach my $line (@array) {
      my $pad;
      my $s_line = $self->__TRANSLATE_CLEAN($line);
      if ($line =~ /\[A\=(\w+)\]/i) {
	my $align = $1;
	$line =~ s!\[A\=\w+\]!!gi;
	if (uc($align) eq "CENTER" || uc($align) eq "C") {
	  $pad = ((($self->{'width'} - 5) - length($s_line)) / 2);
	} elsif (uc($align) eq "LEFT" || uc($align) eq "L") {
	  $pad = 0;
	} elsif (uc($align) eq "RIGHT" || uc($align) eq "R") {
	  $pad = (($self->{'width'} - 5) - length($s_line));
	}
      }
      if ($pad) { $text .= (" " x $pad).$line.'\n'; }
      else { $text .= $line.'\n'; }
    }
    $text =~ s!"!\\"!gm;
    $text =~ s!`!\\`!gm;
  }
  $text = $self->__TRANSLATE_FILTER($text);
  return($text);
}

sub __TRANSLATE_FILTER {
  my $self = shift();
  my $text = shift() || return();
  if ($self->is_cdialog() && $self->{'colours'}) {
    $text =~ s!\[C=black\]!\\Z0!gmi;
    $text =~ s!\[C=red\]!\\Z1!gmi;
    $text =~ s!\[C=green\]!\\Z2!gmi;
    $text =~ s!\[C=yellow\]!\\Z3!gmi;
    $text =~ s!\[C=blue\]!\\Z4!gmi;
    $text =~ s!\[C=magenta\]!\\Z5!gmi;
    $text =~ s!\[C=cyan\]!\\Z6!gmi;
    $text =~ s!\[C=white\]!\\Z7!gmi;
    $text =~ s!\[B\]!\\Zb!gmi;
    $text =~ s!\[/B\]!\\ZB!gmi;
    $text =~ s!\[U\]!\\Zu!gmi;
    $text =~ s!\[/U\]!\\ZU!gmi;
    $text =~ s!\[R\]!\\Zr!gmi;
    $text =~ s!\[/R\]!\\ZR!gmi;
    $text =~ s!\[N\]!\\Zn!gmi;
  } else {
    $text = $self->__TRANSLATE_CLEAN($text);
  }
  return($text);
}
sub __TRANSLATE_CLEAN {
  my $self = shift();
  my $text = shift();
  $text =~ s!\\Z0!!gmi;
  $text =~ s!\\Z1!!gmi;
  $text =~ s!\\Z2!!gmi;
  $text =~ s!\\Z3!!gmi;
  $text =~ s!\\Z4!!gmi;
  $text =~ s!\\Z5!!gmi;
  $text =~ s!\\Z6!!gmi;
  $text =~ s!\\Z7!!gmi;
  $text =~ s!\\Zb!!gmi;
  $text =~ s!\\ZB!!gmi;
  $text =~ s!\\Zu!!gmi;
  $text =~ s!\\ZU!!gmi;
  $text =~ s!\\Zr!!gmi;
  $text =~ s!\\ZR!!gmi;
  $text =~ s!\\Zn!!gmi;
  $text =~ s!\[C=black\]!!gmi;
  $text =~ s!\[C=red\]!!gmi;
  $text =~ s!\[C=green\]!!gmi;
  $text =~ s!\[C=yellow\]!!gmi;
  $text =~ s!\[C=blue\]!!gmi;
  $text =~ s!\[C=magenta\]!!gmi;
  $text =~ s!\[C=cyan\]!!gmi;
  $text =~ s!\[C=white\]!!gmi;
  $text =~ s!\[B\]!!gmi;
  $text =~ s!\[/B\]!!gmi;
  $text =~ s!\[U\]!!gmi;
  $text =~ s!\[/U\]!!gmi;
  $text =~ s!\[R\]!!gmi;
  $text =~ s!\[/R\]!!gmi;
  $text =~ s!\[N\]!!gmi;
  $text =~ s!\[A=\w+\]!!gmi;
  return($text);
}

#: verify the correct list type
#: (2 args per entry means it's divisible by 2)
sub __TEST_MENU_ARGS {
  my $self = shift();
  my $menu = shift();
  if (ref($menu) eq "ARRAY") {
    if ((@{$menu} % 2) == 0) { return(1); }
    else {
      $self->msgbox({'title'=>'error',
		     'text'=>'The menu() widget has been passed an inapropriate number of arguments. '.
		     'menu() requires a list that contains two consecutive elements per menu entry.'
		    });
      return(0);
    }
  } else { return(0); }
}

#: verify the correct list type
#: (3 args per entry means it's divisible by 3)
sub __TEST_LIST_ARGS {
  my $self = shift();
  my $menu = shift();
  if (ref($menu) eq "ARRAY") {
    if ((@{$menu} % 3) == 0) {

      my $RV = 1;
      for (my $i = 2; $i < @{$menu}; $i += 3) { if ($menu->[$i] !~ /^(on|off)$/i) { $RV = 0; } }
      if (!$RV) {
	$self->msgbox({'title'=>'error',
		       'text'=>'The list-based widget has been passed a list that has invalid status field(s). '.
		       'list-based widgets requires a list that has every third element being either '.
		       '"on" or "off" (case in-sensitive).'
		      });
      }
      return($RV);

    } else {
      $self->msgbox({'title'=>'error',
		     'text'=>'The list-based widget has been passed an inapropriate number of arguments. '.
		     'List-based widgets requires a list that contains three consecutive elements per menu entry.'.
		     'with the third element being either "on" or "off" (case in-sensitive).'
		    });
      return(0);
    }
  } else { return(0); }
}

#: this is the dynamic 'Colon Command Help'
sub __ASCII_NAV_HELP {
  my $self = shift();
  my $head = "
Colon Commands:

:?\t\t\tThis help message
:pg <N>\t\t\tGo to page 'N'
:n :next\t\tGo to the next page
:p :prev\t\tGo to the previous page

:esc :escape\t\tSend the [Esc] signal
";
  if ($self->{'use_stderr'}) {
    print STDERR ("~" x 79).$head;
  } else {
    print STDOUT ("~" x 79).$head;
  }
  if ($self->{'extra-button'} || $self->{'extra-label'}) {
    if ($self->{'use_stderr'}) {
      print STDERR ":e :extra\t\tSend the [Extra] signal\n";
    } else {
      print STDOUT ":e :extra\t\tSend the [Extra] signal\n";
    }
  }
  if (!$self->{'nocancel'}) {
    if ($self->{'use_stderr'}) {
      print STDERR ":c :cancel\t\tSend the [Cancel] signal\n";
    } else {
      print STDOUT ":c :cancel\t\tSend the [Cancel] signal\n";
    }
  }
  if ($self->{'help-button'} || $self->{'help-label'}) {
    if ($self->{'use_stderr'}) {
      print STDERR ":h :help\t\tSend the [Help] signal\n";
    } else {
      print STDOUT ":h :help\t\tSend the [Help] signal\n";
    }
  }
  if ($self->{'use_stderr'}) {
    print STDERR ("~" x 79)."\n";
  } else {
    print STDOUT ("~" x 79)."\n";
  }
}

#: this returns the labels (or ' ') for the "extra", "help" and
#: "cancel" buttons.
sub __ASCII_BUTTONS {
  my $self = shift();
  my ($help,$cancel,$extra) = (' ',' ',' ');
  $extra = "Extra" if $self->{'extra-button'};
  $extra = $self->{'extra-label'} if $self->{'extra-label'};
  $extra = "':e'=[".$extra."]" if $extra and $extra ne ' ';
  $help = "Help" if $self->{'help-button'};
  $help = $self->{'help-label'} if $self->{'help-label'};
  $help = "':h'=[".$help."]" if $help and $help ne ' ';
  $cancel = "Cancel" unless $self->{'nocancel'};
  $cancel = $self->{'cancel-label'} if $self->{'cancel-label'};
  $cancel = "':c'=[".$cancel."]" if $cancel and $cancel ne ' ';
  return($help,$cancel,$extra);
}


#: this writes a standard ascii interface to STDOUT. This is intended for use
#: with any non-list native ascii mode widgets.
sub __ASCII_WRITE_TEXT {
  my $self = shift();
  my $cfg = shift();
  my $text = $cfg->{'text'};
  my $backtitle = $cfg->{'backtitle'} || $self->{'backtitle'} || " ";
  my $title = $cfg->{'title'} || $self->{'title'} || " ";
  format ASCIIPGTXT =
+-----------------------------------------------------------------------------+
| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |
$backtitle
+-----------------------------------------------------------------------------+
|                                                                             |
| +-------------------------------------------------------------------------+ |
| | @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| | |
$title
| +-------------------------------------------------------------------------+ |
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| +-------------------------------------------------------------------------+ |
|                                                                             |
+-----------------------------------------------------------------------------+
.
  no strict 'subs';
  my $_fh = select();
  select(STDERR) unless not $self->{'use_stderr'};
  my $LFMT = $~;
  $~ = ASCIIPGTXT;
  write();
  $~= $LFMT;
  select($_fh) unless not $self->{'use_stderr'};
  use strict 'subs';
}

#: very much like __ASCII_WRITE_TEXT() except that this is specifically for
#: the menu() widget only.
sub __ASCII_WRITE_MENU {
  my $self = shift();
  my $cfg = shift();
  my $text = $cfg->{'text'};
  my $backtitle = $cfg->{'backtitle'} || $self->{'backtitle'} || " ";
  my $title = $cfg->{'title'} || $self->{'title'} || " ";
  my $menu = $cfg->{'menu'} || [];
  my ($help,$cancel,$extra) = $self->__ASCII_BUTTONS();
  format ASCIIPGMNU =
+-----------------------------------------------------------------------------+
| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |
$backtitle
+-----------------------------------------------------------------------------+
|                                                                             |
| +-------------------------------------------------------------------------+ |
| | @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| | |
$title
| +-------------------------------------------------------------------------+ |
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| +-------------------------------------------------------------------------+ |
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[0]||' '),($menu->[1]||' '),($menu->[2]||' '),($menu->[3]||' '),($menu->[4]||' '),($menu->[5]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[6]||' '),($menu->[7]||' '),($menu->[8]||' '),($menu->[9]||' '),($menu->[10]||' '),($menu->[11]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[12]||' '),($menu->[13]||' '),($menu->[14]||' '),($menu->[15]||' '),($menu->[16]||' '),($menu->[17]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[18]||' '),($menu->[19]||' '),($menu->[20]||' '),($menu->[21]||' '),($menu->[22]||' '),($menu->[23]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[24]||' '),($menu->[25]||' '),($menu->[26]||' '),($menu->[27]||' '),($menu->[28]||' '),($menu->[29]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[30]||' '),($menu->[31]||' '),($menu->[32]||' '),($menu->[33]||' '),($menu->[34]||' '),($menu->[35]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[36]||' '),($menu->[37]||' '),($menu->[38]||' '),($menu->[39]||' '),($menu->[42]||' '),($menu->[43]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[42]||' '),($menu->[43]||' '),($menu->[44]||' '),($menu->[45]||' '),($menu->[46]||' '),($menu->[47]||' ')
|  @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<<    @<<<< @<<<<<<<<<<<<<<  |
($menu->[48]||' '),($menu->[49]||' '),($menu->[50]||' '),($menu->[51]||' '),($menu->[52]||' '),($menu->[53]||' ')
|      @||||||||||||||||||||  @|||||||||||||||||||  @|||||||||||||||||||      |
$extra,$cancel,$help
|                        ':?' = [Colon Command Help]                          |
+-----------------------------------------------------------------------------+
.
  no strict 'subs';
  my $_fh = select();
  select(STDERR) unless not $self->{'use_stderr'};
  my $LFMT = $~;
  $~ = ASCIIPGMNU;
  write();
  $~= $LFMT;
  select($_fh) unless not $self->{'use_stderr'};
  use strict 'subs';
}

#: very much like __ASCII_WRITE_MENU() except that this is specifically for
#: the radiolist() and checklist() widgets only.
sub __ASCII_WRITE_LIST {
  my $self = shift();
  my $cfg = shift();
  my $text = $cfg->{'text'};
  my $backtitle = $cfg->{'backtitle'} || $self->{'backtitle'} || " ";
  my $title = $cfg->{'title'} || $self->{'title'} || " ";
  my $menu = [];
  push(@{$menu},@{$cfg->{'menu'}});
  my ($help,$cancel,$extra) = $self->__ASCII_BUTTONS();
  my $m = @{$menu};

  if ($cfg->{'wm'}) {
    for (my $i = 2; $i < $m; $i += 3) {
      if ($menu->[$i] && $menu->[$i] =~ /on/i) { $menu->[$i] = '->'; }
      else { $menu->[$i] = ' '; }
    }
  } else {
    my $mark;
    for (my $i = 2; $i < $m; $i += 3) {
      if (!$mark && $menu->[$i] && $menu->[$i] =~ /on/i) { $menu->[$i] = '->'; $mark = 1; }
      else { $menu->[$i] = ' '; }
    }
  }

  format ASCIIPGLST =
+-----------------------------------------------------------------------------+
| @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |
$backtitle
+-----------------------------------------------------------------------------+
|                                                                             |
| +-------------------------------------------------------------------------+ |
| | @|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| | |
$title
| +-------------------------------------------------------------------------+ |
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< | |
$text
| +-------------------------------------------------------------------------+ |
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[2]||' '),($menu->[0]||' '),($menu->[1]||' '), ($menu->[5]||' '),($menu->[3]||' '),($menu->[4]||' '), ($menu->[8]||' '),($menu->[6]||' '),($menu->[7]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[11]||' '),($menu->[9]||' '),($menu->[10]||' '), ($menu->[14]||' '),($menu->[12]||' '),($menu->[13]||' '), ($menu->[17]||' '),($menu->[15]||' '),($menu->[16]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[20]||' '),($menu->[18]||' '),($menu->[19]||' '), ($menu->[23]||' '),($menu->[21]||' '),($menu->[22]||' '), ($menu->[26]||' '),($menu->[24]||' '),($menu->[25]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[29]||' '),($menu->[27]||' '),($menu->[28]||' '), ($menu->[32]||' '),($menu->[30]||' '),($menu->[31]||' '), ($menu->[35]||' '),($menu->[33]||' '),($menu->[34]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[38]||' '),($menu->[36]||' '),($menu->[37]||' '), ($menu->[41]||' '),($menu->[39]||' '),($menu->[40]||' '), ($menu->[44]||' '),($menu->[42]||' '),($menu->[43]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[47]||' '),($menu->[45]||' '),($menu->[46]||' '), ($menu->[50]||' '),($menu->[48]||' '),($menu->[49]||' '), ($menu->[53]||' '),($menu->[51]||' '),($menu->[52]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[56]||' '),($menu->[54]||' '),($menu->[55]||' '), ($menu->[59]||' '),($menu->[57]||' '),($menu->[58]||' '), ($menu->[62]||' '),($menu->[60]||' '),($menu->[61]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[65]||' '),($menu->[63]||' '),($menu->[64]||' '), ($menu->[68]||' '),($menu->[66]||' '),($menu->[67]||' '), ($menu->[71]||' '),($menu->[69]||' '),($menu->[70]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[74]||' '),($menu->[72]||' '),($menu->[73]||' '), ($menu->[77]||' '),($menu->[75]||' '),($menu->[76]||' '), ($menu->[80]||' '),($menu->[78]||' '),($menu->[79]||' ')
|@<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<<< @<<@<<<< @<<<<<<<<<<<<<< |
($menu->[83]||' '),($menu->[81]||' '),($menu->[82]||' '), ($menu->[86]||' '),($menu->[84]||' '),($menu->[85]||' '), ($menu->[89]||' '),($menu->[87]||' '),($menu->[88]||' ')
|      @||||||||||||||||||||  @|||||||||||||||||||  @|||||||||||||||||||      |
$extra,$cancel,$help
|                        ':?' = [Colon Command Help]                          |
+-----------------------------------------------------------------------------+
.
  no strict 'subs';
  my $_fh = select();
  select(STDERR) unless not $self->{'use_stderr'};
  my $LFMT = $~;
  $~ = ASCIIPGLST;
  write();
  $~= $LFMT;
  select($_fh) unless not $self->{'use_stderr'};
  use strict 'subs';
}

#: this is an internal function called by all widgets just before
#: the widget is displayed. This will clear the screen if 'auto-clear' is set
#: and this also serves as a good opportunity to 'sleep'.
sub __CLEAR {
  my $self = shift();
  if (!$self->is_cdialog()) { sleep($self->{'sleep'}) if $self->{'sleep'}; }
  return unless $self->{'auto-clear'};
  $self->clear();
}

#: this is an internal function to call all the callbacks
sub __CALLBACKS {
  my $self = shift();
  my $opt = shift();
  &{$self->{'handlers'}->{'HELP'}} if $self->state() eq "HELP" and ref($self->{'handlers'}->{'HELP'}) eq "CODE" and !$opt->{'do-not-help'};
  &{$self->{'handlers'}->{'EXTRA'}} if $self->state() eq "EXTRA" and ref($self->{'handlers'}->{'EXTRA'}) eq "CODE" and !$opt->{'do-not-extra'};
  &{$self->{'handlers'}->{'ESC'}} if $self->state() eq "ESC" and ref($self->{'handlers'}->{'ESC'}) eq "CODE" and !$opt->{'do-not-esc'};
  &{$self->{'handlers'}->{'CANCEL'}} if $self->state() eq "CANCEL" and ref($self->{'handlers'}->{'CANCEL'}) eq "CODE" and !$opt->{'do-not-cancel'};
}

#: this is an interal function called by all widgets just before
#: the widget is routed (to either ascii or dialog variant) and will
#: beep if 'beep' is set in eith self or cfg.
sub __BEEP {
  my $self = shift();
  my $cfg = shift();
  if (($self->{'beep'}||$cfg->{'beep'}) && !$self->is_cdialog()) {
    if ($self->{'use_stderr'}) {
      print STDERR "\a";
    } else {
      print STDOUT "\a";
    }
  }
}

#: this is called by all widgets and simply resets all the attibs to
#: the defaults.
sub __CLEAN_ATTRS {
  my $self = shift();
  foreach my $key (keys(%{$self->{'clone'}})) {
    $self->{$key} = $self->{'clone'}->{$key} || undef();
  }
}

#: this compiles the dialog variant specific command line options and
#: returns it as a single string. This is called by all widgets that
#: will use __RUN_DIALOG().
sub __GET_ATTR_STR {
  my $self = shift();
  my $attr = shift();
  $self->__ATTRIBUTE($attr);
  my $str = " ";
  $str .= " --backtitle \"".$self->{'backtitle'}."\"" if $self->{'backtitle'};
  $str .= " --title \"".$self->{'title'}."\"" if $self->{'title'};
  $str .= " --clear" if $self->{'clear'};
  $str .= " --defaultno" if $self->{'defaultno'};
  $str .= " --separate-output" if $self->{'separate-output'};
  if ($self->is_cdialog()) {
    $str .= " --aspect ".$self->{'aspect'} if $self->{'aspect'};
    $str .= " --beep" if $self->{'beep'};
    $str .= " --beep-after" if $self->{'beep-after'};
    $str .= " --begin ".$self->{'begin'}->[0]." ".$self->{'begin'}->[1] if $self->{'begin'}->[0] and $self->{'begin'}->[1];
    $str .= " --cancel-label \"".$self->{'cancel-label'}."\"" if $self->{'cancel-label'};
    $str .= " --colors" if $self->{'colours'} || $self->{'colors'};
    $str .= " --cr-wrap" if $self->{'cr-wrap'};
    $str .= " --default-item \"".$self->{'default-item'}."\"" if $self->{'default-item'};
    $str .= " --exit-label \"".$self->{'exit-label'}."\"" if $self->{'exit-label'};
    $str .= " --extra-button" if $self->{'extra-button'};
    $str .= " --extra-label \"".$self->{'extra-label'}."\"" if $self->{'extra-label'};
    $str .= " --help-button" if $self->{'help-button'};
    $str .= " --help-label \"".$self->{'help-label'}."\"" if $self->{'help-label'};
    $str .= " --ignore" if $self->{'ignore'};
    $str .= " --no-collapse" if $self->{'no-collapse'};
    $str .= " --ok-label \"".$self->{'ok-label'}."\"" if $self->{'ok-label'};
    $str .= " --item-help" if $self->{'item-help'};
    $str .= " --max-input ".$self->{'max-input'} if $self->{'max-input'};
    $str .= " --separate-widget \"".$self->{'separate-widget'}."\"" if $self->{'separate-widget'};
    $str .= " --shadow" if $self->{'shadow'};
    $str .= " --no-shadow" if $self->{'no-shadow'};
    $str .= " --sleep ".$self->{'sleep'} if $self->{'sleep'};
    $str .= " --tab-correct" if $self->{'tab-correct'};
    $str .= " --tab-len ".$self->{'tab-len'} if $self->{'tab-len'};
    $str .= " --timeout ".$self->{'timeout'} if $self->{'timeout'};
    $str .= " --trim" if $self->{'trim'};
  }
  if ($self->is_whiptail()) {
    $str .= " --nocancel" if $self->{'no-cancel'} or $self->{'nocancel'};
    $str .= " --fb" if $self->{'fb'};
    $str .= " --noitem" if $self->{'noitem'};
    $str .= " --scrolltext" if $self->{'scrolltext'};
  } elsif (!$self->is_gdialog() && !$self->is_kdialog()) {
    $str .= " --no-cancel" if $self->{'no-cancel'} or $self->{'nocancel'};
  }
  return($str);
}

#: This runs the actual dialog command, correlates the returned data
#: and returns the data gathered in the appropriate format.
sub __RUN_DIALOG {
  my $self = shift();
  my $attrs = shift();
  my $mode = shift() || 'rv';
  if ($self->is_whiptail()) {
    my $tmpfile = $self->{'tmpdir'}."/".ref($self)."_whiptail_".$$.".tmp";
    if ($mode eq "array") {
      system($self->{'dialog'}." ".$attrs." 2>".$tmpfile);
      $self->{'return_value'} = $? >> 8;
      $self->{'return_string'} = __CAT_ONCE($tmpfile);
      $self->{'return_array'} = [split(/\n/,$self->{'return_string'})];
    } elsif ($mode eq "string") {
      system($self->{'dialog'}." ".$attrs." 2>".$tmpfile);
      $self->{'return_value'} = $? >> 8;
      $self->{'return_string'} = __CAT_ONCE($tmpfile);
    } else {
      `$self->{'dialog'} $attrs 1>&2`;
      $self->{'return_value'} = $? >> 8;
    }
  } else {
    if ($mode eq "array") {
      $self->{'return_string'} = `$self->{'dialog'} $attrs 2>&1`;
      $self->{'return_value'} = $? >> 8;
      $self->{'return_array'} = [split(/\n/,$self->{'return_string'})];
    } elsif ($mode eq "string") {
      $self->{'return_string'} = `$self->{'dialog'} $attrs 2>&1`;
      $self->{'return_value'} = $? >> 8;
    } else {
      `$self->{'dialog'} $attrs`;
      $self->{'return_value'} = $? >> 8;
    }
  }
}

#: this resets all Return Values
sub __CLEAN_RVALUES {
  my $self = shift();
  $self->{'return_value'} = undef();
  $self->{'return_string'} = undef();
  $self->{'return_array'} = undef();
}



#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public (attribute) Methods
#:

#: test if the attribute name in question is regarded as "valid"
sub is_attr {
  my $self = shift();
  my $attr = shift() || return(0);
  return(1) if grep { /^\Q$attr\E$/ } @{$ATTRIBUTES};
  return(0);
}

#: manipulate attribute defaults
sub attribute {
  my $self = shift();
  my $data = shift();
  my $atad = shift();
  if (ref($data) eq "HASH") {
    foreach my $key (keys(%$data)) {
      next unless $self->is_attr($key);
      $self->{$key} = $data->{$key} || undef();
      $self->{'clone'}->{$key} = $data->{$key} || undef();
    }
  } elsif (!ref($data)) {
    if ($atad) {
      $self->{$data} = $atad;
      $self->{'clone'}->{$data} = $atad;
    } else {
      return($self->{$data});
    }
  }
}

#: is this linux?
sub is_linux {
  my $self = shift();
  if ($^O =~ /linux/i) { return(1); }
  return(0);
}

#: is this BSD?
sub is_bsd {
  my $self = shift();
  if ($^O =~ /bsd/i) { return(1); }
  return(0);
}

#: is this ascii mode?
sub is_ascii {
  my $self = shift();
  return(1) if $self->{'dialogtype'} eq "ascii";
  return(0);
}

#: is this cdialog?
sub is_cdialog {
  my $self = shift();
  return(1) if $self->{'dialogtype'} eq "cdialog";
  return(0);
}

#: is this gdialog?
sub is_gdialog {
  my $self = shift();
  return(1) if $self->{'dialogtype'} eq "gdialog";
  return(0);
}

#: is this kdialog?
sub is_kdialog {
  my $self = shift();
  return(1) if $self->{'dialogtype'} eq "kdialog";
  return(0);
}

#: is this vanilla dialog?
sub is_dialog {
  my $self = shift();
  return(1) if $self->{'dialogtype'} eq "dialog";
  return(0);
}

#: is this whiptail?
sub is_whiptail {
  my $self = shift();
  return(1) if $self->{'dialogtype'} eq "whiptail";
  return(0);
}

#: set the attributes and translate the 'text'. This is called from
#: __GET_ATTR_STR and thusly by all widgets.
sub __ATTRIBUTE {
  my $self = shift();
  my $data = shift();
  if (ref($data) eq "HASH") {
    foreach my $key (keys(%$data)) {
      next unless $self->is_attr($key);
      $self->{$key} = $data->{$key} || undef();
    }
  }
  if ($data->{'text'}) { $self->{'text'} = $self->__TRANSLATE($data->{'text'}); }
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public (Nautilus Shell Script) Methods
#:

#NAUTILUS_SCRIPT_SELECTED_FILE_PATHS: newline-delimited paths for selected files (only if local)
sub nautilus_paths {
  my $self = shift();
  if ($ENV{'NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'}) {
    return(reverse(split(/\n/,$ENV{'NAUTILUS_SCRIPT_SELECTED_FILE_PATHS'})));
  } else { return(('error')); }
}

#NAUTILUS_SCRIPT_SELECTED_URIS: newline-delimited URIs for selected files
sub nautilus_uris {
  my $self = shift();
  if ($ENV{'NAUTILUS_SCRIPT_SELECTED_URIS'}) {
    return(reverse(split(/\n/,$ENV{'NAUTILUS_SCRIPT_SELECTED_URIS'})));
  } else { return(('error')); }
}

#NAUTILUS_SCRIPT_CURRENT_URI: URI for current location
sub nautilus_path {
  my $self = shift();
  my $URI = $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'};
  $URI =~ s!^file://(.*)!$1! if $URI;
  return($URI) if $URI;
  return('error');
}

#NAUTILUS_SCRIPT_CURRENT_URI: URI for current location
sub nautilus_uri {
  my $self = shift();
  return($ENV{'NAUTILUS_SCRIPT_CURRENT_URI'}) if $ENV{'NAUTILUS_SCRIPT_CURRENT_URI'};
  return('error');
}

#NAUTILUS_SCRIPT_WINDOW_GEOMETRY: position and size of current window
sub nautilus_geometry {
  my $self = shift();
  if ($ENV{'NAUTILUS_SCRIPT_WINDOW_GEOMETRY'}) {
    return($1,$2,$3,$4) if $ENV{'NAUTILUS_SCRIPT_WINDOW_GEOMETRY'} =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/;
  } else { return('e','e','e','e'); }
}

sub nautilus_debug {
  my $self = shift();
  my @paths = $self->nautilus_paths();
  my @uris = $self->nautilus_uris();
  my $path = $self->nautilus_path();
  my $uri = $self->nautilus_uri();
  my ($w,$h,$x,$y) = $self->nautilus_geometry();

  $self->msgbox({'title'=>'Debug Nautilus Script','width'=>79,'height'=>25,
		 'text'=>["Current nautilus script environment is:",
			  "PATHS:{ ".join(" ",@paths)." }",
			  "URIS:{ ".join(" ",@uris)." }",
			  "PATH:{ ".$path." }",
			  "URI:{ ".$uri." }",
			  "GEO:{ W:$w H:$h X:$x Y:$y }"]});
}

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public (user-input access) Methods
#:

#: return a keyword describing the last widget's state.
sub state {
  my $self = shift();
  if ($self->is_gdialog() || $self->is_kdialog()) {
    if (!$self->rv() || $self->rv() == 0) { return("OK"); }
    elsif ($self->rv() == 255) { return("ESC"); }
    elsif ($self->rv() == 250) { return("CANCEL"); }
    elsif ($self->rv() == 252) { return("CLOSE"); }
    elsif ($self->rv() == 3) { return("EXTRA"); }
    elsif ($self->rv() == 2) { return("HELP"); }
    else { return("UNKNOWN"); }
  } else {
    if (!$self->rv() || $self->rv() == 0) { return("OK"); }
    elsif ($self->rv() == 1) { return("CANCEL"); }
    elsif ($self->rv() == 255) { return("ESC"); }
    elsif ($self->rv() == 3) { return("EXTRA"); }
    elsif ($self->rv() == 2) { return("HELP"); }
    elsif ($self->rv() == -1) {
      return("ERROR") unless $self->is_whiptail();
      return("ESC");
    } else { return("UNKNOWN"); }
  }
}

#: return or set the Return Value. This affects the state() method.
sub rv {
  my $self = shift();
  my $set = shift();
  $self->{'return_value'} = $set if $set;
  return($self->{'return_value'});
}

#: return or set the Return String. This affects the string related
#: widgets: inputbox(), passwordbox(), menu(), and radiolist().
sub rs {
  my $self = shift();
  my $set = shift();
  $self->{'return_string'} = $set if $set;
  chomp($self->{'return_string'}) if $self->{'return_string'};
  return($self->{'return_string'});
}

#: return or set the Return Array. This affects the array related
#: widgets: checklist(), timebox(), and calendar().
sub ra {
  my $self = shift();
  my $set = shift();
  if (ref($set) eq "ARRAY") { $self->{'return_array'} = $set; }
  return(@{$self->{'return_array'}}) unless !$self->{'return_array'};
  return();
}


#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#: Public (Dialog Widget) Methods
#:

#: clear
sub clear {
  my $self = shift();
  return unless !$self->is_gdialog() and !$self->is_kdialog();
  $self->{'__CLEAR'} = `clear` unless $self->{'__CLEAR'};
  print $self->{'__CLEAR'};
}

#: YESNO
sub yesno {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_yesno($cfg)); }
  else { return($self->__dialog_yesno($cfg)); }
}
sub noyes {
  my $self = shift();
  my $cfg = shift();
  $cfg->{'defaultno'} = 1;
  return($self->yesno($cfg));
}
sub __ascii_yesno {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  my ($YN,$RESP) = ('Yes|no','YES_OR_NO');
  $YN = "yes|No" if $self->{'defaultno'};
  while ($RESP !~ /^(y|yes|n|no)$/i) {
    $self->clear() if $self->{'auto-clear'};
    $self->__ASCII_WRITE_TEXT({'text'=>$self->{'text'}});
    if ($self->{'use_stderr'}) {
      print STDERR "(".$YN."): ";
    } else {
      print STDOUT "(".$YN."): ";
    }
    chomp($RESP = <STDIN>);
    if (!$RESP && $self->{'defaultno'}) { $RESP = "no"; }
    elsif (!$RESP && !$self->{'defaultno'}) { $RESP = "yes"; }
    if ($RESP =~ /^(y|yes)$/i) { $self->{'return_value'} = 0; }
    else { $self->{'return_value'} = 1; }
  }
  $self->__CLEAR();
  $self->__CALLBACKS({'do-not-cancel'=>1});
  return(1) if $self->state() eq "OK";
  return(0);
}
sub __dialog_yesno {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --scrolltext" unless (!$self->is_whiptail() || $self->{'scrolltext'});
  $attrs .= " --yesno ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $self->__RUN_DIALOG($attrs);
  $self->__CLEAR();
  $self->__CALLBACKS({'do-not-cancel'=>1});
  return(1) if $self->state() eq "OK";
  return(0);
}

#: MSGBOX
sub msgbox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_msgbox($cfg)); }
  else { return($self->__dialog_msgbox($cfg)); }
}
sub __ascii_msgbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  $self->__ASCII_WRITE_TEXT({'text'=>$self->{'text'}});
  if ($self->{'use_stderr'}) {
    print STDERR (" " x 25)."[ Press Enter to Continue ]";
  } else {
    print STDOUT (" " x 25)."[ Press Enter to Continue ]";
  }
  my $junk = <STDIN>;
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rv());
}
sub __dialog_msgbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --scrolltext" unless (!$self->is_whiptail() || $self->{'scrolltext'});
  $attrs .= " --msgbox ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $self->__RUN_DIALOG($attrs);
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rv());
}

#: INFOBOX
sub infobox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_infobox($cfg)); }
  else { return($self->__dialog_infobox($cfg)); }
}
sub __ascii_infobox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  $self->__ASCII_WRITE_TEXT({'text'=>$self->{'text'}});
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rv());
}
sub __dialog_infobox {
  my $self = shift();
  my $cfg = shift();
  if ($self->is_whiptail()) {
    $cfg->{'sleep'} = 0 if $cfg->{'sleep'};
    return($self->msgbox($cfg));
  }
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --scrolltext" unless (!$self->is_whiptail() || $self->{'scrolltext'});
  $attrs .= " --infobox ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $self->__RUN_DIALOG($attrs);
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rv());
}

#: INPUTBOX
sub inputbox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_inputbox($cfg)); }
  else { return($self->__dialog_inputbox($cfg)); }
}
sub __ascii_inputbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  my $length = $self->{'max-input'} + 1;
  my $text = $self->{'text'};
  chomp($text);
  while($length > $self->{'max-input'}) {
    $self->__ASCII_WRITE_TEXT({'text'=>$self->{'text'}});
    if ($self->{'use_stderr'}) {
      print STDERR "input: ";
    } else {
      print STDOUT "input: ";
    }
    chomp($self->{'return_string'} = <STDIN>);
    $length = length($self->{'return_string'});
    if ($length > $self->{'max-input'}) {
      if ($self->{'use_stderr'}) {
	print STDERR "error: too many charaters input,".
	 " the maximum is: ".$self->{'max-input'}."\n";
      } else {
	print STDOUT "error: too many charaters input,".
	 " the maximum is: ".$self->{'max-input'}."\n";
      }
    }
  }
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_inputbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --scrolltext" unless (!$self->is_whiptail() || $self->{'scrolltext'});
  $attrs .= " --inputbox ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $attrs .= " \"".$cfg->{'init'}."\"" if $cfg->{'init'};
  my $length = $self->{'max-input'} + 1;
  while ($length > $self->{'max-input'}) {
    $self->__RUN_DIALOG($attrs,'string');
    $self->__CLEAR();
    $self->__CALLBACKS();
    $length = length($self->{'return_string'});
    if ($length > $self->{'max-input'}) {
      $self->msgbox({'title'=>'error',
		      'text'=>['The maximum allowed input is '.$self->{'max-input'}.' characters.',
			       'You entered in: '.$length.' characters.']});
    }
  }
  return($self->rs());
}

#: PASSWORDBOX
sub passwordbox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_passwordbox($cfg)); }
  else { return($self->__dialog_passwordbox($cfg)); }
}
sub __ascii_passwordbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  my ($length,$key) = ($self->{'max-input'} + 1,'');
  my $text = $self->{'text'};
  chomp($text);
  my $ENV_PATH = $ENV{'PATH'};
  $ENV{'PATH'} = "";
  while ($length > $self->{'max-input'}) {
    $self->__ASCII_WRITE_TEXT({'text'=>$self->{'text'}});
    if ($self->{'use_stderr'}) {
      print STDERR "input: ";
    } else {
      print STDOUT "input: ";
    }
    if ($self->is_bsd()) { system "$self->{'sttybin'} cbreak </dev/tty >/dev/tty 2>&1"; }
    else { system $self->{'sttybin'}, '-icanon', 'eol', "\001"; }
    while($key = getc(STDIN)) {
      last if $key =~ /\n/;
      if ($self->{'use_stderr'}) {
	print STDERR "\b*";
      } else {
	print STDOUT "\b*";
      }
      $self->{'return_string'} .= $key;
    }
    if ($self->is_bsd()) { system "$self->{'sttybin'} -cbreak </dev/tty >/dev/tty 2>&1"; }
    else { system $self->{'sttybin'}, 'icanon', 'eol', '^@'; }
    if ($self->{'return_string'}) { $length = length($self->{'return_string'}); }
    else { $length = 0; }
    if ($length > $self->{'max-input'}) {
      if ($self->{'use_stderr'}) {
	print STDERR "error: too many charaters input,".
	 " the maximum is: ".$self->{'max-input'}."\n";
      } else {
	print STDOUT "error: too many charaters input,".
	 " the maximum is: ".$self->{'max-input'}."\n";
      }
    }
  }
  $ENV{'PATH'} = $ENV_PATH;
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_passwordbox {
  my $self = shift();
  my $cfg = shift();
  return() unless !$self->is_dialog() and !$self->is_gdialog() and !$self->is_kdialog();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --scrolltext" unless (!$self->is_whiptail() || $self->{'scrolltext'});
  $attrs .= " --passwordbox ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $attrs .= " \"".$cfg->{'init'}."\"" if $cfg->{'init'};
  my $length = $self->{'max-input'} + 1;
  while ($length > $self->{'max-input'}) {
    $self->__RUN_DIALOG($attrs,'string');
    $self->__CLEAR();
    $self->__CALLBACKS();
    $length = length($self->{'return_string'});
    if ($length > $self->{'max-input'}) {
      $self->msgbox({'title'=>'error',
		      'text'=>['The maximum allowed input is '.$self->{'max-input'}.' characters.',
			       'You entered in: '.$length.' characters.']});
    }
  }
  return($self->rs());
}

#: TEXTBOX
sub textbox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_textbox($cfg)); }
  else { return($self->__dialog_textbox($cfg)); }
}
sub __ascii_textbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  if (-r $cfg->{'file'}) {
    my $ENV_PATH = $ENV{'PATH'};
    $ENV{'PATH'} = "";
    if ($ENV{'PAGER'}) {
      system($ENV{'PAGER'}." ".$cfg->{'file'});
    } elsif (-x $self->{'pager'}) {
      system($self->{'pager'}." ".$cfg->{'file'});
    } else {
      my $TS = $/; undef($/);
      open(ATBFILE,"<".$cfg->{'file'});
      my $data = <ATBFILE>;
      close(ATBFILE);
      $/ = $TS;
      if ($self->{'use_stderr'}) {
	print STDERR $data;
      } else {
	print STDOUT $data;
      }
    }
    $ENV{'PATH'} = $ENV_PATH;
  } else {
    return($self->msgbox({'title'=>'error','text'=>$cfg->{'file'}.' is not a readable text file.'}));
  }
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_textbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  if ($self->is_gdialog() || $self->is_kdialog()) {
    $self->{'rf'} = $cfg->{'file'};
    open(GTBIN,"<".$self->{'rf'}) or return();
    my $TS = $/;
    undef($/);
    my $txt = <GTBIN>;
    $/ = $TS;
    close(GTBIN);
    $txt =~ s/\t/    /gm;
    $self->{'file'} = $self->{'tmpdir'}."/".basename($self->{'rf'})."_".time.".tmp";
    open(GTBOUT,"+>".$self->{'file'}) or return();
    print GTBOUT $txt;
    close(GTBOUT);
  }
  $attrs .= " --scrolltext" unless (!$self->is_whiptail() || $self->{'scrolltext'});
  $attrs .= " --textbox ";
  $attrs .= " ".$cfg->{'file'};
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $self->__RUN_DIALOG($attrs);
  unlink($self->{'file'}) if $self->{'file'} && -e $self->{'file'};
  $self->{'file'} = $self->{'rf'};  undef($self->{'rf'});
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rv());
}

#: MENU
sub menu {
  my $self = shift();
  my $cfg = shift();
  if (ref($cfg->{'menu'}) eq "ARRAY") {
    $self->__TEST_MENU_ARGS($cfg->{'menu'}) or return();
  } elsif (ref($cfg->{'list'}) eq "ARRAY") {
    $self->__TEST_MENU_ARGS($cfg->{'list'}) or return();
  }
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_menu($cfg)); }
  else { return($self->__dialog_menu($cfg)); }
}
sub __ascii_menu {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  $cfg->{'menu'} = $cfg->{'list'} if ref($cfg->{'list'}) eq "ARRAY";

  my $rs = '';
  my $m;
  $m = @{$cfg->{'menu'}} if ref($cfg->{'menu'}) eq "ARRAY";
  my ($valid,$menu,$realm) = ([],[],[]);
  push(@{$menu},@{$cfg->{'menu'}}) if ref($cfg->{'menu'}) eq "ARRAY";

  for (my $i = 0; $i < $m; $i += 2) { push(@{$valid},$menu->[$i]); }

  if (@{$menu} >= 60) {
    my $c = 0;
    while (@{$menu}) {
      $realm->[$c] = [];
      for (my $i = 0; $i < 60; $i++) {
	push(@{$realm->[$c]},shift(@{$menu}));
      }
      $c++;
    }
  } else {
    $realm->[0] = [];
    push(@{$realm->[0]},@{$menu});
  }
  my $pg = 1;
  while (!$rs) {
    $self->__ASCII_WRITE_MENU({'title'=>$self->{'title'},'text'=>$self->{'text'},
			       'menu'=>$realm->[($pg - 1||0)]});
    if ($self->{'use_stderr'}) {
      print STDERR "(".$pg."/".@{$realm}."): ";
    } else {
      print STDOUT "(".$pg."/".@{$realm}."): ";
    }
    chomp($rs = <STDIN>);
    if ($rs =~ /^:\?$/i) {
      $self->__CLEAR();
      $self->__ASCII_NAV_HELP();
      undef($rs);
      next;
    } elsif ($rs =~ /^:(esc|escape)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 255;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif (($self->{'extra-button'} || $self->{'extra-label'}) && $rs =~ /^:(e|extra)$/i) {
      $self->{'return_value'} = 3;
      $self->__CALLBACKS();
      return($self->state());
    } elsif ($self->{'help-button'} && $rs =~ /^:(h|help)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 2;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif (!$self->{'nocancel'} && $rs =~ /^:(c|cancel)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 1;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif ($rs =~ /^:pg\s*(\d+)$/i) {
      my $p = $1;
      if ($p <= @{$realm} && $p > 0) { $pg = $p; }
      undef($rs);
    } elsif ($rs =~ /^:(n|next)$/i) {
      if ($pg < @{$realm}) { $pg++; }
      else { $pg = 1; }
      undef($rs);
    } elsif ($rs =~ /^:(p|prev)$/i) {
      if ($pg > 1) { $pg--; }
      else { $pg = @{$realm}; }
      undef($rs);
    } else {
      if (@_ = grep { /^\Q$rs\E$/i } @{$valid}) { $self->{'return_string'} = $_[0]; }
      else { undef($rs); }
    }
    $self->__CLEAR();
  }

  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_menu {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $cfg->{'menu'} = $cfg->{'list'} if ref($cfg->{'list'}) eq "ARRAY";
  if (!$self->is_cdialog()) {
    if ($cfg->{'extra-button'} || $cfg->{'extra-label'} ||
	$self->{'extra-button'} || $self->{'extra-label'}) {
      push(@{$cfg->{'menu'}},":e",($cfg->{'extra-label'}||$self->{'extra-label'}||"Extra"))
       unless grep { /^\:e$/ } @{$cfg->{'menu'}};
      undef($cfg->{'extra-label'});
      undef($cfg->{'extra-button'});
    }
    if ($cfg->{'help-button'} || $cfg->{'help-label'} ||
	$self->{'help-button'} || $self->{'help-label'}) {
      push(@{$cfg->{'menu'}},":h",($cfg->{'help-label'}||$self->{'help-label'}||"Help"))
       unless grep { /^\:h$/ } @{$cfg->{'menu'}};
      undef($cfg->{'help-label'});
      undef($cfg->{'help-button'});
    }
    $cfg->{'list-height'} = (@{$cfg->{'menu'}} / 2) if $self->is_gdialog() || $self->is_kdialog();
  }
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --menu ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'}." ".$self->{'list-height'};
  $attrs .= ' "'.join('" "',@{$cfg->{'menu'}}).'"';
  $self->__RUN_DIALOG($attrs,'string');
  $self->__CLEAR();
  $self->__CALLBACKS();
  if ($self->rs() eq ":e") {
    $self->{'return_value'} = 3;
    return($self->state());
  } elsif ($self->rs() eq ":h") {
    $self->{'return_value'} = 2;
    return($self->state());
  }
  return($self->rs());
}

#: RADIOLIST
sub radiolist {
  my $self = shift();
  my $cfg = shift();
  if (ref($cfg->{'menu'}) eq "ARRAY") {
    $self->__TEST_LIST_ARGS($cfg->{'menu'}) or return();
  } elsif (ref($cfg->{'list'}) eq "ARRAY") {
    $self->__TEST_LIST_ARGS($cfg->{'list'}) or return();
  }
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_radiolist($cfg)); }
  else { return($self->__dialog_radiolist($cfg)); }
}
sub __ascii_radiolist {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  $cfg->{'menu'} = $cfg->{'list'} if ref($cfg->{'list'}) eq "ARRAY";

  my $rs = '';
  my $m;
  $m = @{$cfg->{'menu'}} if ref($cfg->{'menu'}) eq "ARRAY";
  my ($valid,$menu,$realm) = ([],[],[]);
  push(@{$menu},@{$cfg->{'menu'}}) if ref($cfg->{'menu'}) eq "ARRAY";

  for (my $i = 0; $i < $m; $i += 3) { push(@{$valid},$menu->[$i]); }

  if (@{$menu} >= 90) {
    my $c = 0;
    while (@{$menu}) {
      $realm->[$c] = [];
      for (my $i = 0; $i < 90; $i++) {
	push(@{$realm->[$c]},shift(@{$menu}));
      }
      $c++;
    }
  } else {
    $realm->[0] = [];
    push(@{$realm->[0]},@{$menu});
  }
  my $pg = 1;
  while (!$rs) {
    $self->__ASCII_WRITE_LIST({'text'=>$self->{'text'},'menu'=>$realm->[($pg - 1||0)]});
    if ($self->{'use_stderr'}) {
      print STDERR "(".$pg."/".@{$realm}."): ";
    } else {
      print STDOUT "(".$pg."/".@{$realm}."): ";
    }
    chomp($rs = <STDIN>);
    if ($rs =~ /^:\?$/i) {
      $self->__CLEAR();
      $self->__ASCII_NAV_HELP();
      undef($rs);
      next;
    } elsif ($rs =~ /^:(esc|escape)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 255;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif (($self->{'extra-button'} || $self->{'extra-label'}) && $rs =~ /^:(e|extra)$/i) {
      $self->{'return_value'} = 3;
      $self->__CALLBACKS();
      return($self->state());
    } elsif ($self->{'help-button'} && $rs =~ /^:(h|help)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 2;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif (!$self->{'nocancel'} && $rs =~ /^:(c|cancel)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 1;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif ($rs =~ /^:pg\s*(\d+)$/i) {
      my $p = $1;
      if ($p <= @{$realm} && $p > 0) { $pg = $p; }
      undef($rs);
    } elsif ($rs =~ /^:(n|next)$/i) {
      if ($pg < @{$realm}) { $pg++; }
      else { $pg = 1; }
      undef($rs);
    } elsif ($rs =~ /^:(p|prev)$/i) {
      if ($pg > 1) { $pg--; }
      else { $pg = @{$realm}; }
      undef($rs);
    } else {
      if (@_ = grep { /^\Q$rs\E$/i } @{$valid}) { $self->{'return_string'} = $_[0]; }
      else { undef($rs); }
    }
    $self->__CLEAR();
    $self->__CALLBACKS();
  }

  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_radiolist {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $cfg->{'menu'} = $cfg->{'list'} if ref($cfg->{'list'}) eq "ARRAY";
  if (!$self->is_cdialog()) {
    if ($cfg->{'extra-button'} || $cfg->{'extra-label'} ||
	$self->{'extra-button'} || $self->{'extra-label'}) {
      push(@{$cfg->{'menu'}},":e",($cfg->{'extra-label'}||$self->{'extra-label'}||"Extra"),'off')
       unless grep { /^\:e$/ } @{$cfg->{'menu'}};
      undef($cfg->{'extra-label'});
      undef($cfg->{'extra-button'});
    }
    if ($cfg->{'help-button'} || $cfg->{'help-label'} ||
	$self->{'help-button'} || $self->{'help-label'}) {
      push(@{$cfg->{'menu'}},":h",($cfg->{'help-label'}||$self->{'help-label'}||"Help"),'off')
       unless grep { /^\:h$/ } @{$cfg->{'menu'}};
      undef($cfg->{'help-label'});
      undef($cfg->{'help-button'});
    }
  }

  my $menu = [];
  push(@{$menu},@{$cfg->{'menu'}});
  my $tmp;
  my $m = @{$menu};
  for (my $i = 2; $i < $m; $i += 3) {
    if (!$tmp && $menu->[$i] =~ /on/i) {
      $menu->[$i] = 'on'; $tmp = "STOP";
    } else { $menu->[$i] = 'off'; }
  }

  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --radiolist ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'}." ".$self->{'list-height'};
  $attrs .= ' "'.join('" "',@{$menu}).'"';
  $self->__RUN_DIALOG($attrs,'string');
  $self->__CLEAR();
  $self->__CALLBACKS();
  if ($self->is_gdialog || $self->is_kdialog()) {
    if ($self->rs() eq ":e") {
      $self->{'return_value'} = 3;
      $self->{'return_string'} = '';
    } elsif ($self->rs() eq ":h") {
      $self->{'return_value'} = 2;
      $self->{'return_string'} = '';
    }
  }
  return(($self->rs()||$self->state()));
}

#: CHECKLIST
sub checklist {
  my $self = shift();
  my $cfg = shift();
  if (ref($cfg->{'menu'}) eq "ARRAY") {
    $self->__TEST_LIST_ARGS($cfg->{'menu'}) or return();
  } elsif (ref($cfg->{'list'}) eq "ARRAY") {
    $self->__TEST_LIST_ARGS($cfg->{'list'}) or return();
  }
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return($self->__ascii_checklist($cfg)); }
  else { return($self->__dialog_checklist($cfg)); }
}
sub __ascii_checklist {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  $cfg->{'menu'} = $cfg->{'list'} if ref($cfg->{'list'}) eq "ARRAY";

  my $rs = '';
  my $m;
  $m = @{$cfg->{'menu'}} if ref($cfg->{'menu'}) eq "ARRAY";
  my ($valid,$menu,$realm) = ([],[],[]);
  push(@{$menu},@{$cfg->{'menu'}}) if ref($cfg->{'menu'}) eq "ARRAY";

  for (my $i = 0; $i < $m; $i += 3) { push(@{$valid},$menu->[$i]); }

  if (@{$menu} >= 90) {
    my $c = 0;
    while (@{$menu}) {
      $realm->[$c] = [];
      for (my $i = 0; $i < 90; $i++) {
	push(@{$realm->[$c]},shift(@{$menu}));
      }
      $c++;
    }
  } else {
    $realm->[0] = [];
    push(@{$realm->[0]},@{$menu});
  }
  my $go = "GO";
  my $pg = 1;
  while ($go) {
    $self->__ASCII_WRITE_LIST({'title'=>$self->{'title'},'wm'=>'check',
			       'text'=>$self->{'text'},'menu'=>$realm->[($pg - 1||0)]});
    if ($self->{'use_stderr'}) {
      print STDERR "(".$pg."/".@{$realm}."): ";
    } else {
      print STDOUT "(".$pg."/".@{$realm}."): ";
    }
    chomp($rs = <STDIN>);
    if ($rs =~ /^:\?$/i) {
      $self->__CLEAR();
      $self->__ASCII_NAV_HELP();
      undef($rs);
      next;
    } elsif ($rs =~ /^:(esc|escape)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 255;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif (($self->{'extra-button'} || $self->{'extra-label'}) && $rs =~ /^:(e|extra)$/i) {
      $self->{'return_value'} = 3;
      $self->__CALLBACKS();
      return($self->state());
    } elsif ($self->{'help-button'} && $rs =~ /^:(h|help)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 2;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif (!$self->{'nocancel'} && $rs =~ /^:(c|cancel)$/i) {
      $self->__CLEAR();
      undef($rs);
      $self->{'return_value'} = 1;
      $self->__CALLBACKS();
      return($self->rv());
    } elsif ($rs =~ /^:pg\s*(\d+)$/i) {
      my $p = $1;
      if ($p <= @{$realm} && $p > 0) { $pg = $p; }
    } elsif ($rs =~ /^:(n|next)$/i) {
      if ($pg < @{$realm}) { $pg++; }
      else { $pg = 1; }
    } elsif ($rs =~ /^:(p|prev)$/i) {
      if ($pg > 1) { $pg--; }
      else { $pg = @{$realm}; }
    } else {
      my @opts = split(/\,\s|\,|\s/,$rs);
      my @good;
      foreach my $opt (@opts) {
	if (@_ = grep { /^\Q$opt\E$/i } @{$valid}) { push(@good,$_[0]); }
      }
      if (@opts == @good) {
	undef($go);
	$self->{'return_array'} = [];
	push(@{$self->{'return_array'}},@good);
      }
    }
    $self->__CLEAR();
    $self->__CALLBACKS();
    undef($rs);
  }

  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->ra());
}
sub __dialog_checklist {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $cfg->{'menu'} = $cfg->{'list'} if ref($cfg->{'list'}) eq "ARRAY";
  if (!$self->is_cdialog()) {
    if ($cfg->{'extra-button'} || $cfg->{'extra-label'} ||
	$self->{'extra-button'} || $self->{'extra-label'}) {
      push(@{$cfg->{'menu'}},":e",($cfg->{'extra-label'}||$self->{'extra-label'}||"Extra"),'off')
       unless grep { /^\:e$/ } @{$cfg->{'menu'}};
      undef($cfg->{'extra-label'});
      undef($cfg->{'extra-button'});
    }
    if ($cfg->{'help-button'} || $cfg->{'help-label'} ||
	$self->{'help-button'} || $self->{'help-label'}) {
      push(@{$cfg->{'menu'}},":h",($cfg->{'help-label'}||$self->{'help-label'}||"Help"),'off')
       unless grep { /^\:h$/ } @{$cfg->{'menu'}};
      undef($cfg->{'help-label'});
      undef($cfg->{'help-button'});
    }
  }
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --separate-output" unless $self->{'separate-output'};
  $attrs .= " --checklist ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'}." ".$self->{'list-height'};
  $attrs .= ' "'.join('" "',@{$cfg->{'menu'}}).'"';
  $self->__RUN_DIALOG($attrs,'array');
  $self->__CLEAR();
  $self->__CALLBACKS();
  if ($self->is_gdialog || $self->is_kdialog()) {
    if (grep { /^:e$/ } $self->ra()) {
      $self->{'return_value'} = 3;
      $self->{'return_array'} = undef();
    } elsif (grep { /^:h$/ } $self->ra()) {
      $self->{'return_value'} = 2;
      $self->{'return_array'} = undef();
    }
  }
  return(($self->ra()||$self->state()));
}

#: CALENDAR
sub calendar {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return(); }
  else { return($self->__dialog_calendar($cfg)); }
}
sub __dialog_calendar {
  my $self = shift();
  my $cfg = shift();
  return() unless $self->is_cdialog();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --calendar ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $attrs .= " ".($cfg->{'day'}||'0')." ".($cfg->{'month'}||'0')." ".($cfg->{'year'}||'0');
  $self->__RUN_DIALOG($attrs,'string');
  $self->{'return_array'} = [split(/\//,$self->{'return_string'})];
  $self->{'return_value'} = $? >> 8;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->ra());
}

#: fselect
sub fselect {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->is_cdialog()) { return($self->__cdialog_fselect($cfg)); }
  else { return($self->__dialog_fselect($cfg)); }
}
sub __cdialog_fselect {
  my $self = shift();
  my $cfg = shift();
  return() unless $self->is_cdialog();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  if (!$cfg->{'path'} || $cfg->{'path'} =~ /(\.|\.\/)$/) { $cfg->{'path'} = abs_path(); }
  $attrs .= " --fselect ";
  $attrs .= "\"".($cfg->{'path'}||"/")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $self->__RUN_DIALOG($attrs,'string');
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_fselect {
  my $self = shift();
  my $cfg = shift();
  return() if $self->is_cdialog();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  my $path = $cfg->{'path'};
  if (!$path || $path =~ /(\.|\.\/)$/) { $path = abs_path(); }
  my $file;
  my ($menu,$list) = ([],[]);
 DDSEL: while (-d $path && ($self->state() ne "ESC" && $self->state() ne "CANCEL")) {
    ($menu, $list) = $self->__GET_DIR($path,['[enter new]']);
    $file = $self->menu({'height'=>$self->{'height'},'width'=>$self->{'width'},'list-height'=>$self->{'list-height'},
			 'title'=>$self->{'title'},'text'=>$path,'menu'=>$menu});
    if ($file ne "") {
      if ($list->[($file - 1 || 0)] eq "[enter new]") {
	my $nfn;
	while (!$nfn || -e $path."/".$nfn) {
	  $nfn = $self->inputbox({'height'=>$self->{'height'},'width'=>$self->{'width'},
				  'title'=>$self->{'title'},'text'=>'Enter a new name with a base directory of: '.$path});
	  next DDSEL if $self->state() eq "ESC" or $self->state() eq "CANCEL";
	  if (-e $path."/".$nfn) { $self->msgbox({'title'=>'error','text'=>$path."/".$nfn.' already exists! Choose another name please.'}); }
	}
	$file = $path."/".$nfn;
	$file =~ s!/$!! unless $file =~ m!^/$!;
	$file =~ s!/\./!/!g; $file =~ s!/+!/!g;
	last DDSEL;
      } elsif ($list->[($file - 1 || 0)] eq "../") {
	$path = dirname($path);
      } elsif ($list->[($file - 1 || 0)] eq "./") {
	$file = $path;
	$file =~ s!/$!! unless $file =~ m!^/$!;
	$file =~ s!/\./!/!g; $file =~ s!/+!/!g;
	last DDSEL;
      } elsif (-d $path."/".$list->[($file - 1 || 0)]) {
	$path = $path."/".$list->[($file - 1 || 0)];
      } elsif (-e $path."/".$list->[($file - 1 || 0)]) {
	$file = $path."/".$list->[($file - 1 || 0)];
	$file =~ s!/$!! unless $file =~ m!^/$!;
	$file =~ s!/\./!/!g; $file =~ s!/+!/!g;
	last DDSEL;
      }
    }
    $file = undef();
    $path =~ s!(/*)!/!; $path =~ s!/\./!/!g;
  }
  $self->{'return_string'} = $file;
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}

#: tailbox
sub tailbox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { $self->__ascii_tailbox($cfg); }
  else { return($self->__dialog_tailbox($cfg)); }
}
sub __ascii_tailbox {
  my $self = shift();
  my $cfg = shift();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  $self->__ATTRIBUTE($cfg);
  $self->clear() if $self->{'auto-clear'};
  if (-r $cfg->{'file'}) {
    if (-x $self->{'tail'}) {
      if ($self->{'use_stderr'}) {
	print STDERR "+---------------------------------------------------------------------+\n";
	my $string = "| Tailing:                                                            |";
	substr($string,11,length($cfg->{'file'}),$cfg->{'file'});
	print STDERR $string."\n";
	print STDERR "|      *** Press <CONTROL> + <C> to exit 'tail' and return. ***       |\n";
	print STDERR "+---------------------------------------------------------------------+\n";
	system($self->{'tail'}." ".$self->{'tailopt'}." ".$cfg->{'file'}." 1>2&");
      } else {
	print STDOUT "+---------------------------------------------------------------------+\n";
	my $string = "| Tailing:                                                            |";
	substr($string,11,length($cfg->{'file'}),$cfg->{'file'});
	print STDOUT $string."\n";
	print STDOUT "|      *** Press <CONTROL> + <C> to exit 'tail' and return. ***       |\n";
	print STDOUT "+---------------------------------------------------------------------+\n";
	system($self->{'tail'}." ".$self->{'tailopt'}." ".$cfg->{'file'});
      }
    } else { $self->textbox($cfg); }
  } else {
    return($self->msgbox({'title'=>'error','text'=>$self->{'file'}.' is not a readable text file.'}));
  }
  $self->{'return_value'} = 0;
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rs());
}
sub __dialog_tailbox {
  my $self = shift();
  my $cfg = shift();
  return() unless $self->is_cdialog();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  if (!-r $cfg->{'file'}) {
    $self->msgbox({text=>$cfg->{'file'}.' is not readable, or does not exist.', 'title'=>'error'});
    return();
  }
  $attrs .= " --tailbox ";
  $attrs .= $cfg->{'file'};
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  $self->__RUN_DIALOG($attrs);
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->rv());
}

#: TIMEBOX
sub timebox {
  my $self = shift();
  my $cfg = shift();
  $self->__BEEP($cfg);
  if ($self->{'ascii'}) { return(); }
  else { return($self->__dialog_timebox($cfg)); }
}
sub __dialog_timebox {
  my $self = shift();
  my $cfg = shift();
  return() unless $self->is_cdialog();
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --timebox ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ";
  $attrs .= $self->{'width'} if $self->{'width'};
  $attrs .= " ".($cfg->{'hour'}||'0')." ".($cfg->{'minute'}||'0')." ".($cfg->{'second'}||'0');
  $self->__RUN_DIALOG($attrs,'string');
  $self->{'return_array'} = [split(/:/,$self->{'return_string'})];
  $self->__CLEAR();
  $self->__CALLBACKS();
  return($self->ra());
}


sub start_gauge {
  my $self = shift();
  my $cfg = shift();
  return(254) if defined $self->{'__GAUGE'};
#  return() unless !$self->is_gdialog() and !$self->is_kdialog();
  $self->__BEEP($cfg);
  $self->__CLEAN_RVALUES();
  $self->__CLEAN_ATTRS();
  my $attrs = $self->__GET_ATTR_STR($cfg);
  $attrs .= " --gauge ";
  $attrs .= "\"".($self->{'text'}||" ")."\"";
  $attrs .= " ".$self->{'height'}." ".$self->{'width'};
  if (($self->is_gdialog() || $self->is_kdialog()) && !$self->{'percent'}) { $self->{'percent'} = 1; }
  $attrs .= " ".($self->{'percent'}||1);
  $self->{'__GAUGE'} = new FileHandle;
  $self->{'__GAUGE'}->open("| $self->{'dialog'} $attrs 2>&1");
  $self->{'return_value'} = $? >> 8;
  $self->{'__GAUGE'}->autoflush(1);
  return($self->rv());
}

sub msg_gauge {
  my $self = shift();
  my $mesg = shift() || return(0);
  return(254) unless defined $self->{'__GAUGE'};
#  return() unless !$self->is_gdialog() and !$self->is_kdialog() and !$self->is_whiptail();
  $self->__BEEP();
  $self->__CLEAN_RVALUES();
  chomp($mesg);
  my $fh = $self->{'__GAUGE'};
  print $fh "XXX\n".$self->__TRANSLATE($mesg)."\nXXX\n";
}

sub inc_gauge {
  my $self = shift();
  my $incr = shift() || 1;
  return(254) unless defined $self->{'__GAUGE'};
#  return() unless !$self->is_gdialog() and !$self->is_kdialog();
  $self->__CLEAN_RVALUES();
  chomp($incr);
  $self->{'percent'} += $incr;
  my $fh = $self->{'__GAUGE'};
  print $fh $self->{'percent'}."\n";
}

sub dec_gauge {
  my $self = shift();
  my $decr = shift() || 1;
  return(254) unless defined $self->{'__GAUGE'};
#  return() unless !$self->is_gdialog() and !$self->is_kdialog();
  $self->__CLEAN_RVALUES();
  chomp($decr);
  $self->{'percent'} -= $decr;
  my $fh = $self->{'__GAUGE'};
  print $fh $self->{'percent'}."\n";
}

sub set_gauge {
  my $self = shift();
  my $value = shift();
  return(254) unless defined $self->{'__GAUGE'};
#  return() unless !$self->is_gdialog() and !$self->is_kdialog();
  $self->__CLEAN_RVALUES();
  chomp($value);
  $self->{'percent'} = $value;
  my $fh = $self->{'__GAUGE'};
  print $fh $self->{'percent'}."\n";
}

sub end_gauge {
  my $self = shift();
  return(254) unless defined $self->{'__GAUGE'};
#  return() unless !$self->is_gdialog() and !$self->is_kdialog();
  $self->__CLEAN_RVALUES();
  my $fh = $self->{'__GAUGE'};
  print $fh "\x04";
  $self->{'__GAUGE'}->close();
  undef($self->{'__GAUGE'});
  $self->__CLEAR();
}

sub ascii_spinner {
  my $self = shift();
  if (!$self->{'__SPIN'} || $self->{'__SPIN'} == 1) { $self->{'__SPIN'} = 2; return("\b|"); }
  elsif ($self->{'__SPIN'} == 2) { $self->{'__SPIN'} = 3; return("\b/"); }
  elsif ($self->{'__SPIN'} == 3) { $self->{'__SPIN'} = 4; return("\b-"); }
  elsif ($self->{'__SPIN'} == 4) { $self->{'__SPIN'} = 1; return("\b\\"); }
}



1;
__END__


=head1 NAME

UDPM - Perl extension for User Dialogs

=head1 SYNOPSIS

  use UDPM;
  my $d = new UDPM ({'backtitle'=>'Demo','colours'=>1,'cr-wrap'=>1,
	 	     'height'=>20,'width'=>70,'list-height'=>5,
		     'no-shadows'=>1});

  $d->msgbox({'title'=>'Welcome!',
	      'text'=>'[B]Welcome[/B] [U]one[/U] and [R]all[/R]!'});

=head1 ABSTRACT

UserDialogPerlModule is simply an OOPerl wrapper for the dialog
application(s). This version of UDPM supports dialog, cdialog
(aka: dialog ver. 0.9b), whiptail, gdialog and kdialog. There
is also an ASCII dialog mode (as a fallback for systems without
a dialog variant).

=head1 DESCRIPTION

UDPM strives to be full-featured and robust in everything to do
with simple end-user interfaces. Care has been taken to provide
a clean OO interface to common command line utilities as well as
providing a native ascii mode simulating the various interface
widgets.

=head1 EXPORT

Nothing.

=head1 PACKAGE METHODS

=over 2

=head2 new()

=over 4

=item EXAMPLE

=over 6

 my $d = new(\%my_defaults);

=back

=item DESCRIPTION

=over 6

This is the Class Constructor method. The only argument it takes
is a hash reference containing valid configuration keys and values.
See REGARDING ATTRIBUTES below for more details. A UDPM object reference
with the defaults defined in the arguments is returned. These
defaults are overridable on a per method call basis.

=back

=back

=back

=over 2

=head2 state()

=over 4

=item EXAMPLE

=over 6

 while ($d->state() ne "ESC" || $d->state() ne "CANCEL") {
   ...
 }

=back

=item DESCRIPTION

=over 6

This method returns a string describing the last exit state of
any widget. Valid states are: "OK" "ESC" "CANCEL" "EXTRA" "HELP"
"UNKNOWN".

=back

=back

=back

=over 2

=head2 rv()

=over 4

=item EXAMPLE

=over 6

 exit($d->rv());

=back

=item DESCRIPTION

=over 6

This returns the last return value (aka: exit value) for the last
widget displayed.

=back

=back

=back

=over 2

=head2 rs()

=over 4

=item EXAMPLE

=over 6

 $d->inputbox({'text'=>'testing'});
 my $input = $d->rs();

=back

=item DESCRIPTION

=over 6

This returns the last return strign (aka: user-input) for the last
widget displayed. Some widgets do not have a return string and instead
have a return array.

=back

=back

=back

=over 2

=head2 ra()

=over 4

=item EXAMPLE

=over 6

 $d->checklist({'text'=>'test','menu'=>['1','one','off','2','two','off']});
 my @selected = $d->ra();

=back

=item DESCRIPTION

=over 6

This returns the last return array (aka: multi-user-input) for the last
widget displayed. Some widgets do not have a return array and instead have
a return string.

=back

=back

=back

=over 2

=head2 attribute()

=over 4

=item EXAMPLE

=over 6

 $d->attribute({'attr'=>'val','attr2'=>'val2'});
 $d->attribute('attr','val');
 my $val = $d->attribute('attr');

=back

=item DESCRIPTION

=over 6

This method will alter the defaults within the UDPM object.
There are three ways to use this method. The first is to pass
a hash reference containing all the attribute -> value pairs
to be altered. The second is to pass two scalars, the first is
the attibute name, and the second is the value to set it to.
The third is to simply pass only the name of an attribute
and it will return that attribute's current value.

=back

=back

=back

=over 2

=head2 is_attr()

=over 4

=item EXAMPLE

=over 6

 print "has attribute" if $d->is_attr('attribute');

=back

=item DESCRIPTION

=over 6

The only argument is the name of a desired attribute.
Returns TRUE (1) if the argument is a valid atrribute and
FALSE (0) if the argument is not.

=back

=back

=back

=over 2

=head2 is_linux()

=over 4

=item EXAMPLE

=over 6

 print "you're running Linux!\n" if $d->is_linux();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if $^O contains "linux".

=back

=back

=back

=over 2

=head2 is_bsd()

=over 4

=item EXAMPLE

=over 6

 print "you're running BSD!\n" if $d->is_bsd();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if $^O contains "bsd".

=back

=back

=back

=over 2

=head2 is_ascii()

=over 4

=item EXAMPLE

=over 6

 print "you're using the native (ascii) dialog mode!\n" if $d->is_ascii();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if the dialog type is
the native (ascii) dialog. This dialog type is binary-independant
thus making this module more versatile as it no longer depends on
the worlds outside of Perl.

=back

=back

=back

=over 2

=head2 is_dialog()

=over 4

=item EXAMPLE

=over 6

 print "you're using the origional dialog!\n" if $d->is_dialog();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if the dialog type is
the origional dialog.

=back

=back

=back

=over 2

=head2 is_cdialog()

=over 4

=item EXAMPLE

=over 6

 print "you're using the (ComeOn) dialog v0.9!\n" if $d->is_cdialog();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if the dialog type is
the (ComeOn) dialog v0.9.

=back

=back

=back

=over 2

=head2 is_whiptail()

=over 4

=item EXAMPLE

=over 6

 print "you're using whiptail!\n" if $d->is_cdialog();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if the dialog type is
whiptail.

=back

=back

=back

=over 2

=head2 is_gdialog()

=over 4

=item EXAMPLE

=over 6

 print "you're using the Gtk/Gnome dialog!\n" if $d->is_gdialog();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if the dialog type is
the Gtk/Gnome dialog.

=back

=back

=back

=over 2

=head2 is_kdialog()

=over 4

=item EXAMPLE

=over 6

 print "you're using the KDE dialog!\n" if $d->is_kdialog();

=back

=item DESCRIPTION

=over 6

This is a very simple method that returns 1 if the dialog type is
the KDE dialog.

=back

=back

=back

=head1 WIDGET METHODS

=over 2

=head2 clear()

=over 4

=item EXAMPLE

=over 6

 $d->clear();

=back

=item DESCRIPTION

=over 6

This method caches the output of a `clear` and simply prints that
whenever called. This does nothing with gui-based dialog variants.

=back

=back

=back

=over 2

=head2 infobox()

=over 4

=item EXAMPLE

=over 6

 $d->infobox({'text'=>'example','sleep'=>1});

=back

=item DESCRIPTION

=over 6

This method displays the infobox widget. The 'sleep' attribute
is available for _all_ widgets but is most commonly used with
infobox(). This widget behaves differently depending on the
dialog variation used. Of special note is whiptail which will
simply diaplay and exit which for the most part is what you want
but when using whiptail in an X session (via an xterm for instance)
the screen will clear right away and the message is lost.  The only
work-around for this is to check for the 'DISPLAY' environemnt variable
if whiptail is being used and substitute the infobox widget with a msgbox;
which UDPM does automagically.

=back

=back

=back

=over 2

=head2 msgbox()

=over 4

=item EXAMPLE

=over 6

 $d->msgbox({'text'=>'example'});

=back

=item DESCRIPTION

=over 6

This method displays the msgbox widget.

=back

=back

=back

=over 2

=head2 textbox()

=over 4

=item EXAMPLE

=over 6

 $d->textbox({'file'=>'/path/and/file/name'});

=back

=item DESCRIPTION

=over 6

This method displays the textbox widget (which in turn displays the
specified text file).

=back

=back

=back

=over 2

=head2 yesno()

=over 4

=item EXAMPLE

=over 6

 if ($d->yesno({'text'=>'A question?'})) {
   # answer is YES
 } else {
   # answer is NO or ESC/CANCEL
 }

=back

=item DESCRIPTION

=over 6

This method presents the yesno widget and waits for a response.
Returns TRUE (1) if the user selected <Yes> and returns FALSE (0)
if the user selected <No> or pressed the escape button (in which case
$d->state() ne "OK").

=back

=back

=back

=over 2

=head2 noyes()

=over 4

=item EXAMPLE

=over 6

 if ($d->noyes({'text'=>'A question?'})) {
   # answer is YES
 } else {
   # answer is NO or ESC/CANCEL
 }

=back

=item DESCRIPTION

=over 6

This method is identical to the yesno() widget with the exception that
the <No> button is initially selected for the user. This is the
equivalent of $d->yesno({'text'=>'default no','defaultno'=>1}).
Returns TRUE (1) if the user selected <Yes> and returns FALSE (0)
if the user selected <No> or pressed the escape button (in which case
$d->state() ne "OK").

=back

=back

=back

=over 2

=head2 inputbox()

=over 4

=item EXAMPLE

=over 6

 my $str = $d->inputbox({'text'=>'enter some text',
                         'init'=>'this is in the input field'});

=back

=item DESCRIPTION

=over 6

This displays the inputbox widget and returns the user data as a string.

=back

=back

=back

=over 2

=head2 passwordbox()

=over 4

=item EXAMPLE

=over 6

 my $pwd = $d->passwordbox({'text'=>'notice no text as you type...'});

=back

=item DESCRIPTION

=over 6

This displays the passwordbox widget and returns the user data as a string.
Notice that this is identical to the inputbox() widget except that this
one does not display _any_ text as the user types it in (not even ***'s).

=back

=back

=back

=over 2

=head2 menu()

=over 4

=item EXAMPLE

=over 6

 my $item = $d->menu({'text'=>'example menu',
                      'menu'=>[ 'tag1', 'item 1 description',
                                'tag2', 'item 2 description'
                              ]});

=back

=item DESCRIPTION

=over 6

This displays the menubox widget and returns the "tag" of the
item selected. Each menu() item is made up of two elements of
an array. The first is the "tag" which is returned upon selection
and the second is the item's description.

=back

=back

=back

=over 2

=head2 radiolist()

=over 4

=item EXAMPLE

=over 6

 my $item = $d->radiolist({'text'=>'a list',
                           'menu'=>[ 'tag1', 'item 1 desc', 'off',
                                     'tag2', 'item 2 desc', 'on'
                                   ]});

=back

=item DESCRIPTION

=over 6

This is very similar to the menu() widget except that the radiolist()
menu definiton is slightly different. Each radiolist() item is made
up of three consecutive elements of an array. The first is the "tag"
which is returned upon selection. The second is the description of the
item and the third is a state toggle, either 'on' or 'off' to specify
which is selected first (if multiple are specified as 'on' then the
first instance of 'on' is the item initially selected).

=back

=back

=back

=over 2

=head2 checklist()

=over 4

=item EXAMPLE

=over 6

 my $item = $d->checklist({'text'=>'a list',
                           'menu'=>[ 'tag1', 'item 1 desc', 'off',
                                     'tag2', 'item 2 desc', 'on'
                                   ]});

=back

=item DESCRIPTION

=over 6

This is very similar to the radiolist() widget except that the checklist()
allows for multiple selections from the menu. Each checklist() item is made
up of three consecutive elements of an array. The first is the "tag"
which is returned upon selection. The second is the description of the
item and the third is a state toggle, either 'on' or 'off' to specify
which is selected (all that are marked 'on' will be selected initially). This
will return a list of all the selected "tag"s.

=back

=back

=back

=over 2

=head2 start_gauge()

=over 4

=item EXAMPLE

=over 6

 $d->start_gauge({'text'=>'look Ma, a meter bar!','percent'=>10});

=back

=item DESCRIPTION

=over 6

This method starts the gauge widget and enables the use of the other
gauge related methods. The attribute 'percent' indicates the initial
value of the gauge. This is NOT a blocking method in that it will start
the widget and the Perl continues on with the gauge widget being displayed.
This will return 254 if there is a gauge widget already open.

=back

=back

=back

=over 2

=head2 msg_gauge()

=over 4

=item EXAMPLE

=over 6

 $d->msg_gauge("a new message");

=back

=item DESCRIPTION

=over 6

This method updates a gauge widget's text message area with a
new string. This will return 254 if there is no gauge widget
currently open.

=back

=back

=back

=over 2

=head2 inc_gauge()

=over 4

=item EXAMPLE

=over 6

 $d->inc_gauge(5);

=back

=item DESCRIPTION

=over 6

This method increments a gauge widget's value by the amount
specified. This will return 254 if there is no gauge widget
currently open.

=back

=back

=back

=over 2

=head2 set_gauge()

=over 4

=item EXAMPLE

=over 6

 $d->set_gauge(75);

=back

=item DESCRIPTION

=over 6

This method sets a gauge widget's value to the amount
specified. This will return 254 if there is no gauge widget
currently open.

=back

=back

=back

=over 2

=head2 end_gauge()

=over 4

=item EXAMPLE

=over 6

 $d->end_gauge();

=back

=item DESCRIPTION

=over 6

This method closes an open gauge widget. This will return 254
if there is no gauge widget currently open.

=back

=back

=back

=over 2

=head2 tailbox()

=over 4

=item EXAMPLE

=over 6

 $d->tailbox({'file'=>'/path/and/file/name'});

=back

=item DESCRIPTION

=over 6

This method displays a tailbox widget with the file specified.
Basically a glorified `tail -f` :) This method will check the
file for read permission and if there is no permission to read
the file, a msgbox widget is displayed with an appropriate
error message.

=back

=back

=back

=over 2

=head2 fselect()

=over 4

=item EXAMPLE

=over 6

 my $name = $d->fselect({'path'=>'/'});

=back

=item DESCRIPTION

=over 6

This method displays an fselect (File Selection) widget and
returns the user data as a string.

=back

=back

=back

=over 2

=head2 timebox()

=over 4

=item EXAMPLE

=over 6

 my ($hour,$minute,$second) = $d->timebox({'hour'=>'4',
                                           'minute'=>'20',
                                           'second'=>'0'});

=back

=item DESCRIPTION

=over 6

This method displays a timebox() widget and returns a list
of the user specified time. If any of the 'hour', 'minute'
or 'second' are not specified the widget will display the
system's current time instead. Quoting the time values
should help prevent any sytactical problems with the number
zero.

=back

=back

=back

=over 2

=head2 calendar()

=over 4

=item EXAMPLE

=over 6

 my ($day,$month,$year) = $d->calendar({'day'=>'20',
                                        'month'=>'4',
                                        'year'=>'2002'});

=back

=item DESCRIPTION

=over 6

This method displays a calendar() widget and returns a list
of the user specified date. If any of the 'day', 'month'
or 'year' are not specified the widget will display the
system's current date instead. Quoting the date values
should help prevent any sytactical problems with the number
zero.

=back

=back

=back

=over 2

=head2 ascii_spinner()

=over 4

=item EXAMPLE

=over 6

 while (1) {
   print $d->ascii_spinner();
   `sleep 0.2`; #slow it down so we can see it rotate...
 }

=back

=item DESCRIPTION

=over 6

This method returns the next character for an ascii spinner.
Note that this will return a backspace character ("\b") along
with one of the following four characters:
 |
 /
 -
 \

It is left as an exercise to the end-user how to utilize the
spinner best in their application.

=back

=back

=back

=head1 REGARDING ATTRIBUTES

=over 2

Almost all methods in this class work with a single argument
of a hash reference containing any attibute => value pairs. These
attributes are for the most part taken straight from the dialog
application's command line options. There are some that have been
omitted (like separate-output because those are only usefull in
determining user input) and others that may not work with all
dialog application variations (like whiptail). UDPM will intelligently
assign the command line options depending on the type of dialog in
use. This means that you don't have to worry about which attribute
to use and when, simply use it and if it's not applicable to the
widget / dialog variation; it won't be used. The following is
not 100% accurate but none the less useful.

 +-------------------------------------------------------+
 |              /Dialog__________________________________|
 |              |   /cDialog_____________________________|
 |              |   |   /Whiptail________________________|
 |              |   |   |   /(g|k)Dialog_________________|
 |              |   |   |   |   /native_mode_____________|
 +--------------+   |   |   |   |   /--------------------+
 | attribute    |   |   |   |   |   |                    |
 +--------------+---+---+---+---+---+--------------------+
 | title        | X | X | X | X | X |                    |
 | backtitle    | X | X | X | X | X |                    |
 | height       | X | X | X | X | X |                    |
 | width        | X | X | X | X | X |                    |
 | list-height  | X | X | X | X | X |                    |
 | defaultno    | X | X | X | X | X |                    |
 | clear        | X | X | X | X | X |                    |
 | nocancel     | X | X | X |   | X |                    |
 | fb           |   |   | X |   |   |                    |
 | noitem       |   |   | X |   |   |                    |
 | scrolltext   |   |   | X |   |   |                    |
 | aspect       |   | X |   |   |   |                    |
 | beep         | * | X | * | * | * |                    |
 | beep-after   |   | X |   |   |   |                    |
 | begin        |   | X |   |   |   |                    |
 | cancel-label |   | X |   |   | X |                    |
 | colours      |   | X |   |   |   |                    |
 | cr-wrap      |   | X |   |   |   |                    |
 | default-item |   | X |   |   |   |                    |
 | exit-label   |   | X |   |   |   |                    |
 | extra-button |   | X |   |   | X |                    |
 | extra-label  |   | X |   |   | X |                    |
 | help-button  |   | X |   |   | X |                    |
 | help-label   |   | X |   |   | X |                    |
 | ignore       |   | X |   |   |   |                    |
 | item-help    |   | X |   |   |   |                    |
 | max-input    |   | X |   |   | X |                    |
 | no-collapse  |   | X |   |   |   |                    |
 | no-shadow    |   | X |   |   |   |                    |
 | ok-label     |   | x |   |   |   |                    |
 | shadow       |   | X |   |   |   |                    |
 | sleep        | * | X | * | * | * |                    |
 | tab-correct  |   | X |   |   |   |                    |
 | tab-len      |   | X |   |   |   |                    |
 | timeout      |   | X |   |   |   |                    |
 | trim         |   | X |   |   |   |                    |
 +--------------+---+---+---+---+---+--------------------+
 | Module Specific Attributes                            |
 +--------------+----------------------------------------+
 | dialogrc     | set DIALOGRC to this file              |
 | dialogbin    | force a certain binary...              |
 | envpaths     | array ref with bin paths               |
 | variants     | array ref dialog, whiptail             |
 | gui-variants | array ref gdialog, kdialog             |
 | ascii        | set to 1 to force ascii mode           |
 | auto-clear   | force a clear screen after each widget |
 | auto-scale   | auto-adjust width of 'text' widgets    |
 | max-scale    | upper limit of line size (auto-scale)  |
 | pager        | force a certain pager for ascii mode   |
 | tail         | force a tail binary for ascii mode     |
 | tailopt      | specify the tail continuous read opt.  |
 | tmpdir       | path to a valid temp directory         |
 | sttybin      | path to an stty binary                 |
 | use_stderr   | make ascii mode output to stderr       |
 | tmpdir       | path to a valid temp directory         |
 +--------------+----------------------------------------+
 | Callback Attributes                                   |
 +--------------+----------------------------------------+
 | HELP-SUB     | a coderef evaluated on "HELP" signal   |
 | EXTRA-SUB    | a coderef evaluated on "EXTRA" signal  |
 | ESC-SUB      | a coderef evaluated on "ESC" signal    |
 | CANCEL-SUB   | a coderef evaluated on "CANCEL" signal |
 +--------------+----------------------------------------+

* = sleep and beep are handled by UDPM instead of the dialog
variant. At the moment the only dialog variant that supports
these argumments is cDialog.

=back

=head1 REGARDING 'Module Specific' ATTRIBUTES

=over 2

These attributes are only used once during object
construction and cannot be modified during the life
of the object (this may change in future versions).

=back

=over 4

=item dialogrc => '/path/to/dialogrc'

=over 6

Specify this if you want cDialog to use a certain
resource configuration file. cDialog is the only
dialog variant that can use this option effectively.

=back

=item dialogbin => '/path/to/dialog'

=over 6

By specifying the full path and filename you can force UDPM
to use a specific binary. If this is omitted, UDPM will
determine the binary to use automatically. If you specify an
invalid binary here, UDPM will exit() and print to STDERR
an error message indicating that it couldn't find a dialog
binary. Unless you want to force a specific binary to be used,
do not set this attribute.

=back

=item envpath => [ '/bin', '/usr/bin', '/usr/local/bin' ]

=over 6

If no PATH environemnt variable is present during autodetection
of the dialog binary, this list is used to search for a valid
variant of dialog. Do not change this unless you know what you
are doing.

=back

=item variants => [ 'dialog', 'whiptail' ]

=over 6

This is a list of the names of the various dialog variant binaries.
Do not change this unless you know what you are doing.

=back

=item gui-variants => [ 'gdialog', 'kdialog' ]

=over 6

This is a list of the names of the various gui based dialog
variant binaries like gdialog and kdialog. Do not change this
unless you know what you are doing.

=back

=item ascii => 0

=over 6

Set this to "1" to force the use of native ASCII
to mimic various dialog widgets.

=back

=item auto-clear => 0

=over 6

Set this to "1" to force a $d->clear() after every widget.

=back

=item auto-scale => 0

=over 6

Set this to "1" to have the width of the dialogs dynamically
altered for long 'text' lines. See 'max-scale' for more details.

=back

=item max-scale => 78

=over 6

This is the max number of characters in a line that can affect
the 'width' attribute for 'auto-scale'ing a widget. If the 'width'
(-5 for borders) is less than the length of the line of text and
the length of the line of text is less than the 'max-scale'; the
attribute 'width' will be temporarialy adjusted, otherwise that
line will have no affect on the 'width' and it's left up to the
dialog variant to wrap that text line appropriately. In the case
that the user is using cDialog (which has a '--print-maxsize'),
the maximum scale size is automatically adjusted to the available
limit (this overrides and 'max-scale' setting during construction).

=back

=item pager => '/usr/bin/pager'

=over 6

Set this to the desired pager (default is /usr/bin/pager) for the
textbox in ascii mode. If the environment variable 'PAGER' exists
it will be used instead of the default / preset.

=back

=item tail => '/usr/bin/tail'

=over 6

Set this to the desired tail application.

=back

=item tailopt => '-f'

=over 6

Set this to the desired tail application's "constantly read from file"
command line option.

=back

=item sttybin => '/bin/stty'

=over 6

stty is the application used to manipulate the tty of the ascii-mode
passwordbox widget.

=back

=item use_stderr => 0

=over 6

Set this to anything other than '0' (zero) and the ascii-mode widgets
will print their interfaces to STDERR instead of STDOUT. This does not
interfere with STDIN which is still used for input.

=back

=item tmpdir => '/tmp'

=over 6

This is used with variants like whiptail that do not play well with
redirecting their output (using the normal conventions). All temporary
files are deleted but if the user performs a "harsh-break" (hitting
ctrl+c many times etc.) there is a chance that some null files may be
left around.

=back

=back

=head1 REGARDING 'Callback' ATTRIBUTES

=over 2

These attributes are only used once during object construction and
cannot be modified during the life of the object (this may change in
future versions). These 'Callback' functions are simply signal
handlers for the four main signals; "HELP", "EXTRA", "ESC", and "CANCEL".

When using these 'Callback' functions be sure to use a secondary UDPM
object within them instead of calling widgets with the same UDPM object
that these callbacks are being assigned to. When you do use the same object
in the callbacks the state() and other such variables _are_ modified and
this can cause logical problems. Having a secondary UDPM object just for the
callbacks isn't a "Bad Thing (tm)" but does add overhead.

=back

=over 4

=item HELP-SUB => \&HELP_SUB_FUNC

=over 6

This code block will be evaluated every time the user selects an
available "Help" button.

=back

=item EXTRA-SUB => \&EXTRA_SUB_FUNC

=over 6

This code block will be evaluated every time the user selects an
available "Extra" button (regardless of it's label value).

=back

=item ESC-SUB => \&ESC_SUB_FUNC

=over 6

This code block will be evaluated every time the user presses (or
selects) the "Esc" button.

=back

=item CANCEL-SUB => \&CANCEL_SUB_FUNC

=over 6

This code block will be evaluated every time the user selects an
available "Cancel" button (regardless of it's label value).

=back

=back

=head1 REGARDING 'text' ATTRIBUTE

=over 2

This attribute is special in that you can use it in two forms;
scalar and array. Here is some examples to help clarify usage:

 $d->msgbox({'text'=>['line one','line two','line three']});
    +---------------------------------+
    | line one                        |
    | line two                        |
    | line three                      |
    +---------------------------------+

 $d->msgbox({'text'=>'line one\nline two\nline three'});
    +---------------------------------+
    | line one                        |
    | line two                        |
    | line three                      |
    +---------------------------------+

The dialog variant ComeOn Dialog (aka: dialog ver. 0.9b)
supports the use of interesting colour related attributes which
UDPM takes full advantage of. When using any widget with a 'text'
attribute, the text itself is allowed certain colour formatting
sequences. UDPM will translate all 'text' attributes and
depending on the 'colours' attribute (1 or 0) and also on the
dialog variant either strip away the formatting sequences or
replace them with the "real" sequences. The "reset all" effect
resets all effects including colours. The following tables
should enlighten the situation.

 +-----------+------------+-----------+
 | effect    | UDPM       | REAL      |
 +-----------+------------+-----------+
 | bold      | [B]...[/B] | \Zb...\ZB |
 | underline | [U]...[/U] | \Zu...\ZU |
 | reversed  | [R]...[/R] | \Zr...\ZR |
 | reset all | [N]        | \Zn       |
 +-----------+------------+-----------+

 +---------+-------------+------+
 | color   | UDP         | REAL |
 +---------+-------------+------+
 | black   | [C=black]   | \Z0  |
 | red     | [C=red]     | \Z1  |
 | green   | [C=green]   | \Z2  |
 | yellow  | [C=yellow]  | \Z3  |
 | blue    | [C=blue]    | \Z4  |
 | magenta | [C=magenta] | \Z5  |
 | cyan    | [C=cyan]    | \Z6  |
 | white   | [C=white]   | \Z7  |
 +---------+-------------+------+

 +-----------+------------+-------+
 | alignment | Long       | Short |
 +-----------+------------+-------+
 | centered  | [A=CENTER] | [A=C] |
 | left      | [A=LEFT]   | [A=L] |
 | right     | [A=RIGHT]  | [A=R] |
 +-----------+------------+-------+

Either the REAL or UDPM versions can be used. The UDPM sequences are
case in-sensitive, and the REAL sequences are case sensitive. Alignment
has effect regardless of dialog variant and option (with exception to GUI based
dialogs and Native (ASCII) mode as they strip newlines and multiple
trailing/prefixing spaces). How the alignment is calculated:

 center_pad = (((width - 5) - length_of_line) / 2)
 right_pad  = ((width - 5) - length_of_line)
 left_pad   = 0

5 is subracted from the width to account for the borders and gaps as these
are included in the overall width of the displayed widget. All padding
is made up of spaces appended to the beginning of the line. If the line
length (before padding) is greater than the width (-5) then the width is
increased to the length of the line (+5).

All of these special text formatting sequences are stripped for gui based
dialog variants as they do not support any such features. This includes the
alignment specifications (even though they are not related to any one
dialog variant).

=back

=head1 REGARDING WIDGETS

=over 2

Most of these widgets are available across multiple variations
of the dialog application.

 +--------------------------------------------+
 |              /Dialog_______________________|
 |              |   /cDialog__________________|
 |              |   |   /Whiptail_____________|
 |              |   |   |   /(g|k)Dialog______|
 |              |   |   |   |   /native_mode__|
 +--------------+   |   |   |   |   /---------+
 | widget       |   |   |   |   |   |         |
 +--------------+---+---+---+---+---+---------+
 | infobox      | X | X | X | X | X |         |
 | msgbox       | X | X | X | X | X |         |
 | textbox	| X | X | X | X | X |         |
 | yesno/noyes 	| X | X | X | X | X |         |
 | inputbox	| X | X | X | X | X |         |
 | passwordbox	|   | X | X |   | X |         |
 | menu		| X | X | X | X | X |         |
 | radiolist	| X | X | X | X | X |         |
 | checklist	| X | X | X | X | X |         |
 | start_gauge	| X | X | X |N/A|   |         |
 | set_gauge	| X | X | X |/|\|   |         |
 | inc_gauge	| X | X | X | | |   |         |
 | dec_gauge	| X | X | X | | |   |         |
 | msg_gauge	| X | X |N/A|\|/|   |         |
 | end_gauge	| X | X | X |N/A|   |         |
 | tailbox	|   | X |   |   | X |         |
 | fselect	| * | X | * | * | * |         |
 | timebox	|   | X |   |   |   |         |
 | calendar	|   | X |   |   |   |         |
 +--------------+---+---+---+---+---+---------+

N/A = Currently broken (either with this module or with the
specific dialog variant).

* = somewhat of a hack using the menu() widget to
do some trickery with displaying directories. Any dialog
but cDialog will use this and is unable to select a file
that doesn't exist (which you can do with the cDialog variant).

The following chart indicates the specific
attributes used by the various widgets. Attributes
listed in []'s are optional.

 +--------------+----------------------------+
 | widget       | Widget Specific Attributes |
 +--------------+----------------------------+
 | infobox      |   text                     |
 | msgbox       |   text                     |
 | textbox	|   file                     |
 | yesno	|   text                     |
 | inputbox	|   text, [init]             |
 | passwordbox	|   text, [init]             |
 | menu		|   text, menu               |
 | radiolist	|   text, list               |
 | checklist	|   text, list               |
 | start_guage	|   text, [percent]          |
 | tailbox	|   file                     |
 | fselect	|   path                     |
 | timebox	|   hour, minute, second     |
 | calendar	|   day, month, year         |
 +--------------+----------------------------+

The 'menu' and 'list' attribute names can be used in any
of the three widgets, but the values in the array must be
correct. Here are the two styles:

 'menu' => [ 'tagname', 'description' ]
 'list' => [ 'tagname', 'description', 'state' ]

 'tagname' can be any string.
 'description' can be any string.
 'state' can be either 'on' or 'off'

So these are valid:

 $d->menu({'list'=>['1','one','2','two']});
 $d->menu({'menu'=>['1','one','2','two']});
 $d->checklist({'menu'=>['1','one','off','2','two','off']});
 $d->checklist({'list'=>['1','one','off','2','two','off']});

And this is silently invalid:

 $d->menu({'menu'=>['1','one','off','2','two','off']});

And these are invalid with a msgbox displaying an error message:

 $d->menu({'list'=>['1','one','2','two','3']});
 $d->checklist({'menu'=>['1','one','ogg','2','two','3']});

The only verification checks are for wether or not the menu lists
are evenly divisible by 2 (for menu()) or 3 (for radiolist() or
checklist()) and also for the radiolist() and checklist() widgets,
every third element must be either 'on' or 'off' (case
in-sensitive).

=back

=head1 REGARDING NATIVE (ASCII) MODE

=over 2

This is probably the greatest feature of UDPM overall because
not only is UDPM "dialog variant" independant, but having _any_
"dialog variant" is optional altogether. Native (ASCII) mode uses the
fixed dimensions of 75 colums and 25 rows. In subsequent versions
of UDPM there may be additional formats for all widgets (ie: "compact",
"normal", "extended", or "custom").

Be aware that the DELETE (or ^H) key may or may not work as expected when
using ASCII mode. This is because input is handled by the simple
"$input = <STDIN>;" statement. In later versions there will be a little
more robust input handler implemented along with support for Readline
(if already installed). Primarily the passwordbox() widget is affected
by this limitation.

=item NATIVE (ASCII) WIDGET NOTES

=over 4

=item textbox() and tailbox()

=over 6

textbox() uses either the environment variable or the runtime
configuration variable 'pager' for displaying text files. Likewise,
tailbox() uses the runtime configuration variable 'tail' and 'tailopt'
to provide the widget's functionality.

=back

=item infobox() and msgbox()

=over 6

Both of these widgets simply print a simple template resembling
the actual ncurses interfaces.

=back

=item inputbox() and passwordbox()

=over 6

Both of these widgets simply print the same standard ascii art
used by infobox() and msgbox() except that at the bottom is a
"input:" indicating the text input field.

=back

=item menu(), radiolist() and checklist()

=over 6

These three widgets allow for an unlimited number of menu entries.
Note that any default selections (indicated by '->') on the
radiolist() and checklist() widgets are not used for anything
practical aside from suggesting the end-user to notice those item(s).

On the bottom left of the screen you'll notice a page indicator:

 (n/m) :

 'n' = current page
 'm' = total number of pages

Each page currently has room for 30 menu entries. This number is
hard-coded and un-alterable (this may change with the "custom" print
formats sometime in the future).

To navigate the menus use:

 +--------------+---------------------------+
 | string       | action                    |
 +--------------+---------------------------+
 | :?           | This help message         |
 | :h :help     | Press the [Help] button   |
 | :e :extra    | Press the [Extra] button  |
 | :esc :escape | Press the [Esc] button    |
 | :c :cancel   | Press the [Cancel] button |
 | :pg <N>      | Go to page 'N'            |
 | :n :next     | Go to the next page       |
 | :p :prev     | Go to the previous page   |
 +--------------+---------------------------+

At the bottom of every menu(), radiolist() or checklist() are two
lines:

   ':e'=[Extra]    ':c'=[Cancel]      ':h'=[Help]
            ':?'=[Colon Command Help]

The Extra, Cancel and Help are actually the widget buttons and
may or may not be visible depending on the runtime configuration
(ie: 'extra-button'=>'1' will make the Extra button visible). This
runtime configuration also enables/disables these three widget
buttons. The Colon Command Help is always visible and always
functional where as the other widget buttons are configuration
dependant for functionality.

=back

=back

=back

=head1 BONUS FEATURES

=over 2

These features are in some way related to interfacing with the
end-user (and/or end-user's environment).

=back

=head2 NAUTILUS SCRIPT SUPPORT

=over 2

=head2 nautilus_paths()

=over 4

=item EXAMPLE

=over 6

 my @paths = $d->nautilus_paths();
 foreach my $file (@paths) {
   ...
 }

=back

=item DESCRIPTION

=over 6

This method returns an array containing all the selected
files in standard unix path format.

=back

=back

=back

=over 2

=head2 nautilus_path()

=over 4

=item EXAMPLE

=over 6

 my $path = $d->nautilus_path();
 chdir($path);

=back

=item DESCRIPTION

=over 6

This method returns a single string containing the standard unix
path of the selected item's parent directory. This is derived from
the nautilus_uri() method and is simply stripped of the "file://".

=back

=back

=back

=over 2

=head2 nautilus_uris()

=over 4

=item EXAMPLE

=over 6

 my @uris = $d->nautilus_uris();
 foreach my $uri (@uris) {
   ...
 }

=back

=item DESCRIPTION

=over 6

This method returns an array containing all the selected
items in standard URI format.

=back

=back

=back

=over 2

=head2 nautilus_uri()

=over 4

=item EXAMPLE

=over 6

 my $uri = $d->nautilus_uri();
 $uri =~ s/^file:\/\/(.*)$/$1/;
 chdir($uri);

=back

=item DESCRIPTION

=over 6

This method returns a single string containing the URI of the
selected item's parent directory.

=back

=back

=back

=over 2

=head2 nautilus_geometry()

=over 4

=item EXAMPLE

=over 6

 my ($w,$h,$x,$y) = $d->nautilus_geometry();

=back

=item DESCRIPTION

=over 6

This method returns four values; in order:

 width
 height
 x
 y

=back

=back

=back

=over 2

=head2 nautilus_debug()

=over 4

=item EXAMPLE

=over 6

 $d->nautilus_debug();

=back

=item DESCRIPTION

=over 6

This method simply runs a msgbox() with all the nautilus data displayed.
When using this, be sure to enforce the use of a gui dialog variant. This
is of most use when first learning to use UDPM for nautilus scripts. Here
is a "classic" nautilus debugging script (save and `chmod 0755` this to
something like: ~/.gnome2/nautilus-scripts/nautilus_debug):

 #!/usr/bin/perl
 use strict;
 use warnings;
 use diagnostics;
 use UDPM;

 chomp(my $DIALOG = `/usr/bin/which gdialog`);
 if (!-x $DIALOG) {
   chomp($DIALOG = `/usr/bin/which kdialog`);
   if (!-x $DIALOG) {
     print STDERR "Couldn't find a suitable gui based dialog variant\n";
     exit(1);
   }
 }

 my $d = new UDPM ({'dialogbin'=>$DIALOG});
 $d->nautilus_debug();

 exit(0);


=back

=back

=back

=head1 FINAL NOTES

=over 2

This module will NOT run in TAINT mode at all. I don't see how this could
even be possible (without circumventing the whole purpose of TAINT mode).
This isn't to say that the author of UDPM won't take any suggestions
on how to usefully implement a "taint" mode within UDPM.

If you plan on utilizing this module in any "mission critical" situations be
forwarned that there are probably many ways a malicious cracker could break
the system.

UDPM was designed and built using Debian (Unstable), Perl 5.8.0, Dialog 0.9b,
Whiptail 0.50.17, GDialog 2.0.6, and Bash 2.05b.

UDPM has implemented both Linux and BSD functionality for certain widgets in
native ascii mode and the BSD aspects have never been tested. Running the
included example Perl script (udpm-demo.pl) on a BSD system in native ascii
mode would highlight any imperfections. Specifically, the platform specific
instructions are 'stty' commands and as such these differ between Linux and
BSD. The platform specific code came from `perldoc -f getc` and pertains
primarily to the passwordbox() widget.

=back

=head1 SEE ALSO

=over 2

Unix man pages:

 dialog(1), whiptail(1), gdialog(1), kdialog(1) and nautilus(1)

Mailing list:

 http://lists.sourceforge.net/mailman/listinfo/udpm-list

Official project site:

 http://udpm.sourceforge.net

=back

=head1 AUTHOR

Kevin C. Krinke, E<lt>kckrinke@opendoorsoftware.comE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2002  Kevin C. Krinke <kckrinke@opendoorsoftware.com>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
