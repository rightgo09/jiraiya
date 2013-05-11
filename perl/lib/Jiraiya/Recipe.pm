package Jiraiya::Recipe {
  use Mouse;
  use Encode qw/ encode decode /;

  has 'api'      => (is => 'ro', isa => 'Jiraiya::API');
  has 'nick'     => (is => 'ro', isa => 'Str'    );
  has 'channels' => (is => 'ro', isa => 'HashRef');

  sub cook {
    my ($self, %args) = @_;
    my $irc     = $args{irc}    or return;
    my $ircmsg  = $args{ircmsg} or return;
    my $who     = $args{who}    or return;
    my $channel = $self->channel($args{channel}) or return;

    my $api   = $self->api;
    my $nick  = $self->nick;
    my $msg   = $ircmsg->{params}[1];
    my $charset = $channel->{charset} || 'UTF-8';
    $msg = decode($charset, $msg);

    my $reply = '';

    if ($msg =~ /\#(\d+)/) {
      my $issue_id = $1;
      $reply = $api->issue_detail($issue_id, $channel->{project_key});
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
