use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	return if ($server->{tag} !~ /3dg|fnode|lia|gsg/);
	
	if ($text =~ /^!(\w+)/) {
		my $cmd = $1;
		if ($cmd =~ /h[ea]lp/) {
			sayit($server,$chan,Irssi::settings_get_str('halpcommands')); return;
    }
		if ($cmd eq 'fortune') {
				my $fortune = `/usr/bin/fortune -s`;
				my @foo = split(/\n/, $fortune);
				sayit($server,$chan,"[fortune] $_") for (@foo);
				return;
    }
    # have to fix this 
#		if ($cmd eq 'say' and $nick eq 'sQuEE' ) { #}and $mask =~ m{squee\@unaffiliated/sq/x-\d+}i) {
#					$text =~ s/^!\w+\s//;
#          my $serverCmd = ($cmd eq 'say') ? "MSG" : "ACTION";
#          $server->command("${serverCmd}, $chan, $text");
#					return;
#    }
		if ($cmd eq 'uptime') {
				get_uptime($chan,$server);
			}
	}
}

sub get_uptime {
	my ($chan,$server) = @_;
	my ($upD,$upH,$upM) = `uptime` =~ /up (?:(\d+) days?,)?\s+(\d+):(\d+),/;
#	my $record = `cat ~/.uptime_record`;# chomp($record);
	$upD = 0 if (!$upD);
	my $day = "day"; $day .= "s" if ($upD > 1);
	my $hs = "h"; $hs .= "s" if ($upH > 1);
	my $min = "min"; $min .= "s" if ($upM > 1);
	my $msg = "$upD $day $upH $hs $upM $min";
	sayit($server,$chan,$msg);
  return;
}

#sub msg_priv {
#	my ($server, $text, $nick, $address) = @_;
#	my $msg = "I only do private shows for certain people I know, you are not on that list. talk to sQuEE, he's mah pimp";
#	sayit($server, $nick, $msg); 
#	Irssi::signal_stop()
#}
sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
sub print_msg { Irssi::print("@_"); }

#signal_add("message private","msg_priv");
signal_add("message public","msg_pub");
Irssi::settings_add_str('misc-help', 'halpcommands', '');

