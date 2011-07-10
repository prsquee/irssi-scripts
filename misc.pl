#!/usr/bin/perl

use Irssi qw(command_bind signal_add print active_win server_find_tag ) ;
use strict;

sub msg_pub {
	my($server, $text, $nick, $mask,$chan) = @_;
	return if ($server->{tag} !~ /3dg|fnode|lia|gsg/);
	
	if ($text =~ /^!/) {
		my @line = split(" ",$text);
		$_ = $line[0];
		{
			/^!h[ea]lp$/ 	and do {
				my $cmds = Irssi::settings_get_str('halpcommands');
				sayit($server,$chan,$cmds);
				return;
			};
			/^!fortune$/	and do {
				my $fortune = `/usr/games/fortune -os`;
				my @foo = split(/\n/, $fortune);
				sayit($server,$chan,"[fortune] $_") for (@foo);
				return; 
			};
			/^!say$/	and do {
				if ($nick =~ /^sQuEE`?$/) {
					$text =~ s/^!say\s//;
					$server->command("MSG $chan $text");
					return;
				}
			};
			/^!do$/		and do {
				if ($nick =~ /^sQuEE`?$/) {
					$text =~ s/^!do\s//;
					$server->command("ACTION $chan $text");
					return;
				}
			};
			/^!uptime$/	and do { 
				get_uptime($chan,$server); 
				return; 
			};
			
		}
	}
}

sub get_uptime {
	my ($chan,$server) = @_;
	my ($upD,$upH,$upM) = `uptime` =~ /up (?:(\d+) days?,)? +?(\d+):(\d+),/;
#	my $record = `cat ~/.uptime_record`;# chomp($record);
	$upD = 0 if (!$upD);
	my $day = "day"; $day .= "s" if ($upD > 1);
	my $hs = "h"; $hs .= "s" if ($upH > 1);
	my $min = "min"; $min .= "s" if ($upM > 1);
	$server->command("MSG $chan $upD $day $upH $hs $upM $min");

}

sub msg_priv {
	my ($server, $text, $nick, $address) = @_;
	my $msg = "I only do private shows for certain people I know, you are not on that list. talk to sQuEE, he's mah pimp";
	sayit($server, $nick, $msg); 
	Irssi::signal_stop()
}
sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
sub doit {
	my ($server, $target, $msg) = @_;
	$server->command("ACTION $target $msg");
}
sub print_msg { Irssi::print("@_"); }

signal_add("message private","msg_priv");
signal_add("message public","msg_pub");
Irssi::settings_add_str('misc-help', 'halpcommands', '');

