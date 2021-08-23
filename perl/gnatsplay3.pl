#!/tools/perl/5.6.0/SunOS/bin/perl


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

sub server_reply
{
  my($state, $text, $type);
  my $raw_reply = <SOCK>;
  if(defined($reply_debug))
  {
    print "<tt>server_reply: $raw_reply</tt><br>\n";
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

sub read_server
{
  my(@text);

  while(<SOCK>)
  {
    if(defined($reply_debug))
    {
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
        print "gnatsweb: unparseable gnatsd output: $raw_reply; user=$db_prefs{'user'}, db=$global_prefs{'database'}; stacktrace: ", print_stacktrace());
        return;
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
            $text = " You do not have access to database \"$global_prefs{'database'}\"";
        } else {
            $text = " Access denied (login again & check usercode/password)";
       }
      }
      print "Return code: $state - $text";
      print "gnatsd error $state-$text; user=$db_prefs{'user'}, db=$global_prefs{'database'}; stacktrace: ", print_stacktrace());
    }
    else
    {
      # gnatsd returned a state, but we don't know what it is
      push(@rettext, $text);
      print "Cannot understand gnatsd output: $state '$text'";
      print "gnatsweb: gnatsd error $state-$text; user=$db_prefs{'user'}, db=$global_prefs{'database'}; stacktrace: ", print_stacktrace());
    }
  } until ($type != $REPLY_CONT);
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
    return 'In: ' . join(' <= ', @stacktrace);
}

sub client_init
{
  my($iaddr, $paddr, $proto, $line, $length);
  if(!($iaddr = inet_aton($site_gnats_host)))
  {
    error_page("Unknown GNATS host '$site_gnats_host'",
               "Check your Gnatsweb configuration.");
    exit();
  }
  $paddr = sockaddr_in($site_gnats_port, $iaddr);

  $proto = getprotobyname('tcp');
  if(!socket(SOCK, PF_INET, SOCK_STREAM, $proto))
  {
    print "socket: $!\n";
    print "gnatsweb: client_init error: $! ; user=$db_prefs{'user'}, db=$global_prefs{'database'}; stacktrace: ", print_stacktrace());
    exit();
  }
  if(!connect(SOCK, $paddr))
  {
    print "connect: $!\n";
    print "gnatsweb: client_init error: $! ; user=$db_prefs{'user'}, db=$global_prefs{'database'}; stacktrace: ", print_stacktrace());
    exit();
  }
  SOCK->autoflush(1);
  get_reply();
}

sub submitedit
{
  my $page = 'Edit PR Results';

  my $debug = 0;
  my $lock_end_reached;

  my($pr) = $q->param('pr');

  # strip out leading category (and any other non-digit trash) from
  # $pr, since it will unduly confuse gnats when we try to submit the
  # edit
  $pr =~ s/\D//g;

  if(!$pr)
  {
    error_page("You must specify a problem report number");
    return;
  }

  my(%fields, %mailto, $adr);
  my $audittrail = '';
  my $err = '';

  # Retrieve new attachment (if any) before locking PR, in case it fails.
  my $encoded_attachment = encode_attachment('attached_file');

  my(%oldfields) = lockpr($pr, $db_prefs{'user'});
  LOCKED:
  {
    # Trim Responsible for compatibility.
    $oldfields{$RESPONSIBLE_FIELD} = trim_responsible($oldfields{$RESPONSIBLE_FIELD});

    # Merge %oldfields and CGI params to get %fields.  Not all gnats
    # fields have to be present in the CGI params; the ones which are
    # not specified default to their old values.
    %fields = %oldfields;
    foreach my $key ($q->param)
    {
      my $val = $q->param($key);
      my $ftype = fieldinfo($key, 'fieldtype') || '';
      if($key =~ /-Changed-Why/
         || ($ftype eq 'multitext'))
      {
        $val = fix_multiline_val($val);
      }
      elsif($ftype eq 'multienum')
      {
        my @val = $q->param($key);
        $val = unparse_multienum(\@val, $key);
      }
      $fields{$key} = $val;
      cb("submitedit", $key, \%fields);
    }

    # Add the attached file, if any, to the new PR.
    add_encoded_attachment_to_pr(\%fields, $encoded_attachment);

    # Delete any attachments, if directed.
    my(@deleted_attachments) = $q->param('delete attachments');
    remove_attachments_from_pr(\%fields, @deleted_attachments);

    if ($debug)
    {
      print "<h3>debugging -- PR edits not submitted</h3><font size=1><table>";
      debug_print_fields(\%fields);
      last LOCKED;
    }

    my $newlastmod = $fields{$LAST_MODIFIED_FIELD} || '';
    my $oldlastmod = $oldfields{$LAST_MODIFIED_FIELD} || '';

    if($newlastmod ne $oldlastmod)
    {
      error_page("Sorry, PR $pr has been modified since you started editing it.",
                "Please return to the edit form, press the Reload button, " .
                "then make your edits again.\n" .
                "<pre>Last-Modified was    '$newlastmod'\n" .
                "Last-Modified is now '$oldlastmod'</pre>");
      last LOCKED;
    }

# Replace semicolons by commas in Notify-List: field.
    $fields{'Notify-List'} =~ s/\;/,/g;

    my (@errors) = ();
    if ($fields{$RESPONSIBLE_FIELD} eq "unknown")
    {
      push(@errors, "$RESPONSIBLE_FIELD is 'unknown'");
    }
    if ($fields{$CATEGORY_FIELD} eq "unknown")
    {
      push(@errors, "$CATEGORY_FIELD is 'unknown'.");
    }
    if($fields{$SUBMITTER_ID_FIELD} eq "unknown")
    {
      push(@errors, "$SUBMITTER_ID_FIELD is 'unknown'.");
    }
    if (@errors)
    {
      push(@errors,
         "Go back to the edit form, correct the errors and submit again.");
      error_page("The PR has not been submitted.", \@errors);
      last LOCKED;
    }

    # If Reply-To changed, we need to splice the change into the envelope.
    if($fields{'Reply-To'} ne $oldfields{'Reply-To'})
    {
      if ($fields{'envelope'} =~ /^'Reply-To':/m)
      {
        # Replace existing header with new one.
        $fields{'envelope'} =~ s/^'Reply-To':.*$/'Reply-To': $fields{'Reply-To'}/m;
      }
      else
      {
        # Insert new header at end (blank line).  Keep blank line at end.
        $fields{'envelope'} =~ s/^$/'Reply-To': $fields{'Reply-To'}\n/m;
      }
    }

    # Check whether fields that are specified in dbconfig as requiring a
    # 'Reason Changed' have the reason specified:
    foreach my $fieldname (keys %fields)
    {
      my $newvalue = $fields{$fieldname} || '';
      my $oldvalue = $oldfields{$fieldname} || '';
      my $fieldflags = fieldinfo($fieldname, 'flags') || 0;
      if ( ($newvalue ne $oldvalue) && ( $fieldflags & $REASONCHANGE) )
      {
        if($fields{$fieldname."-Changed-Why"} =~ /^\s*$/)
        {
          error_page("Field '$fieldname' must have a reason for change",
                    "Please press the 'Back' button of you browser, correct the problem and resubmit
.");
          last LOCKED;
        }
      }
      if ($newvalue eq $oldvalue && exists $fields{$fieldname."-Changed-Why"} )
      {
        delete $fields{$fieldname."-Changed-Why"};
      }
    }

    my($newpr) = unparsepr('gnatsd', %fields);
    $newpr =~ s/\r//g;

    # Submit the edits.  We need to unlock the PR even if the edit fails
    local($suppress_client_exit) = 1;
        client_cmd("editaddr $db_prefs{'user'}");
        last LOCKED if ($client_would_have_exited);
    client_cmd("edit $pr");
        last LOCKED if ($client_would_have_exited);
    client_cmd("$newpr.");

    $lock_end_reached = 1;
  }
  unlockpr($pr);

  if ( (! $client_would_have_exited) && $lock_end_reached) {
    # We print out the "Edit successful" message after unlocking the PR. If the user hits
    # the Stop button of the browser while submitting, the web server won't terminate the
    # script until the next time the server attempts to output something to the browser.
    # Since this is the first output after the PR was locked, we print it after the unlocking.
    # Let user know the edit was successful. After a 2s delay, refresh back
    # to where the user was before the edit. Internet Explorer does not honor the
    # HTTP Refresh header, so we have to complement the "clean" CGI.pm method
    # with the ugly hack below, with a HTTP-EQUIV in the HEAD to make things work.
    my $return_url = $q->param('return_url') || get_script_name();
    # the refresh header chokes on the query-string if the
    # params are separated by semicolons...
    $return_url =~ s/\;/&/g;

    my $refresh = 2;
    print_header(-Refresh => "$refresh; URL=$return_url");

    # Workaround for MSIE:
    my @extra_head_args = (-head => $q->meta({-http_equiv=>'Refresh',
                                    -content=>"$refresh; URL=$return_url"}));

    page_start_html($page, 0, \@extra_head_args);
    page_heading($page, 'Edit successful');
    print <<EOM;
<p>You will be returned to <a href="$return_url">your previous page</a>
in $refresh seconds...</p>
EOM
  }

  page_footer($page);
  page_end_html($page);
}

 initialize -
#     Initialize gnatsd-related globals and login to gnatsd.
#
sub initialize
{
  my $regression_testing = shift;

  my(@lines);
  my $response;

  ($response) = client_init();

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
            login_page($q->url());
            exit();
        } else {
            # store the list of databases for later use
            $global_list_of_dbs = \@db_list;
        }

        # Issue CHDB command; revert to login page if it fails.
        # use the three-arg version, to authenticate at the same time
        my (@chdb_response) = client_cmd("chdb $global_prefs{'database'} $db_prefs{'user'} $db_prefs
{'password'}");
        if (length($chdb_response[0]) == 0 || $client_would_have_exited) {
            login_page($q->url());
            exit();
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
            login_page(undef, "You do not have access to database: $global_prefs{'database'}.<br />\
nPlease log in to another database<br /><br />\n");
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
  @lines = client_cmd("LIST Categories");
  parse_categories(@lines);
  @lines = client_cmd("LIST Submitters");
  parse_submitters(@lines);
  @lines = client_cmd("LIST Responsible");
  parse_responsible(@lines);

  # Now that everything's all set up, let the site_callback have at it.
  # It's return value doesn't matter, but here it can muck with our defaults.
  cb('initialize');
}
sub lockpr
{
  my($pr, $user) = @_;
  #print "<pre>locking $pr $user\n</pre>";
  return parsepr(client_cmd("lock $pr $user"));
}

sub unlockpr
{
  my($pr) = @_;
  #print "<pre>unlocking $pr\n</pre>";
  client_cmd("unlk $pr");
}
