#!/tools/perl/5.6.0/SunOS/bin/perl

use Socket;
use IO::Handle;
use Data::Dumper;
#use strict;

my $gnats_host = "gnats-irva-3.broadcom.com";
my $gnats_port = "1530";
my $gnats_database => "IT-Test";
my $gnats_user = "gnats4";
my $gnats_password = "emsggn09";


# debug setting
my $site_allow_remote_debug = 1;
# debugparam = cmd, reply or all
my $debugparam = "all";

# The possible values of a server reply type.  $REPLY_CONT means that there
# are more reply lines that will follow; $REPLY_END Is the final line.
my $REPLY_CONT = 1;
my $REPLY_END = 2;

my %LEVEL_TO_CODE = ('deny' => 1,
                     'none' => 2,
                     'submit' => 3,
                     'view' => 4,
                     'viewconf' => 5,
                     'edit' => 6,
                     'admin' => 7);

# Server reply codes
my $CODE_GREETING = 200;
my $CODE_CLOSING = 201;
my $CODE_OK = 210;
my $CODE_SEND_PR = 211;
my $CODE_SEND_TEXT = 212;
my $CODE_NO_PRS_MATCHED = 220;
my $CODE_NO_ADM_ENTRY = 221;
my $CODE_PR_READY = 300;
my $CODE_TEXT_READY = 301;
my $CODE_INFORMATION = 350;
my $CODE_INFORMATION_FILLER = 351;
my $CODE_NONEXISTENT_PR = 400;
my $CODE_EOF_PR = 401;
my $CODE_UNREADABLE_PR = 402;
my $CODE_INVALID_PR_CONTENTS = 403;
my $CODE_INVALID_FIELD_NAME = 410;
my $CODE_INVALID_ENUM = 411;
my $CODE_INVALID_DATE = 412;
my $CODE_INVALID_FIELD_CONTENTS = 413;
my $CODE_INVALID_SEARCH_TYPE = 414;
my $CODE_INVALID_EXPR = 415;
my $CODE_INVALID_LIST = 416;
my $CODE_INVALID_DATABASE = 417;
my $CODE_INVALID_QUERY_FORMAT = 418;
my $CODE_NO_KERBEROS = 420;
my $CODE_AUTH_TYPE_UNSUP = 421;
my $CODE_NO_ACCESS = 422;
my $CODE_LOCKED_PR = 430;
my $CODE_GNATS_LOCKED = 431;
my $CODE_GNATS_NOT_LOCKED = 432;
my $CODE_PR_NOT_LOCKED = 433;
my $CODE_CMD_ERROR = 440;
my $CODE_WRITE_PR_FAILED = 450;
my $CODE_ERROR = 600;
my $CODE_TIMEOUT = 610;
my $CODE_NO_GLOBAL_CONFIG = 620;
my $CODE_INVALID_GLOBAL_CONFIG = 621;
my $CODE_NO_INDEX = 630;
my $CODE_FILE_ERROR = 640;

$| = 1; # flush output after each print

sub server_reply
{
  my($state, $text, $type);
  my $raw_reply = <SOCK>;
  if(defined($reply_debug))
  {
    print "debug info\n";
    print "server_reply: $raw_reply\n";
  }
  if($raw_reply =~ /(\d+)([- ]?)(.*$)/)
  {
    $state = $1;
    $text = $3;
    if($2 eq '-')
    {
      $type = $REPLY_CONT;
    }
    else
    {
      if($2 ne ' ')
      {
        print "bad type of reply from server\n";
      }
      $type = $REPLY_END;
    }
    return ($state, $text, $type);
  }
  else
  {
    # unparseable reply.  send back the raw reply for error reporting
    return (undef, undef, undef, $raw_reply);
  }
}


sub get_reply
{
  my @rettext = ();
  my ($state, $text, $type, $raw_reply);

  do {
    ($state, $text, $type, $raw_reply) = server_reply();

    unless ($state) {
        # gnatsd has returned something unparseable
        if ($reply_debug || $client_cmd_debug) {
            print "unparseable reply from gnatsd: $raw_reply\n";
        } else {
            print "Unparseable reply from gnatsd\n";
        }
        print "gnatsweb: unparseable gnatsd output: $raw_reply; user=$gnats_user, db=$gnats_database; stacktrace: ", print_stacktrace();
        return;
    }

  if(defined($reply_debug))
  {
    print "server_reply passed through\n";
    print "state is $state\n";
  }

    if($state == $CODE_GREETING)
    {
      push(@rettext, $text);
      # nothing
    }
    elsif($state == $CODE_OK || $state == $CODE_GREETING
          || $state == $CODE_CLOSING)
    {
      push(@rettext, $text);
      # nothing
    }
    elsif($state == $CODE_PR_READY || $state == $CODE_TEXT_READY)
    {
      @rettext = read_server();
    }
    elsif($state == $CODE_SEND_PR || $state == $CODE_SEND_TEXT)
    {
      # nothing, tho it would be better...
    }
    elsif($state == $CODE_INFORMATION_FILLER)
    {
      # nothing
    }
    elsif($state == $CODE_INFORMATION)
    {
      push(@rettext, $text);
    }
    elsif($state == $CODE_NO_PRS_MATCHED)
    {
      print "Return code: $state - $text\n";
      client_exit();
      push(@rettext, $text);
    }
    elsif($state >= 400 && $state <= 799)
    {
      if ($state == $CODE_NO_ACCESS)
      {
        if ($site_gnatsweb_server_auth) {
            $text = " You do not have access to database \"$gnats_database\"";
        } else {
            $text = " Access denied (login again & check usercode/password)";
       }
      }
      print "Return code: $state - $text";
      print "gnatsd error $state-$text; user=$gnats_user, db=$gnats_database; stacktrace: ", print_stacktrace();
    }
    else
    {
      # gnatsd returned a state, but we don't know what it is
      push(@rettext, $text);
      print "Cannot understand gnatsd output: $state '$text'";
      print "gnatsweb: gnatsd error $state-$text; user=$gnats_user, db=$gnats_database; stacktrace: ", print_stacktrace();
    }
  } until ($type != $REPLY_CONT);
  if ( $reply_debug ) {
      print "got server reply\n";
  }
  return @rettext;
}

# print a stacktrace
# used by the various warn() statments to emit useful diagnostics
# to the web server error logs.
sub print_stacktrace {
    my @stacktrace;
    my $i = 1;
    while ( my($subroutine) = (caller($i++))[3] ) {
        push(@stacktrace, $subroutine);
    }
    return 'In: ' . join(' <= ', @stacktrace) . "\n";
}

# to debug:
#     local($client_cmd_debug) = 1;
#     client_cmd(...);
sub client_cmd
{
  my($cmd) = @_;
  my $debug = 0;
  print SOCK "$cmd\n";
  warn "client_cmd: $cmd" if $debug;
  if(defined($client_cmd_debug))
  {
    print "client_cmd: $cmd\n";
  }
  return get_reply();
}

sub read_server
{
  my(@text);

  while(<SOCK>)
  {
    if(defined($reply_debug))
    {
      print_header();
      print "<tt>read_server: $_</tt><br>\n";
    }
    if(/^\.\r/)
    {
      return @text;
    }
    $_ =~ s/[\r\n]//g;
    # Lines which begin with a '.' are escaped by gnatsd with another '.'
    $_ =~ s/^\.\././;
    push(@text, $_);
  }
}

# can_create -
#     If $no_create_without_access is set to a defined gnats
#     access_level, return false unless user's access_level is >= to
#     level set in $no_create_without_access
sub can_create
{
    if (exists($LEVEL_TO_CODE{$no_create_without_access})) {
      return ($LEVEL_TO_CODE{$access_level} >= $LEVEL_TO_CODE{$no_create_without_access});
    } else {
      return 1;
    }
}

# can_edit -
#     Return true if the user has edit privileges or better.
sub can_edit
{
  return ($LEVEL_TO_CODE{$access_level} >= $LEVEL_TO_CODE{'edit'});
}

sub init_fieldinfo
{
  my $debug = 0;
  my $field;

  @fieldnames = client_cmd("list FieldNames");
  my @type = client_cmd ("ftyp ". join(" ",@fieldnames));
  my @desc = client_cmd ("fdsc ". join(" ",@fieldnames));
  my @flgs = client_cmd ("fieldflags ". join(" ",@fieldnames));
  my @fdflt = client_cmd ("inputdefault ". join(" ",@fieldnames));
  foreach $field (@fieldnames) {
    $fielddata{$field}{'flags'} = 0;
    $fielddata{$field}{'fieldtype'} = lc(shift @type);
    $fielddata{$field}{'desc'} = shift @desc;
    $fielddata{$field}{'fieldflags'} = lc(shift @flgs);
    if ($fielddata{$field}{'fieldflags'} =~ /requirechangereason/)
    {
      $fielddata{$field}{'flags'} |= $REASONCHANGE;
    }
    if ($fielddata{$field}{'fieldflags'} =~ /readonly/)
    {
      $fielddata{$field}{'flags'} |= $READONLY;
    }
    if ($fielddata{$field}{'fieldtype'} eq 'multienum')
    {
      my @response = client_cmd("ftypinfo $field separators");
      $response[0] =~ /'(.*)'/;
      $fielddata{$field}{'separators'} = $1;
      $fielddata{$field}{'default_sep'} = substr($1, 0, 1);
    }
    my @values = client_cmd ("fvld $field");
    $fielddata{$field}{'values'} = [@values];
    $fielddata{$field}{'default'} = shift (@fdflt);
    $fielddata{$field}{'default'} =~ s/\\n/\n/g;
    $fielddata{$field}{'default'} =~ s/\s$//;
  }
  foreach $field (client_cmd ("list InitialInputFields")) {
    $fielddata{$field}{flags} |= $SENDINCLUDE;
  }
  foreach $field (client_cmd ("list InitialRequiredFields")) {
    $fielddata{$field}{flags} |= $SENDREQUIRED;
  }
  if ($debug)
  {
    foreach $field (@fieldnames) {
      warn "name = $field\n";
      warn "  type   = $fielddata{$field}{'fieldtype'}\n";
      warn "  flags  = $fielddata{$field}{'flags'}\n";
      warn "  values = $fielddata{$field}{'values'}\n";
      warn "\n";
    }
  }
}

# parse_submitters -
#     Parse the submitters file.
sub parse_states
{
  my(@lines) = @_;

  @states = ();
  %state_type = ();
  %state_description = ();

  foreach $_ (sort @lines)
  {
    my($state, $type, $description)
          = split(/:/);
    push(@states, $state);
    $state_type{$state} = $type;
    $state_description{$state} = $description;
  }
}


# initialize -
#     Initialize gnatsd-related globals and login to gnatsd.
#
sub initialize
{
  my $regression_testing = shift;

  my(@lines);
  my $response;

  ($response) = client_init();
  if ($trace_debug) {
       print "$response\n";
  }

  # Get gnatsd version from initial server connection text.
  if ($response =~ /GNATS server (.*) ready/)
  {
    $GNATS_VERS = $1;
  }

  # Suppress fatal exit while issuing CHDB and USER commands.  Otherwise
  # an error in the user or database cookie values can cause a user to
  # get in a bad state.
  LOGIN:
  {
    local($suppress_client_exit) = 1
          unless $regression_testing;

        # Issue DBLS command, so that we have a list of databases, in case
        # the user has tried to get into a db they don't have access to,
        # after which we won't be able to do this

        my (@db_list) = client_cmd("dbls");
        if (length($db_list[0]) == 0 || $client_would_have_exited) {
            exit();
        } else {
            # store the list of databases for later use
            $global_list_of_dbs = \@db_list;
        }

        # Issue CHDB command; revert to login page if it fails.
        # use the three-arg version, to authenticate at the same time
        my (@chdb_response) = client_cmd("chdb $gnats_database $gnats_user $gnats_password");
        if (length($chdb_response[0]) == 0 || $client_would_have_exited) {
            exit();
        }
        if ($trace_debug) {
            print "chdb response\n";
            foreach (@chdb_response) {
                print "$_";
            }
        }

        # Get user permission level from the return value of CHDB
        # three arg CHDB should return something like this:
        # 210-Now accessing GNATS database 'foo'
        # 210 User access level set to 'edit'
        if ($chdb_response[1] =~ /User access level set to '(\w*)'/) {
            $access_level = lc($1);
        } else {
            $access_level = 'view';
        }

        # check access level.  if < view, make them log in again.
        # it might be better to allow "create-only" access for users
        # with 'submit' access.
        if ($LEVEL_TO_CODE{$access_level} < $LEVEL_TO_CODE{'view'}) {
            print "You do not have access to database: $gnats_database.\nPlease log in to another database\n";
            undef($suppress_client_exit);
            client_exit();
        }
    }

    # Now initialize our metadata from the database.
    init_fieldinfo ();

  # List various gnats-adm files, and parse their contents for data we
  # will need later.  Each parse subroutine stashes information away in
  # its own global vars.  The call to client_cmd() happens here to
  # enable regression testing of the parse subs using fixed files.
#  @lines = client_cmd("LIST Categories");
#  parse_categories(@lines);
#  @lines = client_cmd("LIST Submitters");
#  parse_submitters(@lines);
#  @lines = client_cmd("LIST Responsible");
#  parse_responsible(@lines);
  @lines = client_cmd("LIST States");
  parse_states(@lines);

}

# Close the client socket and exit.  The exit can be suppressed by:
# setting $suppress_client_exit = 1 in the calling routine (using local)
# [this is only set in edit_pr and the initial login section]
sub client_exit
{
  if (! defined($suppress_client_exit))
  {
    close(SOCK);
    exit();
  }
  else
  {
    $client_would_have_exited = 1;
  }
}

sub client_init
{
    if ($trace_debug) {
        print "starting to connect\n";
    }
    my($iaddr, $paddr, $proto, $line, $length);
    if(!($iaddr = inet_aton($gnats_host))) {
        error_page("Unknown GNATS host '$gnats_host'",
        "Check your Gnatsweb configuration.");
        exit();
    }
    $paddr = sockaddr_in($gnats_port, $iaddr);
    $proto = getprotobyname('tcp');
    if(!socket(SOCK, PF_INET, SOCK_STREAM, $proto)) {
        print "socket: $!n";
        print "gnatsweb: client_init error: $! ; user=$gnats_user, db=$gnats_database; stacktrace: ", print_stacktrace();
        exit();
    }
    if(!connect(SOCK, $paddr)) {
        print "connect: $!\n";
        print "gnatsweb: client_init error: $! ; user=$gnats_user, db=$gnats_database; stacktrace: ", print_stacktrace();
        exit();
    }
    SOCK->autoflush(1);
    get_reply();
    if ($trace_debug) {
        print "client init done\n";
    }

}


sub main {
    if ($site_allow_remote_debug) {
        if ($debugparam eq 'cmd') {
              my $client_cmd_debug = 1;
        }
        if ($debugparam eq 'reply') {
              my $reply_debug = 1;
        }
        if ($debugparam eq 'all') {
              my $reply_debug = 1;
              my $client_cmd_debug = 1;
              my $trace_debug = 1;
        }
    }
    initialize();
    
    client_exit();
    exit();
    
}


MAIN:
    main ();

