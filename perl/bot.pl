use strict;
use warnings;
use Jiraiya;
my $jiraiya = Jiraiya->new(
  irc_server => 'localhost',
  irc_port => 6667,
  irc_password => '',
  irc_channels => {
    '#hoge' => {
      key => '',
      project_key => 'DEMO', #=> JIRA
      charset => 'UTF-8',
    },
  },
  jira_url => 'https://rightgo09.atlassian.net/',
  # account that request to JIRA
  jira_user_id => 'jiraiya',
  jira_user_pw => 'jiraiya',
);
$jiraiya->cook;
