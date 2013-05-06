package Jiraiya::Recipe {
  use Mouse;
  use MIME::Base64;
  use Furl;
  use JSON;
  use Encode qw/ encode decode /;
  use feature qw/ state /;

  has 'nick'     => (is => 'ro', isa => 'Str'    );
  has 'channels' => (is => 'ro', isa => 'HashRef');

  has 'jira_url'     => (is => 'ro');
  has 'jira_user_id' => (is => 'ro');
  has 'jira_user_pw' => (is => 'ro');

  sub furl {
    return state $furl = do {
      my $self = shift(@_);
      my $basic_auth = encode_base64($self->jira_user_id.":".$self->jira_user_pw);
      Furl->new(headers => ['Authorization' => 'Basic '.$basic_auth ]);
    };
  }

  sub cook {
    my ($self, %args) = @_;
    my $irc     = $args{irc}    or return;
    my $ircmsg  = $args{ircmsg} or return;
    my $who     = $args{who}    or return;
    my $channel = $self->channel($args{channel}) or return;

    my $nick  = $self->nick;
    my $msg   = $ircmsg->{params}[1];
    my $charset = $channel->{charset} || 'UTF-8';
    $msg = decode($charset, $msg);

    my $reply = '';

    if ($msg =~ /\#(\d+)/) {
      my $issue_id = $1;
      my $uri = $self->jira_url->clone;
      $uri->path("rest/api/2/issue/".$channel->{"project_key"}."-".$issue_id);
      my $res = $self->furl->get($uri);
      unless ($res->is_success) {
        warn $res->status_line;
        return;
      }
      my $content = decode_json($res->content);
      my $browse_uri = $self->jira_url->clone;
      $browse_uri->path("browse/".$channel->{"project_key"}."-".$issue_id);
      $reply = $browse_uri." : [".$content->{"fields"}->{"summary"}."] [".$content->{"fields"}->{"assignee"}->{"name"}."] [".$content->{"fields"}->{"status"}->{"name"}."] [".$content->{"fields"}->{"issuetype"}->{"name"}."]";
    }

    $reply or return;
    $reply = encode($charset, $reply);
    return $reply;
  }

  sub channel {
    my $self = shift;
    my $name = shift or return;
    my $channel = $self->channels->{$name};
    $channel->{name} = $name;
    return $channel;
  }
}
1;
__END__
