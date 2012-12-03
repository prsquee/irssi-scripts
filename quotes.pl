#quotes.pl

use Irssi qw( settings_add_str settings_get_str );
use strict;
use warnings;
use Data::Dump qw( dump );
use File::Slurp qw( read_file write_file append_file);


sub msg_pub {
	my ($server, $text, $nick, $mask, $chan) = @_;
	return if $server->{tag} !~ /3dg|fnode|lia/;
	return if $text !~ /^!q/;
	
  my $qfile = settings_get_str("quotes_dir") . "$server->{tag}" . $chan . ".txt";
  $qfile =~ s/#/_/g;


  #{{{ add 
  if ( $text =~ /^!qadd(.*)$/ ) { 
    my $addme = strip_all($1) if ($1);
    unless ($addme) { sayit($server,$chan,"I only accept funny quotes!"); return; }
    eval { append_file ($qfile, "$addme\n") };
    sayit($server,$chan,"quote added") if (not $@);
  }
  #}}}
  #{{{ last
  if ( $text =~ /^!qlast\s?(\d)?$/ ) { 
    my $buf = eval { read_file ($qfile, array_ref => 1) };
    if ($buf) {
      my $c = $1 || '1';
      if ($c > scalar(@$buf)) {
        sayit($server,$chan,"stahp! too much!");
        return;
      }
      sayit($server, $chan, "[quote] $$buf[-${c}]");
      return;
    } else { 
      sayit($server,$chan, "looks like no quotes for $chan");
      return;
    }
  } #}}}
  #{{{ random 
  if ( $text =~ /^!q(?:uote)?$/) { 
    my $buf = eval { read_file ($qfile, array_ref => 1) };
    if ($buf) {
      my $single = $$buf[int(rand(@$buf))];
      sayit($server,$chan,"[random] $single");
    } else {
        sayit($server,$chan, "no quotes from $chan");
    }
  }#}}}
  #{{{ count total 
  if ( $text =~ /^!qtotal\b/ ) {
    my $buf  = eval { read_file ($qfile, array_ref => 1) }; #total is a ref to an array of the slurped file
    if ($buf) {
      my $t = scalar @$buf;
      sayit($server,$chan,"total quotes: $t");
      return;
    } else { 
      sayit($server,$chan, "looks like there isnt any quotes for $chan");
      return;
    }
  }#}}}
  #{{{ #delete
  if ( $text =~ /^!qdel(.*)/) { 
    my $deleteme = strip_all($1) if ($1);
    if ($deleteme) { 
      $deleteme =~ s/\W/\\W/g; #escape all the non \w
      $deleteme = qr/$deleteme/i;
      my @toBeDeleted;
      my $buf = eval { read_file ($qfile, array_ref => 1) };
      eval { @toBeDeleted = grep { /($deleteme)/ } @$buf; } if ($buf);
      if (@toBeDeleted) {
        if ( scalar(@toBeDeleted) == 1) {
          #if we found exactly 1 match
          @$buf = grep { ! /($deleteme)/ } @$buf;
          #write it atomically
          write_file ($qfile, {atomic => 1}, @$buf);
          sayit($server, $chan, "deleted quote: \"$_\"") for (@toBeDeleted);
        } else { sayit($server,$chan,"stahp! that's more than one quote!"); return; }
      } else { sayit($server,$chan,"quote not found!");                     return; }
    } else { sayit($server,$chan,"delete a quote with a few words.");       return; }
  }#}}}
  #{{{ search
  if ( $text =~ /^!qs(?:earch)?(.*)/) {
    my $searchme = strip_all($1) if ($1);
    if ($searchme) {
      my @words2find = split(/\s+/, $searchme);
      my @found = eval { read_file $qfile };
      if (@found) {
        foreach (@words2find) {
          my $singleWord = qr/$_/i;
          eval { @found = grep { /$singleWord/ } @found; }
        }

        if (scalar(@found) == 0) {
          sayit($server,$chan,"found nothin'");
        } else {
            if (scalar(@found) >= 1 and scalar(@found) <= 4) {
              #si encontro menos de 4
              sayit($server,$chan, "[found] $_") for (@found);
            } else {
                #si encontro mas de 4, tirar 4 random quotes de los encontrados
                my @randq;
                for (0..3) {
                  my $n = int(rand(@found));
                  $randq[$_] = $found[$n];
                  splice (@found, $n, 1);
                }
                my $totalFound = scalar(@found) + scalar(@randq);
                sayit($server,$chan,"found $totalFound quotes, here are 4 random quotes");
                sayit($server,$chan,"[found] $_") foreach (@randq);
              }
        }
      } else { sayit($server,$chan, "no quotes for $chan"); return; }
    } else { sayit($server,$chan,"I can find you a quote."); return;}
  }#}}}
}
#{{{ misc strip all; open file; print and say 
sub strip_all {
  my $text = shift;
	$text =~ s/\x03\d{0,2}(,\d{0,2})?//g;           #mirc colors
	$text =~ s/\x1b\[\d+(?:,\d+)?m//g;              #ansi colors 
	$text =~ s/\x02|\x16|\x1F|\x0F//g;              #bold, inverse, underline and clear
	$text =~ s/^\s+//g;				                      #espacios vacios al ppio
	return $text;
}

sub print_msg { Irssi::active_win()->print("@_"); }
sub sayit {
  my ($server, $target, $msg) = @_;
  $server->command("MSG $target $msg");
}
#}}}
#{{{ signaal and stuff 
Irssi::signal_add("message public","msg_pub");
Irssi::settings_add_str("quotes", "qfile", '');
Irssi::settings_add_str("quotes", "quotes_dir", '/home/squee/.irssi/scripts/quotes_saved/');
#use Irssi::get_irssi_dir()
#}}}
