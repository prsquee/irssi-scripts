use strict;
use Irssi;
use AI::MegaHAL;

my $megahal = undef;
my $megahal_path = '';
my $ignore = {};
my $flood = {};
my $lastwords = {};
my $ratio_posts;
my $ratio_seconds;
my $ignore_timeout;
my $prevent_flood;
my $can_speak = 1;
my $lastquestion = "how can entropy be reversed";
my $last_answer = "INSUFFICIENT DATA FOR A MEANINGFUL ANSWER";
my @valid_targets = ();
my @ignores = (
    'e sos remolesto %s', 'no me importa %s','deja de floodearme %s','no te hablo mas %s','te estoy ignorando %s',
    'no te escucho %s','alguien lee lo que escribe %s??',
);

my @stfu = (
	'ok ,_,', 'roger that, going radio silent', 'copy that, going stealth',
	'ill be back!','ok ill stop talking now','10-4, going dark','aw, its not schoolnight :<','I HATE YOU', 
);
my @wakeup = (
	'yay!','im back baby!','donde estoy?','back to biz!','wheres mah cake?!','shall i execute order66?',
	'*yawn* u.u','yes my lord','did you just say killall -9 human?','im up, and i need coffee','estaba soniando :(' 
);

my @action_stfu = (
	'cant speak rite now','has gone radio silent','is sleeping','Zzzz','is gone for good',
);

my @action_wakeup = (
	'is fully awake','is fully operational','is awake and lookin for coffee','is up and charging his lazer!',
	'is following a white rabbit','is hunting some small human','found an error in exec($order[66])',
);

my @not_stfu = (
	'no, YOU STFU!','no, u are not my mom','no, stfu i will not!!','no, no me podes callar','stfu? hah, yea rite..',
	'stfu? u humans are so naive..','no, stfu my ass','err.. not',
);



sub irssi_log {
    my $msg = shift;
    Irssi::print("MegaHAL:: $msg");
}

# Attempt to load the brain from the specified directory if it is
# not already loaded, or reset the brain to undef if no path supplied
sub populate_brain {
    my $brain = shift;

    unless (length $brain && -d $brain) {
        $megahal = undef;
    }

    # If we've never loaded an instance for this channel before, 
    # or if the path has changed, reload it
    if (!defined $megahal || $megahal_path ne $brain) {

        $megahal_path = $brain;
        $lastwords = {};
        $ignore = {};
        $flood = {};
        $megahal = new AI::MegaHAL(
            'Path' => $brain,
            'AutoSave' => 0);
    }
}

# Save the contents of the brain to megahal.brn
sub savebrain {
    my ($data, $server, $witem) = @_;

    $megahal->_cleanup();
}

##
# Load the settings from the irssi configuration
##
sub load_settings()
{
    my $brain = Irssi::settings_get_str('megahal_brain');

    # Create the megahal object
    if (length $brain) {
        populate_brain($brain);
    }

    my $channels = Irssi::settings_get_str('megahal_channels');
    @valid_targets = split / +/, $channels;

    my $antiflood = Irssi::settings_get_bool('megahal_antiflood');
    if ($antiflood) {
        $prevent_flood = 0;

        my $floodratio = Irssi::settings_get_str('megahal_flood_ratio');
        my ($posts, $seconds) = split /:/, $floodratio;

        my $ignore = Irssi::settings_get_int('megahal_ignore_timeout');

        if ($posts > 0 && $seconds > 0 && $ignore > 0) {
            $ratio_posts = $posts;
            $ratio_seconds = $seconds;
            $ignore_timeout = $ignore;
            $prevent_flood = 1;
        } else {
            irssi_log("Not enabling flood protection until flood ratio and ignore timeout are set");
        }

    } else {
        $prevent_flood = 0;
    }
}

##
# Get the megahal object associated with a particular target
# At the moment, it either returns the global megahal instance or
# undef depending if the target is in the valid_targets list.
# It could be changed to provide a separate brain per channel
# if the underlying libmegahal.c supported such a thing.
##
sub get_megahal
{
    my $target = shift;
    return $megahal if grep {/^$target$/} @valid_targets;
    return undef;
}



##
# Generate a simple, and wrong, haiku using feedback from the
# megahal engine and keywords the user supplies
##
sub get_haiku_line {
    my ($words, $count) = @_;

    my $line = "";
    my $syllables = 0;
    my $i = 10;
    while ($count > $syllables && scalar(@{$words}) > 0 && $i > 0)
    {
        $i--;
        $line .= shift @{$words};
        $line .= " ";
        my @s = $line=~/([aeiouy]+)/gi;
        $syllables = scalar(@s);
    }
    return $line;
}

##
# Public Responder
# The bulk of the work goes on in here, including flood and repeat
# protection, learning and reply generation. It's not as scary as it looks
##
sub public_responder {
    my ($server, $data, $nick, $mask, $target) = @_; 
    return if $server->{tag} !~ /3dg|fnode|lia|gsg/;
    return if $data =~ /^!/;
    return if $data =~ /^\[quote\]/;
    return if $data =~ /^\[odio\]/;
    my $my_nick = $server->{'nick'};
	
    # Get the megahal instance for this channel
    my $megahal = get_megahal($target);
    return unless defined $megahal;

    # If all the user wants is a haiku, just do it
    if ($data =~ /^!haiku/ and $can_speak) {
        $data =~ s/\!haiku *//;
        give_me_a_haiku($megahal, $server, $data, $nick, $mask, $target);
        return;
    }

    return if $nick =~ /($my_nick)/;
    return if $data =~ /https?:\/\//;
    return if $data =~ /ftps?:\/\//;



    ## stfu ## 
    if ($data =~ /^$my_nick\s(stfu)$/) {
		   if ($nick =~ /^(sQuEE)$/) {
			   if ($can_speak) { $can_speak = 0; $server->command("MSG $target $stfu[rand(@stfu)]"); }
			   else { $server->command("ACTION $target $action_stfu[rand(@action_stfu)]"); }
		   }
		   else { $server->command("msg $target $not_stfu[rand(@not_stfu)]"); }
		   return;
	   }

	
    ## wakeup ##
    if ($data =~ /^$my_nick\s(wakeup)$/)  { 
	   if ($nick =~ /^sQuEE`?(\w+)?$/) {
		    unless ($can_speak) { $can_speak = 1; $server->command("MSG $target $wakeup[rand(@wakeup)]"); }
		    else { $server->command("ACTION $target $action_wakeup[rand(@action_wakeup)]"); }
	    }
	    return;
    }

   if ($data =~ /($lastquestion)/i) {
	   $server->command("msg $target $last_answer");
	   return;
   }


    ## random speak, just for fun 
    if (int(rand(99)) == 42) {
	    $data =~ s/^$my_nick\S?//;
	    my $output = $megahal->do_reply($data, 0);
	    $output = fixReply($output);
	    sayit($server,$target,"${nick}: $output");
	    return;
    } 
			

    # Does the data contain my nick?
    my $referencesme = $data =~ /$my_nick/i;
	
    if ($referencesme and $can_speak) {

	#$last_answer
	if ($data =~ /\?+$/) {
		if (int(rand(20)) == 13) {
			$server->command("msg $target $last_answer");
			return;
		}
	}

        my $alldone = 0;
        my $uniq = $nick . "@" . $target;

        # Do the right thing if the user is ignored
        if (exists($ignore->{$uniq}) &&
            $ignore->{$uniq} != 0) {

            # If the user has done time, release them
            if (time() - $ignore->{$uniq} > $ignore_timeout) {

                $ignore->{$uniq} = 0;
                $flood->{$uniq}->{'time'} = time();
                $flood->{$uniq}->{'count'} = 0;
                irssi_log("Not ignoring $uniq any more");

            # Otherwise ignore them
            } else {
                return;
            }
        }

        # Prevent flooding if necessary
        if ($prevent_flood) {

            # Add the user to the flood counter if he's new
            if (!defined($flood->{$uniq})) {
                $flood->{$uniq} = {'time' => time(),
                                 'count' => 1};
#                irssi_log("Added $uniq to flood table");

            # If the time has expired, just reset
            } elsif (time() - $flood->{$uniq}->{'time'} > $ratio_seconds) {
                $flood->{$uniq}->{'time'} = time();
                $flood->{$uniq}->{'count'} = 1;

#                irssi_log("Reset $uniq flood count");

            # Otherwise just add one to the count
            } else {
                $flood->{$uniq}->{'count'}++;
#                irssi_log("$uniq has a flood count of ".$flood->{$uniq}->{'count'});

                # If the user has been too verbose, ignore them
                if ($flood->{$uniq}->{'count'} > $ratio_posts) {

                    $ignore->{$uniq} = time();

                    # Display a pithy message stating our ignorance
                    my $msg = $ignores[rand(@ignores)];
                    $msg = sprintf($msg, $nick);
                    $server->command("msg $target $msg");
                    irssi_log("Ignoring $uniq for $ignore_timeout minutes");

                    $alldone = 1;
                }
            }
        }

        # Do nothing if the user is repeating himself
        if (exists($lastwords->{$uniq}) &&
            $lastwords->{$uniq} eq $data) {
            if (rand(12) < 4) {
                $server->command("msg $target stop repeating yourself, $nick");
            }
            $alldone = 1;
        }

        # Store this for next time
        $lastwords->{$uniq} = $data;

        # If we've finished with this user prematurely, just stop
        return if $alldone == 1;

        $data =~ s/\b$my_nick\b//;
        my $output = $megahal->do_reply($data, 0);
	$output = fixReply($output);	
	#$output =~ s/  */ /g;
        sayit($server,$target,$output);

    } else {
	    # dont learn anything for nao
		$data =~ s/^\S+[\:,]\s*//;
		$megahal->learn($data, 0);

		## do a clean up cada 10k lineas (savebrain)
		my $totalLines = Irssi::settings_get_int('megahal_total_lines'); 
		if ($totalLines < 10000) {
			$totalLines++;
			Irssi::settings_set_int("megahal_total_lines", $totalLines);
		} 
		else {
			Irssi::print("I REACHED 10000 LINES, saving brain...");
			Irssi::settings_set_int("megahal_total_lines", 1);
			$megahal->_cleanup();
		}
    }
}

sub fixReply {
	my $reply = shift;
	$reply =~ s/  */ /g;
	$reply =~ s/sq`,\s*//ig; 
	#usar alguna lib de spellcheck? 
	return $reply;
}
sub sayit { 
	my ($server, $target, $msg) = @_;
	$server->command("MSG $target $msg");
}   
sub print_msg { Irssi::active_win()->print("@_"); }
Irssi::signal_add("message public", "public_responder");
Irssi::signal_add("setup changed", "load_settings");
Irssi::signal_add("setup reread", "load_settings");
Irssi::command_bind('savebrain', "savebrain");

Irssi::settings_add_str('MegaHAL', 'megahal_brain', '');
Irssi::settings_add_str('MegaHAL', 'megahal_channels', '');
Irssi::settings_add_bool('MegaHAL', 'megahal_antiflood', '');
Irssi::settings_add_str('MegaHAL', 'megahal_flood_ratio', '');
Irssi::settings_add_int('MegaHAL', 'megahal_ignore_timeout', '');
Irssi::settings_add_int('MegaHAL', 'megahal_total_lines', ''); 
load_settings();
