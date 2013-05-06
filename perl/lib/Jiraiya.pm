package Jiraiya {
  use Mouse;
  use Mouse::Util::TypeConstraints;
  use URI;

  my $subtype_uri = subtype 'Jiraiya::URI'
    => as class_type('URI');
  coerce $subtype_uri
    => from 'Str' => via { URI->new($_) };

  has 'jira_url'     => (is => 'ro', isa => $subtype_uri, required => 1, coerce => 1);
  has 'jira_user_id' => (is => 'ro', isa => 'Str',        required => 1);
  has 'jira_user_pw' => (is => 'ro', isa => 'Str',        required => 1);

  has 'irc_channels' => (is => 'ro', isa => 'HashRef', required => 1);
  has 'irc_server'   => (is => 'ro', isa => 'Str',     required => 1);
  has 'irc_port'     => (is => 'ro', isa => 'Int',     required => 1);
  has 'irc_password' => (is => 'ro', isa => 'Str',     required => 1);

  has 'nick'   => (is => 'ro', isa => 'Str',             default => 'jiraiya');
  has 'recipe' => (is => 'ro', isa => 'Jiraiya::Recipe', default => \&default_recipe, lazy => 1);

  has 'cv'  => (is => 'rw', isa => 'AnyEvent::CondVar'    );
  has 'irc' => (is => 'rw', isa => 'AnyEvent::IRC::Client');

  sub BUILDARGS {
    my $class = shift;
    return ref($_[0]) eq 'HASH' ? $_[0] : { @_ };
  }

  sub BUILD {
    my $self = shift;
    $self->init;
  }

  __PACKAGE__->meta->make_immutable;

  no Mouse;

  use AnyEvent;
  use AnyEvent::IRC::Client;
  use Jiraiya::Recipe;

  sub init {
    my $self = shift;

    my $cv  = AnyEvent->condvar;
    my $irc = AnyEvent::IRC::Client->new;

    $irc->reg_cb(
      registered => $self->cb_registered,
      disconnect => $self->cb_disconnect,
      publicmsg  => $self->cb_publicmsg,
    );

    $self->cv($cv);
    $self->irc($irc);
  }

  sub default_recipe {
    my $self = shift;
    my $recipe = Jiraiya::Recipe->new({
      nick     => $self->nick,
      channels => $self->irc_channels,

      jira_url     => $self->jira_url,
      jira_user_id => $self->jira_user_id,
      jira_user_pw => $self->jira_user_pw,
    });
    return $recipe;
  }

  sub cb_registered {
    return sub { print "registered.\n" };
  }

  sub cb_disconnect {
    return sub { print "disconnected.\n" };
  }

  sub cb_publicmsg {
    my $self = shift;
    return sub {
      my ($irc, $channel, $ircmsg) = @_;
      my (undef, $who) = $irc->split_nick_mode($ircmsg->{prefix});

      my $msg = $self->recipe->cook(
        irc     => $irc,
        channel => $channel,
        ircmsg  => $ircmsg,
        who     => $who,
      );
      $irc->send_chan($channel, "NOTICE", $channel, $msg) if $msg;
    };
  }

  sub cook {
    my $self = shift;
    my $info = {
      nick     => $self->nick,
      real     => $self->nick,
      password => $self->irc_password,
    };
    $self->irc->connect($self->irc_server, $self->irc_port, $info);
    for my $name (keys %{$self->irc_channels}) {
      $self->irc->send_srv("JOIN", $name);
    }
    $self->cv->recv;
    $self->irc->disconnect;
  }

  *run = \&cook;
}
1;
__END__
