$CFVersion                     = "3.2";

$debug                         = 0;

$DOMAINNAME                    = "home.fml.org";
$FQDN                          = "home.fml.org";

$MAIL_LIST                     = "elena\@$DOMAINNAME";
$PERMIT_POST_FROM              = "members_only";
$REJECT_POST_HANDLER           = "reject";

$CONTROL_ADDRESS               = "elena-ctl\@$DOMAINNAME";
$PERMIT_COMMAND_FROM           = "members_only";
$REJECT_COMMAND_HANDLER        = "reject";

$MAINTAINER                    = "elena-admin\@$DOMAINNAME";

$ML_FN                         = "(elena ML)";

$AUTO_REGISTRATION_TYPE        = "confirmation";

$DATE_TYPE                     = "original-date";

$XMLNAME                       = "X-ML-Name: elena";

$XMLCOUNT                      = "X-Mail-Count";

$SUBJECT_TAG_TYPE              = "[:]";

$SUBJECT_FORM_LONG_ID          = 7;

$BRACKET                       = "elena";

$BASE_DIR                      = "/tmp";
$GUIDE_FILE                    = "$BASE_DIR/guide";

$DEFAULT_WHOIS_SERVER		= "localhost";

$DISTRIBUTE_FILTER_HOOK = q#
	print STDERR "test of hook\n";
#;

