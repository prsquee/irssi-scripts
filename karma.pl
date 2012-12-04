#replace.pl
use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use warnings;
use strict;
use Data::Dumper;
use File::Slurp qw( read_file write_file append_file);


my %karma = ();
my $karmaFile = Irssi::get_irssi_dir() . "/scripts/datafiles/karma.txt";
sub init {
  #abrir el file y armar karma table.
  #which would be nick + server tag => count
  my $buf = eval { read_file ($karmaFile, array_ref => 1) };
  if ($buf) {
    foreach (@$buf) {
      chomp;
      my ($name, $count) = split /,/ if m/,/;
      $karma{$name} = $count if ($name and $count);
    }
  } else {
    print (CRAP "no karma file");
  }
}

sub msg_pub {
	my ($server,$text,$nick,$mask,$chan) = @_;
	return if ($server->{tag} !~ /3dg|fnode|lia|gsg/);
  show_karma($server,$chan,$nick,$text) if ($text =~ /^!karma/);

  if ($text =~ /(\w+)(([-+])\3)/) {
    #no self karma
    if ($nick !~ /^${1}$/i) {
      if (! exists($karma{$1 . $server->{tag}}) or ! defined($karma{$1 . $server->{tag}})) {
         $karma{$1 . $server->{tag}} = 0;
      }
      my $dome = '$karma{$1 . $server->{tag}}' . $2;
      eval "$dome";
    }
    save_karma();
    #print(CRAP Dumper(\%karma));
  }
}
sub save_karma {
  my @buf = map { $_ . "," . $karma{$_} . "\n" } keys %karma;
  write_file ($karmaFile, @buf);
  undef @buf;
  return;
}
sub show_karma {
  my ($server,$chan,$nick,$text) = @_;
  my ($name) = $text =~ /!karma\s+(.*)$/;
  $name = $nick if ( ! defined($name));
  if ($name eq $server->{nick}) {
    sayit($server,$chan,"my karma is over 9000 already!");
    return;
  }
  elsif ( ! exists($karma{$name . $server->{tag}})  or
          ! defined($karma{$name . $server->{tag}}) or
            $karma{$name . $server->{tag}} == 0) {
              sayit($server,$chan,"$name has neutral karma");
  } 
  elsif (defined($karma{$name . $server->{tag}})) {
    sayit($server,$chan,"karma for ${name}: $karma{$name . $server->{tag}}");
  }
}

sub sayit {
  my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
sub printmsg { active_win()->print("@_"); }
Irssi::signal_add("message public","msg_pub");

init();
