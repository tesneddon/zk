$ ! Procedure:	ZKSTATUS.COM
$ __vfy = "VFY_''f$parse(f$environment("procedure"),,,"name")'"
$ if (f$type('__vfy') .eqs. "") then __vfy = 0
$ __vfy_saved = f$verify(&__vfy)
$
$err: subroutine
$ set noon
$ severity = f$edit(P1,"COLLAPSE,UPCASE")
$ identification = f$edit(P2,"COLLAPSE,UPCASE")
$ text = f$edit(P3,"TRIM")
$ continuation = (f$edit(P4,"COLLAPSE,UPCASE") .nes. "")
$ say = "write sys$output"
$ percent = "%"
$ if (continuation) then percent = "-"
$ if ((severity .eqs. "") .or. (identification .eqs. "") .or. (text .eqs. ""))
$ then say "%''facility'-F-SPOTTHEERR, <''severity'><''identification'><''text'>"
$ else say "''percent'''facility'-''severity'-''identification', ''text'"
$ endif
$ exitt 1
$ endsubroutine
$
$ procedure = f$element(0,";",f$environment("PROCEDURE"))
$ facility = f$parse(procedure,,,"NAME")
$
$ set noon
$ set symbol/scope=(nolocal)
$ on control_y then goto bail_out
$
$ say = "write sys$output"
$ err = "call___ err"
$ batch = (f$mode() .eqs. "BATCH")
$ mailmsg = "SYS$SCRATCH:''facility'_''f$getjpi("","PID")'.MAIL"
$ logfile = "SYS$LOGIN:''facility'.LOG"
$ statefile = "SYS$LOGIN:''facility'.STATE"
$ known = "|interval|queue|mailto|dir|web|web_path|asterisk|ami_user|ami_secret|zkphone_service|"
$
$ ! Only the last few logs are kept: a run every minute would otherwise
$ ! leave over a thousand a day.
$ if (batch) then purge/nolog/keep=10 'logfile'
$
$ ! The configuration file: P1, or ZK$STATUS_CONFIG.  It is found again by
$ ! its full name, which is what the next job is given.
$ if (p1 .eqs. "") then p1 = f$trnlnm("ZK$STATUS_CONFIG")
$ if (p1 .eqs. "")
$ then
$   err E NOCONFIG "no configuration file given, and ZK$STATUS_CONFIG is not defined"
$   goto bail_out
$ endif
$ config = f$search(p1)
$ if (config .eqs. "")
$ then
$   err E FNF "''p1' not found"
$   goto bail_out
$ endif
$ config = f$element(0,";",config)
$
$ ! Read the keys DCL needs.  The Perl below reads the whole file itself;
$ ! both reject a key they do not know.  A ! starts a comment.
$ cfg_interval = "5"
$ cfg_queue = "SYS$BATCH"
$ cfg_mailto = ""
$ cfg_dir = ""
$ lineno = 0
$ open/read/error=err_open cfg 'config'
$cfg_loop:
$ read/end_of_file=cfg_done/error=err_read cfg line
$ lineno = lineno + 1
$ line = f$edit(f$element(0,"!",line),"TRIM")
$ if (line .eqs. "") then goto cfg_loop
$ eq = f$locate("=",line)
$ if (eq .eq. f$length(line)) then goto err_syntax
$ key = f$edit(f$extract(0,eq,line),"COLLAPSE,LOWERCASE")
$ value = f$edit(f$extract(eq+1,f$length(line)-eq-1,line),"TRIM")
$ if ((key .eqs. "") .or. (f$locate("|''key'|",known) .eq. f$length(known))) -
	then goto err_key
$ if ((key .eqs. "interval") .or. (key .eqs. "queue") .or. -
      (key .eqs. "mailto") .or. (key .eqs. "dir")) then cfg_'key' = value
$ goto cfg_loop
$cfg_done:
$ close cfg
$
$ if ((f$type(cfg_interval) .nes. "INTEGER") .or. (f$integer(cfg_interval) .lt. 1))
$ then
$   err E INTERVAL "interval ""''cfg_interval'"" is not a whole number of minutes"
$   goto bail_out
$ endif
$ interval = f$integer(cfg_interval)
$
$ ! Queue the next run before this one does any work, so that a check
$ ! that fails or hangs does not end the cycle.  Run interactively, it
$ ! checks once and does not queue anything.
$ if (batch)
$ then
$   hours = interval / 60
$   minutes = interval - (hours * 60)
$   submit/noprint/queue='cfg_queue'/name='facility'/log='logfile' -
	/after="+''hours':''minutes'"/parameters=("''config'") 'procedure'
$   if (.not. $status) then -
	err W NOSUBMIT "the next run could not be queued; this is the last"
$ endif
$
$ ! The checks, the status page, and a message if anything changed
$ if (f$search(mailmsg) .nes. "") then delete/nolog 'mailmsg';*
$ perl -x 'procedure' "''config'" "''mailmsg'" "''statefile'"
$ if (.not. $status) then err W CHECKFAIL "the checks did not finish"
$
$ ! Each run writes a new page, and the state when it changes
$ page = cfg_dir + "STATUS.HTML"
$ if (f$search(page) .nes. "") then purge/nolog/keep=2 'page'
$ if (f$search(statefile) .nes. "") then purge/nolog/keep=2 'statefile'
$
$ if ((f$search(mailmsg) .nes. "") .and. (cfg_mailto .nes. ""))
$ then
$   i = 0
$mail_loop:
$   addr = f$edit(f$element(i,",",cfg_mailto),"TRIM")
$   if (addr .eqs. ",") then goto mail_done
$   i = i + 1
$   if (addr .eqs. "") then goto mail_loop
$   mail/noself/subject="Halls of ZK status change" 'mailmsg' "SMTP%""''addr'"""
$   if (.not. $status) then err W NOMAIL "unable to mail ''addr'"
$   goto mail_loop
$mail_done:
$ endif
$ goto bail_out
$
$err_open:
$ err E OPEN "unable to open ''config'"
$ say "-" + f$message($status) - "%"
$ goto bail_out
$
$err_read:
$ err E READ "unable to read ''config'"
$ say "-" + f$message($status) - "%"
$ goto bail_out
$
$err_syntax:
$ err E SYNTAX "''config' line ''lineno': expected key = value"
$ goto bail_out
$
$err_key:
$ err E BADKEY "''config' line ''lineno': unknown key ""''key'"""
$ goto bail_out
$
$bail_out:
$ close/nolog cfg
$ if (f$type(mailmsg) .nes. "") then -
$     if (f$search(mailmsg) .nes. "") then delete/nolog 'mailmsg';*
$ exitt 1.or.(0*f$verify(__vfy_saved))
$ !+==========================================================================
$ !
$ ! Procedure:	ZKSTATUS.COM
$ !
$ ! Purpose:	Check that The Halls of ZK can be played, on the web and by
$ !		telephone; write a status page of badges for the website to
$ !		show in a frame; and mail someone when a check changes from
$ !		passing to failing, or back.
$ !
$ !		Submitted to batch, it queues itself to run again every
$ !		interval minutes before doing anything else.  Run with @, it
$ !		checks once.
$ !
$ ! Parameters:	P1	The configuration file; the logical ZK$STATUS_CONFIG
$ !			if not given.  See ZKSTATUS.INI.  It holds the AMI
$ !			secret, so protect it (W:) from the world.
$ !
$ ! Requires:	Perl (5.6.2 or later) defined as the foreign command PERL.
$ !		The checks are written in Perl, below, and run with
$ !		PERL -X, which skips everything before the #!perl line.
$ !
$ ! Files:	dir:STATUS.HTML		the badges, for an <iframe>
$ !		SYS$LOGIN:ZKSTATUS.STATE	each check's last result; mail
$ !					is sent only when one changes
$ !		SYS$LOGIN:ZKSTATUS.LOG	the batch log, last 10 kept
$ !
$ ! History:
$ !		19-NOV-2026, TES; Version V1-001
$ !	001 -	Original version.
$ !-==========================================================================
#!perl
#
# The checks.  Run by ZKSTATUS.COM as
#
#	perl -x ZKSTATUS.COM config-file mail-file state-file
#
# Each check gives a result of up or down, with a line saying what it
# found.  The results go into the status page; any that differ from the
# state file are written to the mail file, for the DCL to send, and the
# state file is written anew.  With no state file (the first run) nothing
# is mailed.
#
# Written for Perl 5.6.2: only IO::Socket and IO::Select, which it has.
#
use strict;
use warnings;
use IO::Socket;
use IO::Select;

my $facility = 'ZKSTATUS';
my $timeout  = 10;			# seconds, to connect and to answer
my %pending;				# read from each socket, not yet returned
my %known = map { $_ => 1 }
    qw(interval queue mailto dir web web_path asterisk ami_user ami_secret
       zkphone_service);

# Time::HiRes is not part of 5.6.2; without it times are whole seconds
my $hires = eval { require Time::HiRes; 1 };
sub now { return $hires ? Time::HiRes::time() : time() }
sub took {
    my ($start) = @_;
    my $t = now() - $start;
    return $hires ? sprintf("%.1fs", $t) : sprintf("%ds", $t);
}

my ($config, $mailfile, $statefile) = @ARGV;
die "%$facility-F-USAGE, perl -x ZKSTATUS.COM config-file mail-file state-file\n"
    unless defined $statefile;

my %cfg = read_config($config);
die "%$facility-F-NODIR, no dir in $config: where does STATUS.HTML go?\n"
    unless defined $cfg{dir} && $cfg{dir} ne '';
my $interval = $cfg{interval} || 5;
my $checked  = vms_time(time());

my @results;
push @results, check_web(\%cfg) if set($cfg{web});
push @results, check_trunk(\%cfg) if set($cfg{asterisk});
push @results, check_zkphone() if set($cfg{zkphone_service})
                                   && $cfg{zkphone_service} =~ /^(y|yes|true|1)$/i;
foreach my $r (@results) {
    print "%$facility-I-\U$r->{name}\E, $r->{label} is $r->{status}: $r->{detail}\n";
}

write_page(page_file($cfg{dir}), \@results);

my %was = read_state($statefile);
my @changes;
foreach my $r (@results) {
    my $old = $was{$r->{name}};
    next unless defined $old && $old ne $r->{status};
    push @changes, $r->{status} eq 'up'
        ? "$r->{label} is UP again: $r->{detail}"
        : "$r->{label} is DOWN: $r->{detail}";
}
if (@changes) {
    open(my $fh, ">$mailfile") or die "%$facility-F-MAIL, unable to write $mailfile: $!\n";
    print $fh "$_\n" foreach @changes;
    print $fh "\nChecked $checked by ZKSTATUS.\n";
    close $fh;
    print "%$facility-I-CHANGED, $_\n" foreach @changes;
}
my $state_changed = 0;
foreach my $r (@results) {
    my $old = $was{$r->{name}};
    $state_changed = 1 unless defined $old && $old eq $r->{status};
}
write_state($statefile, \@results) if $state_changed;
exit 0;

#
# Checks.  Each returns { name, label, badge, status (up/down), detail }.
# name is the key in the state file; label names it in the log and the
# mail; results with the same badge share one badge on the page.
#

# The website: a GET of web_path, answered with 2xx or 3xx.  A redirect
# (to HTTPS, say) still shows the server is up.
sub check_web {
    my ($c) = @_;
    my ($host, $port) = host_port($c->{web}, 80);
    my $path = set($c->{web_path}) ? $c->{web_path} : '/dclinabox/-/dclinabox.html';
    my %r = (name => 'web', label => $host, badge => $host);
    my $start = now();

    my ($sock, $why) = connect_to($host, $port);
    return { %r, status => 'down', detail => $why } unless $sock;
    my $line;
    if (send_text($sock, "GET $path HTTP/1.0\r\nHost: $host\r\n"
                       . "User-Agent: ZKSTATUS\r\nConnection: close\r\n\r\n")) {
        $line = read_line($sock, $start + $timeout);
    }
    close_sock($sock);
    return { %r, status => 'down', detail => "no answer within ${timeout}s" }
        unless defined $line;
    my ($code) = $line =~ m{^HTTP/\d+\.\d+\s+(\d{3})};
    return { %r, status => 'down', detail => "not an HTTP answer" }
        unless defined $code;
    return { %r, status => ($code =~ /^[23]/ ? 'up' : 'down'),
             detail => "HTTP $code in " . took($start) };
}

# The phone trunk: log in to the Asterisk manager (AMI) and ask for the
# outbound registrations.  Up if there is at least one and every one is
# Registered.  It also shows that Asterisk itself is running.
sub check_trunk {
    my ($c) = @_;
    my ($host, $port) = host_port($c->{asterisk}, 5038);
    my %r = (name => 'trunk', label => 'phone trunk', badge => 'phone');
    my $start = now();
    my $deadline = $start + $timeout;
    my $user = set($c->{ami_user}) ? $c->{ami_user} : 'zkstatus';
    my $secret = defined $c->{ami_secret} ? $c->{ami_secret} : '';

    my ($sock, $why) = connect_to($host, $port);
    return { %r, status => 'down', detail => $why } unless $sock;
    my $result = eval {
        my $banner = read_line($sock, $deadline);
        die "no answer from Asterisk within ${timeout}s\n" unless defined $banner;
        die "not the Asterisk manager on $host:$port\n"
            unless $banner =~ /^Asterisk Call Manager/;

        ami_send($sock, Action => 'Login', Username => $user, Secret => $secret,
                 Events => 'off', ActionID => 'zks-login');
        my $m = ami_response($sock, $deadline, 'zks-login');
        die "login as $user refused: " . ($m->{message} || 'no reason given') . "\n"
            unless lc($m->{response} || '') eq 'success';

        ami_send($sock, Action => 'PJSIPShowRegistrationsOutbound', ActionID => 'zks-reg');
        $m = ami_response($sock, $deadline, 'zks-reg');
        die "registrations refused: " . ($m->{message} || 'no reason given') . "\n"
            unless lc($m->{response} || '') eq 'success';
        my (@ok, @bad);
        while (1) {
            $m = ami_block($sock, $deadline);
            die "the list of registrations stopped short\n" unless $m;
            next unless ($m->{actionid} || '') eq 'zks-reg';
            my $event = $m->{event} || '';
            last if $event eq 'OutboundRegistrationDetailComplete';
            next unless $event eq 'OutboundRegistrationDetail';
            my $name = $m->{objectname} || '?';
            my $status = $m->{status} || 'Unregistered';
            if ($status eq 'Registered') { push @ok, $name }
            else { push @bad, "$name $status" }
        }
        ami_send($sock, Action => 'Logoff');
        die "no outbound registrations\n" unless @ok || @bad;
        die join(', ', @bad) . "\n" if @bad;
        +{ %r, status => 'up', detail => join(', ', @ok) . " registered, in " . took($start) };
    };
    close_sock($sock);
    return $result if $result;
    (my $err = $@) =~ s/\n$//;
    return { %r, status => 'down', detail => $err };
}

# The ZKPHONE service, which takes the calls from Asterisk.  This only
# works on the node that runs it.
sub check_zkphone {
    my %r = (name => 'zkphone', label => 'ZKPHONE service', badge => 'phone');
    return { %r, status => 'down', detail => 'can only be checked on VMS' }
        unless $^O eq 'VMS';
    my @out = `TCPIP SHOW SERVICE ZKPHONE`;
    foreach (@out) {
        return { %r, status => 'up', detail => 'enabled' }
            if /^ZKPHONE\s.*\bEnabled\b/i;
        return { %r, status => 'down', detail => 'disabled' }
            if /^ZKPHONE\s.*\bDisabled\b/i;
    }
    my ($first) = grep { /\S/ } @out;
    $first = 'no output from TCPIP SHOW SERVICE' unless defined $first;
    $first =~ s/\s+$//;
    return { %r, status => 'down', detail => $first };
}

#
# Helpers
#

sub set { return defined $_[0] && $_[0] ne '' }

# host[:port]
sub host_port {
    my ($spec, $default) = @_;
    my ($host, $port) = split /:/, $spec, 2;
    $port = $default unless defined $port && $port =~ /^\d+$/;
    return ($host, $port);
}

# A socket, or undef and why not
sub connect_to {
    my ($host, $port) = @_;
    my $sock = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $port,
                                     Proto => 'tcp', Timeout => $timeout);
    return ($sock) if $sock;
    my $why = $@ || "$!";
    $why =~ s/^IO::Socket::INET:\s*//;
    $why =~ s/^connect:\s*//;
    return (undef, "no connection to $host:$port ($why)");
}

sub send_text {
    my ($sock, $text) = @_;
    return defined syswrite($sock, $text);
}

# One line from a socket, or undef if it does not come by $deadline
sub read_line {
    my ($sock, $deadline) = @_;
    my $key = fileno($sock);
    $pending{$key} = '' unless defined $pending{$key};
    my $sel = IO::Select->new($sock);
    while ($pending{$key} !~ /\n/) {
        my $left = $deadline - now();
        return undef if $left <= 0 || !$sel->can_read($left);
        my $n = sysread($sock, $pending{$key}, 512, length $pending{$key});
        last unless $n;
    }
    my $line;
    if ($pending{$key} =~ s/^([^\n]*)\n//) {
        $line = $1;
    } else {
        return undef if $pending{$key} eq '';
        ($line, $pending{$key}) = ($pending{$key}, '');
    }
    $line =~ s/\r$//;
    return $line;
}

sub close_sock {
    my ($sock) = @_;
    delete $pending{fileno($sock)};
    close $sock;
}

# AMI: a message is Key: Value lines and a blank line
sub ami_send {
    my ($sock, @kv) = @_;
    my $text = '';
    while (@kv) { my $k = shift @kv; my $v = shift @kv; $text .= "$k: $v\r\n" }
    send_text($sock, "$text\r\n") or die "unable to send to Asterisk ($!)\n";
}

# The next message, with its keys in lower case; undef if none comes
sub ami_block {
    my ($sock, $deadline) = @_;
    my %m;
    while (1) {
        my $line = read_line($sock, $deadline);
        return undef unless defined $line;
        if ($line eq '') {
            return \%m if %m;
            next;
        }
        $m{lc $1} = $2 if $line =~ /^([^:]+):\s?(.*)$/;
    }
}

# The response to the action with this ActionID, skipping anything else
sub ami_response {
    my ($sock, $deadline, $id) = @_;
    while (1) {
        my $m = ami_block($sock, $deadline);
        die "no answer from Asterisk within ${timeout}s\n" unless $m;
        return $m if defined $m->{response} && ($m->{actionid} || '') eq $id;
    }
}

# A VMS directory (ends in ] > or :) takes the name as it is; anything
# else is taken as a Unix one, for trying this away from VMS.
sub page_file {
    my ($dir) = @_;
    return $dir =~ /[\]>:]$/ ? "${dir}STATUS.HTML" : "$dir/status.html";
}

sub vms_time {
    my @t = localtime(shift);
    my @mon = qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC);
    return sprintf("%2d-%s-%04d %02d:%02d", $t[3], $mon[$t[4]], $t[5] + 1900,
                   $t[2], $t[1]);
}

sub html {
    my ($s) = @_;
    $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/"/&quot;/g;
    return $s;
}

# Badges in the style of shields.io, as plain HTML and CSS.  A badge is
# up only if every result on it is; its tooltip gives each one.
sub write_page {
    my ($file, $results) = @_;
    my $refresh = $interval * 60;
    my (@order, %on);
    foreach my $r (@$results) {
        push @order, $r->{badge} unless $on{$r->{badge}};
        push @{$on{$r->{badge}}}, $r;
    }
    my $badges = '';
    foreach my $b (@order) {
        my @parts = @{$on{$b}};
        my $status = (grep { $_->{status} ne 'up' } @parts) ? 'down' : 'up';
        my $what = @parts == 1 ? $parts[0]{detail}
                 : join('; ', map { "$_->{label}: $_->{detail}" } @parts);
        my $title = html("$what; checked $checked");
        $badges .= qq{<span class="badge" title="$title">}
                 . qq{<span class="label">} . html($b) . qq{</span>}
                 . qq{<span class="$status">$status</span></span>\n};
    }
    open(my $fh, ">$file") or die "%$facility-F-PAGE, unable to write $file: $!\n";
    print $fh <<"EOF";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="refresh" content="$refresh">
<title>Halls of ZK status</title>
<style>
html, body { margin: 0; padding: 0; background: transparent; }
body { font: 11px/20px Verdana, "DejaVu Sans", Geneva, sans-serif; }
.badge { display: inline-block; margin: 0 4px 4px 0; border-radius: 3px;
         overflow: hidden; white-space: nowrap; color: #fff;
         text-shadow: 0 1px 0 rgba(1,1,1,.3); }
.badge span { display: inline-block; padding: 0 6px; }
.label { background: #555; }
.up { background: #4c1; }
.down { background: #e05d44; }
</style>
</head>
<body>
$badges</body>
</html>
EOF
    close $fh or die "%$facility-F-PAGE, unable to write $file: $!\n";
}

sub read_state {
    my ($file) = @_;
    my %s;
    open(my $fh, "<$file") or return %s;
    while (my $line = <$fh>) {
        $s{$1} = $2 if $line =~ /^\s*(\w+)\s*=\s*(\w+)/;
    }
    close $fh;
    return %s;
}

sub write_state {
    my ($file, $results) = @_;
    open(my $fh, ">$file") or die "%$facility-F-STATE, unable to write $file: $!\n";
    print $fh "$_->{name} = $_->{status}\n" foreach @$results;
    close $fh;
}

# The same rules as the DCL: key = value, a ! starts a comment, keys are
# not case sensitive, and an unknown key is an error.
sub read_config {
    my ($file) = @_;
    my %c;
    open(my $fh, "<$file") or die "%$facility-F-OPEN, unable to open $file: $!\n";
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/!.*//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq '';
        my ($key, $value) = $line =~ /^([^=]*?)\s*=\s*(.*)$/
            or die "%$facility-F-SYNTAX, $file line $.: expected key = value\n";
        $key = lc $key;
        $key =~ s/\s+//g;
        die "%$facility-F-BADKEY, $file line $.: unknown key \"$key\"\n"
            unless $known{$key};
        $c{$key} = $value;
    }
    close $fh;
    return %c;
}
__END__
