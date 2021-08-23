$AppConfig{myuseremail} = 'raytran@broadcom.com';
$AppConfig{remedyemail}="remedyhelp\@broadcom.com";
$one_week_out = UnixDate( DateCalc("today","+7 days",\$err), "%m/%d/%Y 11:59:59PM");
$current_L2_assignee = "sarmak";
$server = "ccase-irva-1";

$message .= "Tickets Created by Automated ClearCase VOB Check Process On - $server\n";
$message .= "\@\~CT R\"\n";
$message .= "\@\~C \"SCM\"\n";
$message .= "\@\~T \"Clearcase\"\n";
$message .= "\@\~I \"Other\"\n";
$message .= "\@\~CCA \"raytran,dskanes\"\n";
$message .= "\@\~DD \"$one_week_out\"\n";
$message .= "\@\~AS \"Irvine\"\n";
$message .= "\@\~AI \"$current_L2_assignee\"\n";
$message .= "\@\~AG \"SCM L2\"\n";
Notify("$AppConfig{myuseremail}","$AppConfig{remedyemail}","$AppConfig{myuseremail}","$hdticket","$message");



