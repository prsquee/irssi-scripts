#public commands
use Irssi qw (  print
                signal_emit
                signal_add
                signal_register
                settings_get_str
                settings_add_str
                settings_set_str
);
use strict;
use warnings;
use Data::Dumper;

sub incoming_public {
	my($server, $text, $nick, $mask, $chan) = @_;
  my $myNets = settings_get_str('active_networks');
  print (CRAP "im not being used on any network!") if (not defined($myNets));
	return if $server->{tag} !~ /$myNets/;

  #check if someone said a command
  if ($text =~ /^!/) {
    my ($cmd) = $text =~ /^!(\w+)\s*/;
    if ($cmd =~ /^h[ea]lp$/) {
      #my $halps = settings_ge_str('halpcommands');
      sayit($server,$chan, settings_get_str('halpcommands')); 
      return;
    }
    if ($cmd eq 'addhelp') {
        my ($newhalp) = $text =~ /^!addhelp\s+(.*)$/;
        my $halps = settings_get_str('halpcommands');
        $halps .= " $newhalp" if ($newhalp);
        Irssi::settings_set_str('halpcommands', $halps);
        sayit($server,$chan,$halps);
        return;
    }
    if ($cmd eq 'fortune') {
        my $fortune = `/usr/bin/fortune -s`;
        my @cookie = split(/\n/, $fortune);
        sayit($server,$chan,"[fortune] $_") foreach @cookie;
        return;
    }
    if ($cmd =~ /(?:^do$)|(?:^say$)/ and $nick eq 'sQuEE' and $mask =~ /unaffiliated/) {
          $text =~ s/^!\w+\s//;
          my $serverCmd = ($cmd eq 'say') ? "MSG" : "ACTION";
          $server->command("$serverCmd $chan $text");
          return;
    }
    if ($cmd eq 'uptime') {
      #get_uptime($chan,$server);
      signal_emit('show uptime',$server,$chan) if (is_loaded('uptime'));
      return;
    }
    if ($cmd eq 'imdb') {
      signal_emit('search imdb',$server,$chan,$text) if (is_loaded('imdb'));
      return;
    }
    if ($cmd eq 'nickinfo') {
      print (CRAP "fix me");
      return;
    }
    if ($cmd eq 'calc') {
      signal_emit('calculate',$server,$chan,$text) if (is_loaded('calc'));
      return;
    }
    if ($cmd eq 'ihq') {
      signal_emit('search isohunt',$server,$chan,$text) if (is_loaded('isohunt'));
      return;
    }
    if ($cmd eq 'ping') { sayit($server,$chan,"pong"); return; }
  }
  #cmd check ends here. begin general text match

  if ($text =~ m{http://www\.imdb\.com/title/(tt\d+)}) {
    my $id = $1;
    signal_emit('search imdb',$server,$chan,$id) if (is_loaded('imdb'));
    return;
  }
}

#sub msg_priv {
#	my ($server, $text, $nick, $address) = @_;
#	my $msg = "I only do private shows for certain people I know, you are not on that list. talk to sQuEE, he's mah pimp";
#	sayit($server, $nick, $msg); 
#	Irssi::signal_stop()
#}
sub is_loaded { return exists($Irssi::Script::{shift(@_).'::'}); }
sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}

#signal_add("message private","msg_priv");
signal_add("message public","incoming_public");
settings_add_str('bot config', 'halpcommands', '');
settings_add_str('bot config', 'active_networks','');

signal_register( { 'show uptime' => [ 'iobject', 'string' ]});            #server,chan
signal_register( { 'search imdb' => [ 'iobject', 'string', 'string' ]});  #server,chan,text
signal_register( { 'calculate'   => [ 'iobject', 'string', 'string' ]});  #server,chan,text
signal_register( { 'search isohunt' => [ 'iobject', 'string', 'string' ]});  #server,chan,text

#signal registration
#signal_register(hash)
#  Register parameter types for one or more signals.
#  `hash' must map one or more signal names to references to arrays
#  containing 0 to 6 type names. Some recognized type names include
#  int for integers, intptr for references to integers and string for
#  strings. For all standard signals see src/perl/perl-signals-list.h
#  in the source code (this is generated by src/perl/get-signals.pl).

#signal types:

#  • GList* of ([^,]*)> glistptr_$1
#  • GSList* of (\w+)s> gslist_$1
#  • char* string
#  • ulong* ulongptr
#  • int* intptr
#  • int int
#  • CHATNET_REC iobject
#  • SERVER_REC iobject
#  • RECONNECT_REC iobject
#  • CHANNEL_REC iobject
#  • QUERY_REC iobject
#  • COMMAND_REC iobject
#  • NICK_REC iobject
#  • LOG_REC Irssi::Log
#  • RAWLOG_REC Irssi::Rawlog
#  • IGNORE_REC Irssi::Ignore
#  • MODULE_REC Irssi::Module
#  • BAN_REC Irssi::Irc::Ban
#  • NETSPLIT_REC Irssi::Irc::Netsplit
#  • NETSPLIT_SERVER__REC Irssi::Irc::Netsplitserver
#  • DCC_REC siobject
#  • AUTOIGNORE_REC Irssi::Irc::Autoignore
#  • AUTOIGNORE_REC Irssi::Irc::Autoignore
#  • NOTIFYLIST_REC Irssi::Irc::Notifylist
#  • CLIENT_REC Irssi::Irc::Client
#  • THEME_REC Irssi::UI::Theme
#  • KEYINFO_REC Irssi::UI::Keyinfo
#  • PROCESS_REC Irssi::UI::Process
#  • TEXT_DEST_REC Irssi::UI::TextDest
#  • WINDOW_REC Irssi::UI::Window
#  • WI_ITEM_REC iobject
#  • PERL_SCRIPT_REC Irssi::Script

#
