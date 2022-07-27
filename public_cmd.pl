# public commands
# FIXME this is getting awfuly bloated.

use Irssi qw (  print signal_emit
                signal_add signal_register
                settings_get_str settings_add_str settings_set_str
                get_irssi_dir
             );
use v5.32;
use strict;
use warnings;
use utf8;
use Storable qw(store retrieve);
use Data::Dumper;
use Time::HiRes;
use Encode qw (encode decode);

#{{{ initial variables

settings_add_str('bot config', 'halpcommands',    '');
settings_add_str('bot config', 'halp_sysarmy',    '');
settings_add_str('bot config', 'active_networks', '');
settings_add_str('bot config', 'myUserAgent',     '');
settings_add_str('bot config', 'bot_masters',     '');
settings_add_str('bot config', 'flip_table_status', '0');

#nick 2 twitter list
our $twit_users_file
  = get_irssi_dir() . '/scripts/datafiles/twitternames.storable';

our $twit_users_ref = eval { retrieve($twit_users_file) } || [];
#print (CRAP Dumper($twit_users_ref));

# static and complex regexes
my $youtubex
  = qr{(?x-sm:
    https?://(?:www\.)?         #optional
    youtu(?:\.be|be\.com)       #matches the short youtube link
    /                           #the 1st slash
    (?:watch\?\S*v=)?           #this wont be here if it's short uri
    #(?:user/.*/)?              #username can be
    (?:channel/)?               #channel id are 24chars
    ([\w-]{11,24})              #the vid id or channel id
)};

my $karma_thingy = qr{[\w\[\]`|\-^\\.]+}; #thingy can be \w with .{}[]`|\-^
my $karmagex
  = qr{(?x-sm:
      ($karma_thingy)
      ( ([-+])\3 )      #match a single - or + then match the same symbol
                        #save the matched ++ or -- into \2
                        #\1 is the thingy we matched
                        #\2 is the matched ++ or --
                        #\3 is the single + or -
)};

my $karma_antiflood_time = 2;
my $karma_lasttime = 0;
my $ignore_karma_from = {};

#novelty stuff
my %faces = (
  'shrug' => '‾\_(ツ)_/‾',
  'wot'   => 'ಠ_ಠ'       ,
  'dunno' => '‾\(°_o)/‾' ,
  'caca'  => '💩'         ,
);


#}}}
#handles all incoming public messages.
sub incoming_public {
  my($server, $text, $nick, $mask, $chan) = @_;
  #this needs to be a hash.
  my $active_networks = settings_get_str('active_networks');
  print (CRAP "im not being used on any network!") if (!$active_networks);
  return if $server->{tag} !~ /$active_networks/;

  #strip out control chars
  $text =~ s/\x03\d{0,2}(,\d{0,2})?//g; #colors
  $text =~ s/\x02|\x16|\x1F|\x0F//g;    #bold, inverse, underline and clear

  my $elsewhere = '';
  if ($nick =~ /^nbot/) {
    ($nick) = $text =~ m#^<([^>]+)>\s+#;
    $text =~ s#^<([^>]+)>\s+##;
    $nick =~ s#\W#_#g;
  }

  #check if someone said a command
  if (my ($cmd) = $text =~ /^!(\w+)\b/) {
    #{{{ halps
    if ($cmd =~ /^h[ea]lp$/) {
      my $defaultcmd = settings_get_str('halpcommands') . ' ';
      $defaultcmd .= settings_get_str('halp_sysarmy')   if $chan =~ /##?sysarmy(?:-en)?/;
      $defaultcmd .= settings_get_str('halp_linuxchix') if $chan eq '#linuxchixar';
      sayit($server, $chan, $defaultcmd);
      return;
    }#}}}
    #{{{ add help
    if ($cmd eq 'addhalp' and is_sQuEE($mask)) {
      my ($newhalp) = $text =~ /^!addhalp\s+(.*)$/;
      settings_set_str(
        'halpcommands',
        settings_get_str('halpcommands') . " $newhalp"
      ) if (defined($newhalp));

      sayit($server, $chan, settings_get_str('halpcommands'));
      return;
    }#}}}
    #{{{ fortune cookies
    if ($cmd eq 'fortune') {
      my @cookie = qx(/usr/bin/fortune -s);
      sayit($server, $chan, "[fortune] $_") foreach @cookie;
      return;
    }#}}}
    #{{{ do this and say that
    if (($cmd eq 'do' or $cmd eq 'say') and is_sQuEE($mask)) {
      $text =~ s/^!\w+\s//;
      my $serverCmd = ($cmd eq 'say') ? "MSG" : "ACTION";
      $server->command("$serverCmd $chan $text");
      return;
    }#}}}
    #{{{ uptime
    if ($cmd eq 'uptime') {
      #get_uptime($chan,$server);
      signal_emit('show uptime', $server, $chan) if is_loaded('uptime');
      return;
    }#}}}
    #{{{ imdb
    if ($cmd eq 'imdb') {
      signal_emit('search imdb', $server, $chan, $text) if is_loaded('imdb');
      return;
    }#}}}
    #{{{ !calc(ulate)
    if ($cmd eq 'calc') {
      signal_emit('calculate', $server, $chan, $text) if is_loaded('calc');
      return;
    }#}}}
    #{{{ !short
    if ($cmd eq 'short') {
      my ($url) = $text =~ m{(https?://[^ ]+)}i;
      if ($url and is_loaded('tinyurl')) {
        my $shorten = scalar('Irssi::Script::tinyurl')->can('do_shortme')->($url);
        sayit($server, $chan, "[shorten] $shorten");
      }
      sayit($server, $chan, 'I can shorten a URL with TinyURL.') if not defined $url;
      return;
    }#}}}
    #{{{ googling
    if ($cmd eq 'google') {
      my ($query) = $text =~ /^!google\s+(.*)$/;
      if (not $query) {
        sayit($server, $chan, 'LMGTFY');
        return;
      }
      elsif ($query =~ /\bgoogle\b/i) {
        sayit($server, $chan, 'no! this will break the interwebz!');
        return;
      }
      elsif (is_loaded('google3')) {
        signal_emit('google me', $server, $chan, $query);
        return;
      }
    }#}}}
    #{{{ !ping !pong
    if ($cmd =~ /p([ioua])ng/) {
      my $v = { 'i' => 'o',
                'o' => 'i',
                'u' => 'a',
                'a' => 'u',
                '1' => '0'
              };
      sayit($server, $chan, 'p' . ${$v}{$1} . 'ng');
      return;
    }#}}}
    #{{{ !euro
    if ($cmd =~ /^euros?$/) {
      signal_emit( 'showme the euros', $server, $chan, $text) if is_loaded('euro');
      return;
    }
    #}}}
    #{{{ !dol[ao]rsi
    if ($text =~ m{^!(doll?[aeo]rs?|pesos?)\s?(\d+k*)?$}) {
      my $coin = $1;
      my $howmuch = (defined($2) ? $2 : '1');
      $howmuch =~ s/k/000/g;
      signal_emit( 'showme the usd', $server, $chan, $coin, $howmuch) if is_loaded('dolarya');
      return;
    }
    #}}}
    #{{{ !lt last tweet from a user
    if ($cmd =~ /^l(?:ast)?t(?:weet)?$/) {
      my $user = undef;
      ($user) = $text =~ /^!l(?:ast)?t(?:weet)? @?(\w+)/;
      if (not defined($user)) {
        if (not exists($twit_users_ref->{$nick})) {
          sayit(
            $server, $chan,
            "you dont have a twitter handle, so I'll need a twitter username"
          );
          return;
        }
        else {
          $user = $twit_users_ref->{$nick};
        }
      }
      signal_emit("last tweet", $server, $chan, $user)
        if defined($user) and is_loaded('twitter');
      return;
    }#}}}
    #{{{ [QUOTE] !qadd and tweet a quote
    if ($cmd eq 'qadd' and is_loaded('quotes')) {
      my ($quote_this) = $text =~ /^!qadd\s(.*)$/;
      unless (defined($quote_this)) {
        sayit(
          $server, $chan,
          'EL_FORMATO IS DEFINED AS: <@supreme_leader> because I say so. | '
          . '<peasant1> yes m\'Lord. | '
          . '<peasant2> it wont happen again, Sire. | '
          . '<peasant-n> please forgive us.'
        );
        return;
      }

      #got the quote here. now send it to file. get the confirmation back.
      my $message_out = undef;
      if (is_loaded('quotes')) {
        $message_out
          = scalar('Irssi::Script::quotes')->can('quotes_add')->(
              $quote_this,
              $server->{tag},
              $chan
            ) ? 'quote added' : 'cannot add quotes right now';

        if ($chan =~ /sysarmy|ssqquuee/ and is_loaded('sysarmy')) {
          #gotta tweet this to sysarmIRC
          #first we remove the @ from ops.
          $quote_this =~ s/\B@//g;

          #we replace all the nick with @twitternames
          #keys are irc $nicknames, values are @twitterhandle
          foreach my $nick (keys %{$twit_users_ref}) {
            $quote_this =~ s/\b\Q$nick\E\b/\@$twit_users_ref->{$nick}/g;
          }

          # replace | for \n
          $quote_this =~ s{(?:\s+)?\|(?:\s+)?}{\n}g;

          #append some branding.
          $quote_this .= "\n\n" . '#sysarmy';

          #and off we go.
          my $status = scalar('Irssi::Script::sysarmy')->can('send_to_twitter')->($quote_this);

          $message_out .= $status ? ' and tweeted to @sysarmIRC.' : '';
        }
        sayit($server, $chan, $message_out);
      }
      else {
        sayit($server, $chan, 'cannot do quotes right now.');
        return;
      }
    }
    ##}}}
    #{{{ [QUOTE] random, lastone, search and delete.
    if ('quote' =~ /^${cmd}/ and is_loaded('quotes')) {
      signal_emit('random quotes', $server, $chan);
      return;
    }
    if ('qlast' =~ /^${cmd}/ and is_loaded('quotes')) {
      my $lastquote = 1;
      if ($text ne "!${cmd}") {
        ($lastquote) = $text =~ /^!${cmd}\s+(\d+)?$/ ;
      }
      signal_emit('last quote', $server, $chan, $lastquote);
      return;
    }
    if ('qdelete' =~ /^${cmd}/ and is_loaded('quotes')) {
      my ($delete_this) = $text =~ /^!${cmd}\s+(.*)/;
      if (defined($delete_this)) {
        signal_emit('delete quote', $server, $chan, $delete_this);
      }
      else {
        sayit($server, $chan,
          'I can delete one quote at a time. Just a partial match is enough.'
        );
      }
    }
    if ('qsearch' =~ /^${cmd}/ and is_loaded('quotes')) {
      my ($find_this) = $text =~ /^!${cmd}\s+(.*)/;
      signal_emit('find quote', $server, $chan, $find_this) if ($find_this);
    }
    if ('qtotal' =~ /^${cmd}/ and is_loaded('quotes')) {
      signal_emit('count quotes', $server, $chan);
    }
    #}}}
    #{{{ karma is a bitch
    if ($cmd eq 'karma') {
      my ($thingy) = $text =~ /!karma\s+($karma_thingy)/;
      $thingy = $nick if not defined($thingy);
      if ($thingy eq $server->{nick}) {
        sayit($server, $chan, 'my karma is over 9000 already!');
        return;
      }
      signal_emit("karma check", $server, $chan, $thingy) if is_loaded('karma');
      return;
    }
    #}}}
    #{{{ !setkarma
    if ($cmd eq 'setkarma' and is_sQuEE($mask)) {
      my ($thingy, $newkarma) = $text =~ /^!setkarma\s+(.+)=(.+)$/;
      signal_emit(
        "karma set", $server, $chan, $thingy, $newkarma
      ) if (is_loaded('karma') and $thingy and $newkarma);
      return;
    }#}}}
    #{{{ !rank
    if ($cmd eq 'rank' ) {
      signal_emit("karma rank", $server, $chan) if is_loaded('karma');
    }
    #}}}
    ##{{{ !flipkarma
    if ($cmd eq 'flipkarma' && is_master($mask)) {
      signal_emit('karma flip', $server, $chan) if is_loaded('karma');
    }#}}}
    #{{{ [TWITTER] !mytwitteris
    if ($cmd eq 'mytwitteris') {
      #print (CRAP Dumper($twit_users_ref));
      my ($givenName) = $text =~ /^!mytwitteris\s+(.+)$/;
      unless ($givenName) {
        if (not exists ($twit_users_ref->{$nick})) {
          sayit($server, $chan, "I dunno any twitter handle for $nick. "
                              . "Add yours with !mytwitteris \@yourtwitter."
               );
        }
        else {
          sayit($server, $chan, "I remember $nick is "
                              . "\@$twit_users_ref->{$nick} on twitter");
          return;
        }
      }
      else {
        $givenName =~ s/^\@//;
        $twit_users_ref->{$nick} = $givenName;
        store $twit_users_ref, $twit_users_file;
        sayit($server, $chan, 'okay!') if exists $twit_users_ref->{$nick};
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
          sayit($server, $chan, "I know $givenName is "
                              . "\@$twit_users_ref->{$givenName} on twitter");
          return;
        }
        #check if given is a twitter and has an ircname
        foreach my $ircname (keys %$twit_users_ref) {
          if ($givenName =~ /^$twit_users_ref->{$ircname}$/i) {
            sayit($server, $chan, "I've been told "
                         . "\@$givenName is $ircname here on freenode");
            return;
          }
        }
        sayit($server, $chan, "nope, I dunno any $givenName");
        return;
        #so lazy
      }
      else {
        sayit($server, $chan, "I might know who is who on twitter and irc");
        return;
       }
     }
    #}}}
    #{{{ [TWITTER] !isnolongerhere
    if ($cmd eq 'isnolongerhere' and is_master($mask)) {
      my ($given_name) = $text =~ /^!isnolongerhere\s+(.+)$/;
      if ($given_name) {
        $given_name =~ s/^\@//;
        delete $twit_users_ref->{$given_name};
        if (not exists $twit_users_ref->{$given_name}) {
          store $twit_users_ref, $twit_users_file;
          sayit($server, $chan, 'deleted!');
        }
        return;
      }
    }#}}}
    #{{{ [TWITTER] !user (checkout user on twitter)
    if ($cmd eq 'user') {
      my ($who) = $text =~ /^!user\s+@?(\w+)/;

      signal_emit('teh fuck is who',
                  $server, $chan, $who) if $who and is_loaded('twitter');

      sayit($server, $chan, "!user <twitter_username>") if not defined($who);
      return;
    }#}}}
    #{{{ [TWITTER] !tt post tweet to sysarmy
    if ($cmd eq 'tt' and $chan =~ /sysarmy|ssqquuee/) {
      if ($text eq '!tt') {
        sayit($server, $chan, 'send a tweet to @sysARmIRC');
        return;
      }
      if (is_loaded('sysarmy')) {
        $text =~ s/!tt\s+//;
        foreach (keys %{$twit_users_ref}) {
          $text =~ s/\b\Q$_\E\b/\@$twit_users_ref->{$_}/g;
        }
        my $status
          = scalar('Irssi::Script::sysarmy')->can('send_to_twitter')->($text);

        my $message_out = $status ? 'tweet sent.'
                                  : 'cannot post to twitter right now.';

        sayit($server, $chan, $message_out);
        return;
      }
    } #}}}
    #{{{ !ddg cuac cuac go
    if ($cmd eq 'ddg') {
      my ($query) = $text =~ /^!ddg\s+(.*)$/;
      unless ($query) {
        sayit($server, $chan, 'cuac cuac go!');
        return;
      }
      else {
        signal_emit(
          'cuac cuac go',
          $server,
          $chan,
          $query
        ) if is_loaded('duckduckgo');
      }
    }#}}}
   #{{{ !btc bitcoins
    if ($text =~ m{^!bi?tc(?:oin)?s?\s?(\d+(?:[.,]\d+)?)?$}) {
      my $howmuch = '1';
      $howmuch = $1 if $1;
      $howmuch =~ tr/,/./;
      signal_emit('gold digger', $server, $chan, $howmuch) if is_loaded('coinbase');
    }#}}}
   #{{{ kraken coins
    if ($cmd =~ m{^(?:eth)|(?:xlm)|(?:ltc)|(?:doge)}) {
      my ($howmuch) = $text =~ m{(\d+(?:[.,]\d+)?)};
      $howmuch = '1' if not $howmuch;
      $howmuch =~ tr/,/./;
      signal_emit('kraken released', $server, $chan, $cmd, $howmuch) if is_loaded('kraken');
    }#}}}
    #{{{ !clima
    if ($cmd eq 'clima') {
      my ($city) = $text =~ /^!clima\s+(.*)$/;
      if (is_loaded('clima') and defined($city)) {
        signal_emit('weather', $server, $chan, $city);
      }
      else {
        sayit($server, $chan, "I need a city name.");
      }
    } #}}}
    #{{{ wolfram alpha !wa
    if ($cmd eq 'wa') {
      my ($query) = $text =~ /^!wa\s+(.*)$/;
      if (is_loaded('wolfram') and defined($query)) {
        signal_emit('wolfram', $server, $chan, $query);
      }
      else {
        sayit($server, $chan, 'I can pass on any question to this dude.');
      }
    } #}}}
    #{{{ !bofh
    if ($cmd eq 'bofh') {
      signal_emit('bofh', $server, $chan) if (is_loaded('bofh'));
    } #}}}
    ##{{{ !bash bash.org quotes
    if ($cmd =~ m{^bash\b}) {
      signal_emit('bash quotes', $server,$chan, $text) if is_loaded('bash');
    }
    ##}}}
    ##{{{ !subte
    if ($cmd eq 'subte') {
      my ($linea) = $text =~ m{^!subte\s+([abcdehpABCDEHP])$};
      sayit($server, $chan, "que linea?") unless ($linea);
      signal_emit('hay subte', $server, $chan, uc($linea)) if ($linea);
    }
    ##}}}
    #{{{ novelty (?) !shrug !wot !dunno !caca !flip
    if ($cmd =~ /^(?:shrug|dunno|wot|caca)$/) {
      my ($reason) = $text =~ m{^!\w+\s+(.+)$};

      if (defined $reason) {
        my $answer = decode('utf8', $reason) . ' ' . $faces{$cmd};
        sayit($server, $chan, encode('utf8', $answer));
      }
      else {
        sayit($server, $chan, $faces{$cmd});
      }
    }
    if ($cmd =~ /^flip$/i) {
      my ($flipme) = $text =~ m{^!flip\s+(.*)$}i;
      if ( defined $flipme and $flipme ne 'DEM TABLES') {
        $flipme = decode('utf8', $flipme);
        my $flipped
          = scalar('Irssi::Script::flipme')->can('flip_text')->($flipme)
            if is_loaded('flipme');

        sayit($server, $chan, encode('utf8', '(╯°□°）╯︵ ' . $flipped)) if $flipped;
        return;
      }
      else {
        if (settings_get_str('flip_table_status') == 0) {
          sayit($server, $chan, '(╯°□°）╯︵ ┻━┻');
          settings_set_str('flip_table_status', '1');
        }
        else {
          sayit($server, $chan, '┬─┬ノ( º _ ºノ)');
          settings_set_str('flip_table_status', '0');
        }
      }
    }
    #}}}
    #{{{ !excusas
    if ($cmd eq 'excusa') {
      signal_emit('excusa get', $server, $chan) if is_loaded('excusarmy')
    }
    if ($cmd eq 'addexcusa' and $chan =~ /sysarmy(?:-en)?|ssqquuee/) {
      my ($excusa) = $text =~ m{!addexcusa\s+(.*)$};
      if (not $excusa) {
        sayit($server, $chan, 'contribute a new excusa for the excusarmy app!');
      }
      else {
        signal_emit('excusa add', $server, $chan, $excusa)
          if ($excusa and is_loaded('excusarmy'));
      }
    }
    ##}}}
    #{{{ !birras
    if ($cmd =~ /^(?:admin)?birras?$/ and $chan =~ /sysarmy(?:-en)?|ssqquuee/) {
      sayit($server, $chan, "not sure. check https://www.meetup.com/sysarmy/");
      #signal_emit('birras get', $server, $chan) if is_loaded('adminbirras');
      return;
    }
    ##}}}
    #{{{ !settopic
    if ($cmd eq 'settopic' and is_sQuEE($mask)) {
      my ($new_topic) = $text =~ /^!settopic +(.*)$/;
      $server->send_message('chanserv', "topic $chan $new_topic", 0);
    }
    ##}}}
    #{{{ !corona
    if ($cmd =~ m{^covid}) {
      my ($country) = $text=~ m{^!covid(?:virus)?\s+?(\w{2})?};
      $country = 'AR' if not $country;
      signal_emit('coronavirus', $server, $chan, $country) if is_loaded('corona');
    }
    #}}}
    #{{{ !feriados
    if ($cmd =~ m{^feriados?}) {
      signal_emit('worknowork', $server, $chan) if is_loaded('feriados');
    }
    #}}}
    #{{{ !discord
    if ($cmd eq 'discord' and $chan eq '#sysarmy') {
        sayit($server, $chan, 'Discord: https://sysar.my/discord');
    }
    #{{{ !slack
    if ($cmd eq 'slack' and $chan eq '#sysarmy') {
        sayit($server, $chan, 'Slack: https://sysar.my/slack');
    }
    #}}}
  } #public cmd check ends here. begin general URL match

################################################################################
  #
  #{{{ GENERAL URL MATCH
  if ($text =~ m{(https?://[^ ]+)}) {
    my $url = $1;
    return if ($url =~ /wikipedia|facebook|fbcdn|app.slack/i);
    #site specific stuff
    if ($url =~ m{https?://www\.imdb\.com/title/(tt\d+)}) {
      signal_emit('search imdb', $server, $chan, $1) if ($1 and is_loaded('imdb'));
      return;
    }
    #youtube here
    if ($url =~ /$youtubex/) {
      signal_emit('check tubes', $server, $chan, $1) if (is_loaded('youtube'));
      return;
    }
    #show twitter user bio info from an url
    if ($url =~ m{twitter\.com/(\w+)$}) {
      signal_emit('teh fuck is who',
                  $server, $chan, $1) if ($1 and is_loaded('twitter'));
      return;
    }
    #twitter status fetch
    if ($url =~ m{twitter\.com(?:/\#!)?/[^/]+/status(?:es)?/\d+}) {
      signal_emit('fetch tweet',
                  $server, $chan, $url) if (is_loaded('twitter'));
      return;
    }
    if ($url =~ m{mercadolibre\.com\.ar/MLA-(\d+)}) {
      my $mla = 'MLA' . $1;
      signal_emit('mercadolibre', $server, $chan, $mla);
      return;
    }
    #imgur api?
    if ($url =~ m{https?://i\.imgur\.com/(\w{5,8})h?\.[pjgb]\w{2,}$}) {
      #h is there for hires
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
  } #}}} URL MATCH ENDS HERE. lo que sigue seria general text match.

  #{{{ do stuff with anything that is not a cmd or a http link
  #
  ## karma check against the text
  ## too much abuse of this.
#  my @karmacheck = $text =~ /$karmagex/g;
#  if (scalar(@karmacheck) > 0) {
#    foreach (@karmacheck) {
#      my ($thingy, $op) = ( /^(.+)([+-]{2})$/ );
#      next if ($thingy eq $nick);
#      $thingy .= $server->{tag};
#      signal_emit('karma bitch', $thingy, $op) if (is_loaded('karma'));
#    }
 ## KARMA KARMA AND KARMA++
  if ($text =~ /$karmagex/) {
    #fancy karma throttling mechanism.
    return if (time - $karma_lasttime < $karma_antiflood_time);

    my $thingy   = $1;
    my $operator = $2;

    # check for self karma and apply penalty
    $operator = '--' if ($thingy eq $nick);

    # replace me with $nick if selft decrementing karma
    $thingy = $nick if ($thingy eq 'me' and $operator eq '--');

    #karma scope is per channel
    my $channel = $chan . '_libera';
    #my $channel = $chan . '_' . $server->{tag};

    signal_emit('karma bitch', $thingy, $operator, $channel)
      if (is_loaded('karma') and $thingy and $operator);

    $karma_lasttime = time;
  }
} #incoming puiblic message ends here #}}}

################################################################################
#{{{ helper subroutines
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
sub is_sQuEE {
  #my $mask = shift;
  return (shift(@_) eq '~sQuEE@user/squee') ? 'true' : undef;
}
sub is_loaded { return exists($Irssi::Script::{shift(@_).'::'}); }
sub sayit     { my $s = shift; $s->command("MSG @_"); }

signal_add("message public", "incoming_public");
