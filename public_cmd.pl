#public commands
use Irssi qw (  print
                signal_emit
                signal_add
                signal_register
                settings_get_str
                settings_add_str
                settings_set_str
                get_irssi_dir
);
use strict;
use warnings;
use Storable qw (store retrieve);
use Data::Dumper;

#{{{ init stuff
#nick 2 twitter list
my $twitterusersFile = get_irssi_dir() . '/scripts/datafiles/twitternames.storable';
my $twitterusers_ref = eval { retrieve($twitterusersFile) } || [];
#print (CRAP Dumper($twitterusers_ref));

# static and complex regexes
my $youtubex = qr{(?x-sm:
    (?:http://)?(?:www\.)?      #optional 
    youtu(?:\.be|be\.com)       #matches the short youtube link
    /                           #the 1st slash
    (?:watch\?\S*v=)?           #this wont be here if it's short uri
    (?:user/.*/)?               #username can be 
    ([^&]{11})                  #the vid id
)};
#}}}

sub incoming_public {
  my($server, $text, $nick, $mask, $chan) = @_;
  my $myNets = settings_get_str('active_networks');
  print (CRAP "im not being used on any network!") if (not defined($myNets));
  return if $server->{tag} !~ /$myNets/;

  #check if someone said a command
  if ($text =~ /^!/) {
    my ($cmd) = $text =~ /^!(\w+)\b/;
    #{{{ halps 
    if (defined($cmd)) {
      if ($cmd =~ /^h[ea]lp$/) {
        #my $halps = settings_ge_str('halpcommands');
        sayit($server,$chan, settings_get_str('halpcommands')); 
        return;
      }#}}}
      #{{{ add help
      if ($cmd eq 'addhalp' and $nick eq 'sQuEE' and $mask =~ /unaffiliated/) {
          my ($newhalp) = $text =~ /^!addhalp\s+(.*)$/;
          my $halps = settings_get_str('halpcommands');
          $halps .= " $newhalp" if ($newhalp);
          Irssi::settings_set_str('halpcommands', $halps);
          sayit($server,$chan,$halps);
          return;
      }#}}}
      #{{{ fortune cookies
      if ($cmd eq 'fortune') {
          my $fortune = `/usr/bin/fortune -s`;
          my @cookie = split(/\n/, $fortune);
          sayit($server,$chan,"[fortune] $_") foreach @cookie;
          return;
      }#}}}
      #{{{ do this and say that
      if (($cmd eq 'do' or $cmd eq 'say') and $nick eq 'sQuEE' and $mask =~ /unaffiliated/) {
            $text =~ s/^!\w+\s//;
            my $serverCmd = ($cmd eq 'say') ? "MSG" : "ACTION";
            $server->command("$serverCmd $chan $text");
            return;
      }#}}}
      #{{{ uptime
      if ($cmd eq 'uptime') {
        #get_uptime($chan,$server);
        signal_emit('show uptime',$server,$chan) if (is_loaded('uptime'));
        return;
      }#}}}
      #{{{ imdb
      if ($cmd eq 'imdb') {
        signal_emit('search imdb',$server,$chan,$text) if (is_loaded('imdb'));
        return;
      }#}}}
      #{{{ test nick stuff
      if ($cmd eq 'nickinfo') {
        print (CRAP "fix me");
        return;
      }#}}}
      #{{{ calculating
      if ($cmd eq 'calc') {
        signal_emit('calculate',$server,$chan,$text) if (is_loaded('calc'));
        return;
      }#}}}
      #{{{ isohunt
      if ($cmd eq 'ihq') {
        signal_emit('search isohunt',$server,$chan,$text) if (is_loaded('isohunt'));
        return;
      }#}}}
      #{{{ shorten 
      if ($cmd eq 'short') {
        my ($url) = $text =~ m{(https?://[^ ]+)}i;
        if ($url and is_loaded('ggl')) {
          my $shorten = scalar('Irssi::Script::ggl')->can('do_shortme')->($url);
          sayit($server,$chan,"[shorten] $shorten");
        }
        sayit($server,$chan,"I need a http://yourmom.com") if (not defined($url));
        return;
      }#}}}
      #{{{ get temp
      if ($cmd eq 'temp') {
        signal_emit('get temp',$server,$chan) if (is_loaded('smn'));
        return;
      }#}}}
      #{{{  googling
      if ($cmd eq 'google') {
        my ($query) = $text =~ /^!google\s+(.*)$/;
        if ($query =~ /google/) {
          sayit ($server,$chan,"no! this will break the interwebz!");
          return;
        } elsif ($query) {
          signal_emit('google me',$server,$chan,$query) if (is_loaded('google3'));
          return;
        }
      }#}}}
      #{{{ ping pong
      if ($cmd eq 'ping') { sayit($server,$chan,"pong"); return; }#}}}
      #{{{ dolar and pesos
      if ($cmd eq 'dolar' or $cmd eq 'pesos') {
        signal_emit('showme the money',$server,$chan,$text) if (is_loaded('dolar2'));
        return;
      }#}}}
      #{{{ last tweet from a uesr
      if ($cmd =~ /^l(?:ast)?t(?:weet)?$/) {
        my ($user) = $text =~ /^!l(?:ast)?t(?:weet)? @?(\w+)/;
        signal_emit("last tweet",$server,$chan,$user) if ($user and is_loaded('twitter'));
        sayit($server,$chan,"I need a twitter username") if (not $user);
        return;
      }#}}}
      #{{{ quotes and stuff
      if ($cmd =~ /^q(?:uote|add|del|last|search)?/) {
        if ($cmd eq 'qadd' and $chan =~ /sysarmy|moob/) {
          #keys are irc names, values are twitter @users 
          foreach my $name (keys %{$twitterusers_ref}) {
            $text =~ s/\b(?:$name)\b/\@$twitterusers_ref->{$name}/g;
          }
        }
        signal_emit('quotes',$server,$chan,$text) if (is_loaded('quotes'));
        return;
      }
      #}}}
      #{{{ my twitter is 
      if ($cmd eq 'mytwitteris') {
        #print (CRAP Dumper($twitterusers_ref));
        my ($givenName) = $text =~ /^!mytwitteris\s+(.+)$/;
        if (not $givenName) {
          #sayit($server,$chan,"if you tell me your twitter username I will replace your nick with that when I tweet");
          if (!exists ($twitterusers_ref->{$nick}) or !defined($twitterusers_ref->{$nick})) {
            sayit($server,$chan,"I dunno any twitter handle for $nick");
          } else {
              sayit($server,$chan,"I remember $nick is \@$twitterusers_ref->{$nick} on twitter");
              return;
            }
        } else {
          $givenName =~ s/^\@//;
          $twitterusers_ref->{$nick} = $givenName;
          store $twitterusers_ref, $twitterusersFile;
        }
      }
      #}}}
      #{{{ reimgur 
      if ($cmd eq 'imgur') {
        my ($url) = $text =~ m{^!imgur\s+(http://.*)$}i;
        signal_emit('reimgur',$server,$chan,$url) if (is_loaded('reimgur') and $url);
        sayit($server,$chan,"Imguraffe is my best friend!") if (not $url);
        return;
      }
      #}}}
      #{{{ karma is a bitch
      if ($cmd eq 'karma') {
        my ($name) = $text =~ /!karma\s+(.*)$/;
        $name = $nick if (not defined($name));
        if ($name eq $server->{nick}) {
          sayit($server,$chan,"my karma is over 9000 already!");
          return;
        }
        $name .= $server->{tag};
        signal_emit("karma check",$server,$chan,$name) if (is_loaded('karma'));
        return;
      }#}}}
      #{{{ checout user on twitter 
      if ($cmd eq 'user') {
        my ($who) = $text =~ /^!user\s+@?(\w+)/;
        signal_emit('teh fuck is who',$server,$chan,$who) if ($who and is_loaded('twitter'));
        sayit($server,$chan,"!user <twitter_username>") if (!defined($who));
        return;
      }#}}}
    }
  } #cmd check ends here. begin general text match

  #{{{ GENERAL URL MATCH
	if ($text =~ m{(https?://[^ ]*)}) {
    my $url = $1;
    signal_emit('write to file',"<$nick> $text") if ($chan =~ /sysarmy|moob/ and is_loaded('savelink'));
    return if ($url =~ /(wikipedia)|(facebook)|(fbcdn)/i);
    #{{{ site specific stuff
    if ($url =~ m{http://www\.imdb\.com/title/(tt\d+)}) {
        my $imdb = $1;
        signal_emit('search imdb',$server,$chan,$imdb) if (is_loaded('imdb'));
        return;
    }
    #youtube here
    if ($url =~ /$youtubex/) {
      my $vid = $1;
      signal_emit('check tubes',$server,$chan,$vid) if (is_loaded('youtube'));
      return;
    }
    #twitter status fetch
    if ($url =~ m{twitter\.com(?:/#!)?/[^/]+/status(?:es)?/\d+}) {
      signal_emit('fetch tweet',$server,$chan,$url) if (is_loaded('twitter'));
      return;
    }
    # http://www.chromaplay.com
    if ($url =~ m{chromaplay\.com/\?ytid=([^ &]{11})$}) {
      my $vid = $1;
      signal_emit('check tubes',$server,$chan,$vid) if (is_loaded('youtube'));
      return;
    }
    if ($url =~ m{mercadolibre\.com\.ar/(MLA-\d+)}) {
      my $mla = $1;
      $mla =~ s/-//;
      signal_emit('mercadolibre',$server,$chan,$mla);
      return;
    }
    #future reddit api here 
    #imgur api?
    if ($url =~ /imgur/) {
      if ($url =~ m{http://i\.imgur\.com/(\w{5})h?\.[pjgb]\w{2}$}) { #h is for hires
          $url = "http://imgur.com/$1" if ($1);
      }
    } #}}}

    #any other http link fall here
    signal_emit('check title',$server,$chan,$url);
  } # URL match ends here. lo que sigue seria general text match, como el de replace and others stuff que no me acuerdo
  #}}}
  #{{{ ## do stuff with anything that is not a cmd or a http link
  ## karma karma and karma
  if ($text =~ /(\w+)(([-+])\3)/) { 
    #no self karma
    return if ($nick =~ /^${1}$/i);
    my $name = $1 . $server->{tag} if $1;
    my $op = $2 if $2;
    signal_emit('karma bitch',$name,$op) if (is_loaded('karma'));
  } #}}}
} #incoming puiblic message ends here
#{{{ signal and stuff
sub is_loaded { return exists($Irssi::Script::{shift(@_).'::'}); }
sub sayit {
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}
#signal_add("message private","msg_priv");

signal_add("message public","incoming_public");

settings_add_str('bot config', 'halpcommands',              '');
settings_add_str('bot config', 'active_networks',           '');
settings_add_str('bot config', 'myUserAgent',               '');

#apikeys
settings_add_str('twitter', 'twitter_apikey',               '');
settings_add_str('twitter', 'twitter_secret',               '');
settings_add_str('twitter', 'twitter_access_token',         '');
settings_add_str('twitter', 'twitter_access_token_secret',  '');
settings_add_str('twitter', 'sysarmy_access_token',         '');
settings_add_str('twitter', 'sysarmy_access_token_secret',  '');
settings_add_str('imgur'  , 'imgurkey',                     '');

#}}}
#{{{ #signal registration
signal_register( { 'show uptime'      => [ 'iobject', 'string'            ]});  #server,chan
signal_register( { 'search imdb'      => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'calculate'        => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'search isohunt'   => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'get temp'         => [ 'iobject', 'string'            ]});  #server,chan
signal_register( { 'google me'        => [ 'iobject', 'string','string'   ]});  #server,chan,query
signal_register( { 'check title'      => [ 'iobject', 'string','string'   ]});  #server,chan,url
signal_register( { 'check tubes'      => [ 'iobject', 'string','string'   ]});  #server,chan,vid
signal_register( { 'quotes'           => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'showme the money' => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'teh fuck is who'  => [ 'iobject', 'string','string'   ]});  #server,chan,who
signal_register( { 'fetch tweet'      => [ 'iobject', 'string','string'   ]});  #server,chan,url
signal_register( { 'last tweet'       => [ 'iobject', 'string','string'   ]});  #server,chan,user
signal_register( { 'karma check'      => [ 'iobject', 'string','string'   ]});  #server,chan,name
signal_register( { 'karma bitch'      => [            'string','string'   ]});  #name,op
signal_register( { 'post twitter'     => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'post sysarmy'     => [ 'iobject', 'string','string'   ]});  #server,chan,text
signal_register( { 'tweet quote'      => [            'string'            ]});  #addme
signal_register( { 'mercadolibre'     => [ 'iobject', 'string','string'   ]});  #server,chan,mla
signal_register( { 'reimgur'          => [ 'iobject', 'string','string'   ]});  #server,chan,url
signal_register( { 'write to file'    => [            'string'            ]});  #text

#}}} 
#{{{ signal register halp
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
##}}}
