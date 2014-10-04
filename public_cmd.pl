#public commands
use Irssi qw (  print signal_emit 
                signal_add signal_register 
                settings_get_str settings_add_str settings_set_str 
                get_irssi_dir
             );
use strict;
use warnings;
use Storable qw (store retrieve);
use Data::Dumper;
use utf8;
use Time::HiRes;


#{{{ init stuff

settings_add_str('bot config', 'halpcommands',    '');
settings_add_str('bot config', 'halp_sysarmy',    '');
settings_add_str('bot config', 'active_networks', '');
settings_add_str('bot config', 'myUserAgent',     '');
settings_add_str('bot config', 'bot_masters',     '');

#nick 2 twitter list
our $twit_users_file 
  = get_irssi_dir() . '/scripts/datafiles/twitternames.storable';

our $twit_users_ref = eval { retrieve($twit_users_file) } || [];
#print (CRAP Dumper($twit_users_ref));

# static and complex regexes
my $youtubex = qr{(?x-sm:
    (?:http://)?(?:www\.)?      #optional 
    youtu(?:\.be|be\.com)       #matches the short youtube link
    /                           #the 1st slash
    (?:watch\?\S*v=)?           #this wont be here if it's short uri
    (?:user/.*/)?               #username can be 
    ([^&]{11})                  #the vid id
)};

my $karmagex = qr{(?x-sm:
                    ([\w\[\]`|\\-]+)  #thingy can be \w with []`|\-
                    (([-+])\3)        #capture a + or - 
                                      #then look for the same symbol with \3
                                      #\1 is the 1st word
                                      #\2 is the opeartor ++ or --
                  )};

my $karma_antiflood_time = 2;
my $karma_lasttime = 0;
my $ignore_karma_from = {};

##multiline karma check
#my $karmagex = qr{([a-zA-Z0-9_\[\]`|\\-]+(?:--|\+\+))}; 
#}}}

sub incoming_public {
  my($server, $text, $nick, $mask, $chan) = @_;
  my $active_networks = settings_get_str('active_networks');
  print (CRAP "im not being used on any network!") if (!$active_networks);
  return if $server->{tag} !~ /$active_networks/;

  #check if someone said a command
  if ($text =~ /^!(\w+)\b/) {
    my $cmd = $1;
    #{{{ halps 
    if ($cmd =~ /^h[ea]lp$/) {
      my $defaultcmd = settings_get_str('halpcommands') . ' ';
      $defaultcmd   .= settings_get_str('halp_sysarmy') if ($chan eq '#sysarmy');
      sayit($server, $chan, $defaultcmd);
      return;
    }#}}}
    #{{{ add help
    if ($cmd eq 'addhalp' and is_master($mask)) {
        my ($newhalp) = $text =~ /^!addhalp\s+(.*)$/;
        #my $halps = settings_get_str('halpcommands');
        #O$halps .= " $newhalp" if ($newhalp);
        settings_set_str('halpcommands', settings_get_str('halpcommands') . " $newhalp") if (defined($newhalp));
        sayit($server,$chan,settings_get_str('halpcommands'));
        return;
    }#}}}
    #{{{ fortune cookies
    if ($cmd eq 'fortune') {
      my @cookie = qx(/usr/bin/fortune -s);
      sayit($server,$chan,"[fortune] $_") foreach @cookie;
      return;
    }#}}}
    #{{{ do this and say that
    if (($cmd eq 'do' or $cmd eq 'say') and is_master($mask)) {
      $text =~ s/^!\w+\s//;
      my $serverCmd = ($cmd eq 'say') ? "MSG" : "ACTION";
      $server->command("$serverCmd $chan $text");
      return;
    }#}}}
    #{{{ uptime
    if ($cmd eq 'uptime') {
      #get_uptime($chan,$server);
      signal_emit('show uptime',$server,$chan) if (isLoaded('uptime'));
      return;
    }#}}}
    #{{{ imdb
    if ($cmd eq 'imdb') {
      signal_emit('search imdb',$server,$chan,$text) if (isLoaded('imdb'));
      return;
    }#}}}
    #{{{ test nick stuff
    #if ($cmd eq 'nickinfo') {
    #  print (CRAP "fix me");
    #  return;
    #}#}}}
    #{{{ !calc(ulate)
    if ($cmd eq 'calc') {
      signal_emit('calculate',$server,$chan,$text) if (isLoaded('calc'));
      return;
    }#}}}
    #{{{ !short
    if ($cmd eq 'short') {
      my ($url) = $text =~ m{(https?://[^ ]+)}i;
      if ($url and isLoaded('ggl')) {
        my $shorten = scalar('Irssi::Script::ggl')->can('do_shortme')->($url);
        sayit($server,$chan,"[shorten] $shorten");
      }
      sayit($server, $chan, "I cant shorten  http://domain.com ") if (not defined($url));
      return;
    }#}}}
    #{{{ !temp
    if ($cmd eq 'temp') {
      #signal_emit('get temp',$server,$chan) if (isLoaded('smn'));
      sayit($server,$chan,"use !clima instead");
      return;
    }#}}}
    #{{{  googling
    if ($cmd eq 'google') {
      my ($query) = $text =~ /^!google\s+(.*)$/;
      if (!$query) {
        sayit($server, $chan, 'too lazy to google it yourself?');
        return;
      } 
      elsif ($query =~ /\bgoogle\b/i) {
        sayit($server, $chan, 'no! this will break the interwebz!');
        return;
      } 
      else {
        signal_emit('google me', $server, $chan, $query) if (isLoaded('google3'));
        return;
      } 
    }#}}}
    #{{{ !ping !pong
    if ($cmd =~ /p([ioua])ng/) {
      my $v = { 'i' => 'o',
                'o' => 'i',
                'u' => 'a',
                'a' => 'u'
              };
      sayit($server, $chan, 'p'.${$v}{$1}.'ng');
      return;
    }#}}}
    #{{{ !dol[ao]r and !pesos
    if ($cmd =~ /^dol[ao]r$/ or $cmd eq 'pesos') {
      #sayit($server,$chan,"service down. but I can guess the price is still high :(");
      signal_emit('showme the money', $server, $chan, $text) if (isLoaded('dolar2'));
      return;
    }#}}}
    #{{{ !lt last tweet from a user
    if ($cmd =~ /^l(?:ast)?t(?:weet)?$/) {
      my $user = undef;
      ($user) = $text =~ /^!l(?:ast)?t(?:weet)? @?(\w+)/;
      if (not defined($user)) {
        if (not exists($twit_users_ref->{$nick})) {
          sayit($server, $chan, "you dont have a twitter handle, so I'll need a twitter username");
          return;
        } else { $user = $twit_users_ref->{$nick} }
      }  
      signal_emit("last tweet",$server,$chan,$user) if (defined($user) and isLoaded('twitter'));
      return;
    }#}}}
    #{{{ !quotes and stuff
    if ($cmd =~ /^q(?:uote|add|del|last|search)?/) {
      my $tweetme = $text;
      if ($cmd eq 'qadd' and $text ne '!qadd' and $chan =~ /sysarmy|ssqquuee/) {
        $tweetme =~ s/^!qadd\s+//;
        #keys are irc $nicknames, values are @twitterhandle
        foreach (keys %{$twit_users_ref}) {
          $tweetme =~ s/\b\Q$_\E\b/\@$twit_users_ref->{$_}/g;
        }
        #print (CRAP $tweetme);
        $tweetme .= " \n".'#sysarmy';
        my $tweeturl = scalar('Irssi::Script::sysarmy')->can('tweetquote')->($tweetme);
        $text .= (defined($tweeturl) ? "======${tweeturl}" : '');
      }
      signal_emit('quotes', $server, $chan, $text) if (isLoaded('quotes'));
      return;
    }
    #}}}
    #{{{ !imgur reimgur 
    if ($cmd eq 'imgur') {
      my ($url) = $text =~ m{^!imgur\s+(https?://.*)$}i;
      signal_emit('reimgur',$server,$chan,$url) if (isLoaded('reimgur') and $url);
      sayit($server,$chan,"Imguraffe is my best friend!") if (not $url);
      return;
    }
    #}}}
    #{{{ karma is a bitch
    if ($cmd eq 'karma') {
      my ($name) = $text =~ /!karma\s+([a-zA-Z0-9_\[\]`|\\-]+)/;
      $name = $nick if (not defined($name));
      if ($name eq $server->{nick}) {
        sayit($server,$chan,"my karma is over 9000 already!");
        return;
      }
      if ($name eq 'sQuEE')   { sayit($server,$chan,"karma for $name: 🍺 ");                 return; }

      if ($name =~ /^osx|mac(?:intosh)?$/i)  { sayit($server,$chan,"karma for $name: ⌘");   return; }

      if ($name =~ /^iphone|ios$/i)  { sayit($server,$chan,"karma for ${name}: 📱 ");        return; }

      if ($name =~ /^perl$/i) { sayit($server, $chan, "karma for ${name}: 🐫 ");             return; }


      $name .= $server->{tag};
      signal_emit("karma check",$server,$chan,$name) if (isLoaded('karma'));
      return;
    }
    # !setkarma
    if ($cmd eq 'setkarma' and is_master($mask)) {
      my ($key,$val) = $text =~ /^!setkarma\s+(.+)=(.*)$/;
      signal_emit("karma set",$server,$chan,$key.$server->{tag},$val) if (isLoaded('karma') and $key and $val);
      return;
    }
    #}}}
    #{{{ !rank 
    if ($cmd eq 'rank' ) { 
      signal_emit("karma rank",$server,$chan) if (isLoaded('karma'));
    }
    #}}}
    #{{{ !flip}}}
    if ($cmd eq 'flip' && is_master($mask)) {
      signal_emit('karma flip', $server, $chan) if (isLoaded('karma'));
    }
    #{{{ [TWITTER] !mytwitteris 
    if ($cmd eq 'mytwitteris') {
      #print (CRAP Dumper($twit_users_ref));
      my ($givenName) = $text =~ /^!mytwitteris\s+(.+)$/;
      unless ($givenName) {
        #sayit($server,$chan,"if you tell me your twitter username I will replace your nick with that when I tweet");
        if (not exists ($twit_users_ref->{$nick})) {
          sayit($server,$chan,"I dunno any twitter handle for $nick. Add yours with !mytwitteris \@yourtwitter.");
        }
        else {
          sayit($server,$chan,"I remember $nick is \@$twit_users_ref->{$nick} on twitter");
          return;
        }
      }
      else {
        $givenName =~ s/^\@//;
        $twit_users_ref->{$nick} = $givenName;
        store $twit_users_ref, $twit_users_file;
        sayit($server,$chan,"okay!") if (exists $twit_users_ref->{$nick});
      }
    }
    #}}}
    #{{{ [TWITTER] !ishere
    if ($cmd eq 'ishere') {
      my ($givenName) = $text =~ /^!ishere\s+(.+)$/;
      if ($givenName) {
        $givenName =~ s/^\@//;
        #check if given is a nick and has a twitter user 
        if (exists ($twit_users_ref->{$givenName})) {
          sayit($server,$chan,"I know $givenName is \@$twit_users_ref->{$givenName} on twitter");
          return;
        }
        #check if given is a twitter and has an ircname
        foreach my $ircname (keys %$twit_users_ref) {
          if ($givenName =~ /^$twit_users_ref->{$ircname}$/i) {
            sayit($server,$chan,"I've been told \@$givenName is $ircname here on freenode");
            return;
          }
        }
        sayit($server,$chan,"nope, I dunno any $givenName");
        return;
        #so lazy
      }
      else {
        sayit($server,$chan,"I might know who is who on twitter and irc");
        return;
       }
     }
    #}}} 
    #{{{ [TWITTER] !isnolongerhere 
    if ($cmd eq 'isnolongerhere' and is_master($mask)) {
      my ($givenName) = $text =~ /^!isnolongerhere\s+(.+)$/;
      if ($givenName) {
        $givenName =~ s/^\@//;
        delete $twit_users_ref->{$givenName}; # if (exist ($twit_users_ref->{$givenName}));
        if (not exists $twit_users_ref->{$givenName}) {
          store $twit_users_ref, $twit_users_file;
          sayit($server,$chan,"deleted!") 
        }
        return;
      }
    }#}}}
    #{{{ [TWITTER] checkout user on twitter 
    if ($cmd eq 'user') {
      my ($who) = $text =~ /^!user\s+@?(\w+)/;
      signal_emit('teh fuck is who',$server,$chan,$who) if ($who and isLoaded('twitter'));
      sayit($server,$chan,"!user <twitter_username>") if (!defined($who));
      return;
    }#}}}
    #{{{ [TWITTER] !tt post tweet to sysarmy 
    if ($cmd eq 'tt' and $chan =~ /sysarmy|ssqquuee/) {
      if ($text eq '!tt') {
        sayit($server,$chan,'send a tweet to @sysARmIRC');
        return;
      }
      $text =~ s/!tt\s+//;
      foreach (keys %{$twit_users_ref}) {
        $text =~ s/\b\Q$_\E\b/\@$twit_users_ref->{$_}/g;
      }
      signal_emit('post sysarmy',$server,$chan,$text) if (isLoaded('sysarmy'));
      return;
    } #}}}
    #{{{ !ddg cuac cuac go 
    if ($cmd eq 'ddg') {
      my ($query) = $text =~ /^!ddg\s+(.*)$/;
      unless ($query) {
        sayit($server,$chan,"cuac cuac go!");
        return;
      } else {
        signal_emit('cuac cuac go',$server,$chan,$query) if (isLoaded('duckduckgo'));
      }
    }#}}}
   #{{{ !btc bitcoins
    if ($cmd =~ m{^bi?tc(?:oin)?s?}) {
      signal_emit('gold digger', $server, $chan, 'btc') if (isLoaded('blockio'));
    }#}}}
   #{{{ !ltc litecoins
    if ($cmd =~ m{^li?te?c(?:oin)?s?}) {
      signal_emit('silver digger', $server, $chan, 'ltc') if (isLoaded('blockio')); 
    }#}}}
    #{{{ !tpb the pirate bay
    if ($cmd eq 'tpb') {
      my ($booty) = $text =~ /!tpb\s+(.*)$/;
      if ($booty and isLoaded('tpb')) { 
        signal_emit('arrr', $server, $chan, $booty);
      } 
      else {
        sayit($server, $chan, 
              qq(Ahoy, Matey! I've sailed the seven proxies!)
             );
      }
    }#}}}
    #{{{ !clima 
    if ($cmd eq 'clima') {
      my ($city) = $text =~ /^!clima\s+(.*)$/;
      if (isLoaded('clima') and defined($city)) { 
        signal_emit('weather', $server, $chan, $city);
      } else { sayit($server, $chan, "!clima <una ciudad de argentina>"); }
    } #}}}
    #{{{ wolfram alpha !wa 
    if ($cmd eq 'wa') {
      my ($query) = $text =~ /^!wa\s+(.*)$/;
      if (isLoaded('wolfram') and defined($query)) { 
        signal_emit('wolfram', $server, $chan, $query);
      } else { sayit($server, $chan, "I can pass on any question to this dude I know, Wolfram Alpha."); }
    } #}}}
    #{{{ !bofh 
    if ($cmd eq 'bofh') {
      signal_emit('bofh', $server, $chan) if (isLoaded('bofh'));
    } #}}}
    #{{{ #!coins 
    if ($cmd eq 'coins' ) {
      my ($coin1, $coin2) = $text =~ m{^!coins ([a-zA-Z0-9]+)[-_\|/:!]([a-zA-Z0-9]+)$};
      if ($coin1 and $coin2) {
        signal_emit('insert coins', $server, $chan, "${coin1}_${coin2}") if (isLoaded('coins'));
      } else { sayit ($server, $chan, "usage: !coins coin1/coin2 - Here is a list: http://www.cryptocoincharts.info/v2"); }
    } #}}} 
    #{{{ #!doge WOW SUCH COMMAND 
    if ($cmd =~ m{doge(?:coin)?s?}) {
      signal_emit('such signal', $server, $chan, $text) if (isLoaded('doge'));
    }

    if ($cmd =~ m{^(?:such|many)difficult$}) {
      signal_emit('such difficult', $server, $chan, $text) if (isLoaded('doge'));
    }
    #}}}
    ##{{{ !bash bash.org quotes
    if ($cmd =~ m{^bash\b}) {
      signal_emit('bash quotes', $server,$chan, $text) if (isLoaded('bash'));
    }
    ##}}}
    ##{{{ !subte
    if ($cmd eq 'subte') {
      my ($linea) = $text =~ m{^!subte\s+([abcdehpABCDEHP])$};
      sayit ($server, $chan, "que linea?") unless ($linea);
      signal_emit('hay subte', $server, $chan, uc($linea)) if ($linea);
    }
    ##}}}
  } #cmd check ends here. begin general text match

#################################################################################################################################
  #
  #{{{ GENERAL URL MATCH
  if ($text =~ m{(https?://[^ ]+)}) {
    my $url = $1;
    return if ($url =~ /wikipedia|facebook|fbcdn/i);
    #if ($chan =~ /sysarmy|ssqquuee/ and isLoaded('savelink')) {
    #  signal_emit('write to file',"<$nick> $text");
    #}
    #site specific stuff
    if ($url =~ m{http://www\.imdb\.com/title/(tt\d+)}) {
        signal_emit('search imdb',$server,$chan,$1) if ($1 and isLoaded('imdb'));
        return;
    }
    #youtube here
    if ($url =~ /$youtubex/) {
      signal_emit('check tubes',$server,$chan,$1) if (isLoaded('youtube'));
      return;
    }
    #vimeo vid
    #if ($url =~ m{vimeo\.com/(\d+)}) {
    #  signal_emit('check vimeo',$server,$chan,$1) if (isLoaded('vimeo'));
    #  return;
    #}
    #
    #show twitter user bio info from an url 
    if ($url =~ m{twitter\.com/(\w+)$}) {
      signal_emit('teh fuck is who',$server,$chan,$1) if ($1 and isLoaded('twitter'));
      return;
    }
    #twitter status fetch
    if ($url =~ m{twitter\.com(?:/\#!)?/[^/]+/status(?:es)?/\d+}) {
      signal_emit('fetch tweet',$server,$chan,$url) if (isLoaded('twitter'));
      return;
    }
    # http://www.chromaplay.com
    if ($url =~ m{chromaplay\.com/\?ytid=([^ &]{11})$}) {
      signal_emit('check tubes',$server,$chan,$1) if ($1 and isLoaded('youtube'));
      return;
    }
    if ($url =~ m{mercadolibre\.com\.ar/(MLA-\d+)}) {
      $_ = $1 and s/-//;
      signal_emit('mercadolibre',$server,$chan,$_);
      return;
    }
    #future reddit api here 
    #imgur api?
    if ($url =~ m{http://i\.imgur\.com/(\w{5,8})h?\.[pjgb]\w{2}$}) { #h is for hires
        $url = "http://imgur.com/$1" if ($1);
    }
    #quickmeme
    if ($url =~ /qkme\.me/) {
      if ($url =~ m{http://i\.qkme\.me/(\w{6})\.[pjgb]\w{2}$}) {
          $url = "http://www.quickmeme.com/meme/$1" if ($1);
      }
    }
    #any other http link fall here
    signal_emit('check title', $server, $chan, $url);
  } #}}} URL match ends here. lo que sigue seria general text match.
  #{{{ do stuff with anything that is not a cmd or a http link
  #
  ## karma check against the text 
#  my @karmacheck = $text =~ /$karmagex/g;
#  if (scalar(@karmacheck) > 0) {
#    foreach (@karmacheck) {
#      my ($thingy, $op) = ( /^(.+)([+-]{2})$/ );
#      next if ($thingy eq $nick);
#      $thingy .= $server->{tag};
#      signal_emit('karma bitch', $thingy, $op) if (isLoaded('karma'));
#    }
 ## KARMA KARMA AND KARMA++
  if ($text =~ /$karmagex/) {
    #somebody wants some karma, but no self karma.
    return if ($nick eq $1);
    
    my $thingy = $1 . $server->{tag} if $1;     #karmas are per server.
    my $op = $2 if $2;

    #fancy anti-karmabot mechanism.
    return if (time - $karma_lasttime < $karma_antiflood_time);
    signal_emit('karma bitch', $thingy, $op) if (     isLoaded('karma') 
                                                and defined($thingy) 
                                                and defined($op));
    $karma_lasttime = time;
  } 
} #incoming puiblic message ends here #}}}
#{{{ signal and stuff
sub is_master {
  my $mask = shift;
  my @masters = split ',', settings_get_str('bot_masters');
  my $is_master = undef;

  foreach my $master (@masters) {
    if ($mask eq $master) {
      $is_master = 'true';
      last;
    }
  }
  return $is_master;
}
sub isLoaded { return exists($Irssi::Script::{shift(@_).'::'}); }
sub sayit { my $s = shift; $s->command("MSG @_"); }
signal_add("message public","incoming_public");

#apikeys
settings_add_str('wolfram', 'wa_appid',           '');
#}}}
#{{{ # if you are signal, register here
signal_register( { 'show uptime'      => [ 'iobject','string'                   ]}); #server,chan
signal_register( { 'search imdb'      => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'calculate'        => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'search isohunt'   => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'get temp'         => [ 'iobject','string'                   ]}); #server,chan
signal_register( { 'google me'        => [ 'iobject','string','string'          ]}); #server,chan,query
signal_register( { 'check title'      => [ 'iobject','string','string'          ]}); #server,chan,url
signal_register( { 'karmadecay'       => [ 'iobject','string','string'          ]}); #server,chan,url
signal_register( { 'check tubes'      => [ 'iobject','string','string'          ]}); #server,chan,vid
signal_register( { 'check vimeo'      => [ 'iobject','string','string'          ]}); #server,chan,vid
signal_register( { 'quotes'           => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'add quotes'       => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'showme the money' => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'teh fuck is who'  => [ 'iobject','string','string'          ]}); #server,chan,who
signal_register( { 'fetch tweet'      => [ 'iobject','string','string'          ]}); #server,chan,url
signal_register( { 'last tweet'       => [ 'iobject','string','string'          ]}); #server,chan,user
signal_register( { 'karma check'      => [ 'iobject','string','string'          ]}); #server,chan,name
signal_register( { 'karma set'        => [ 'iobject','string','string','string' ]}); #server,chan,key,val
signal_register( { 'karma bitch'      => [           'string','string'          ]}); #name,op
signal_register( { 'karma rank'       => [ 'iobject','string'                   ]}); #server,chan
signal_register( { 'karma flip'       => [ 'iobject','string'                   ]}); #server,chan
signal_register( { 'post twitter'     => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'post sysarmy'     => [ 'iobject','string','string'          ]}); #server,chan,text
signal_register( { 'tweet quote'      => [           'string'                   ]}); #addme
signal_register( { 'mercadolibre'     => [ 'iobject','string','string'          ]}); #server,chan,mla
signal_register( { 'reimgur'          => [ 'iobject','string','string'          ]}); #server,chan,url
signal_register( { 'write to file'    => [           'string'                   ]}); #text
signal_register( { 'cuac cuac go'     => [ 'iobject','string','string'          ]}); #server,chan,query
signal_register( { 'gold digger'      => [ 'iobject','string','string'          ]}); #server,chan,btc
signal_register( { 'silver digger'    => [ 'iobject','string','string'          ]}); #server,chan,ltc
signal_register( { 'insert coins'     => [ 'iobject','string','string'          ]}); #server,chan,$pair
signal_register( { 'such signal'      => [ 'iobject','string','string'          ]}); #server,chan,$text
signal_register( { 'such difficult'   => [ 'iobject','string','string'          ]}); #server,chan,$text
signal_register( { 'arrr'             => [ 'iobject','string','string'          ]}); #server,chan,$text
signal_register( { 'weather'          => [ 'iobject','string','string'          ]}); #server,chan,$city
signal_register( { 'wolfram'          => [ 'iobject','string','string'          ]}); #server,chan,$query
signal_register( { 'bofh'             => [ 'iobject','string'                   ]}); #server,chan,$query
signal_register( { 'bash quotes'      => [ 'iobject','string','string'          ]}); #server,chan,$text
signal_register( { 'hay subte'        => [ 'iobject','string','string'          ]}); #server,chan,$linea
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
