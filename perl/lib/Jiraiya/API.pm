package Jiraiya::API {
  use Mouse;
  use JSON qw/ decode_json /;

  has 'base_url' => (is => 'ro', isa => 'URI');
  has 'furl' => (is => 'ro', isa => 'Furl');

  sub issue_detail {
    my ($self, $issue_id, $project_key) = @_;
    my $uri = $self->base_url->clone;
    $uri->path("rest/api/2/issue/".$project_key."-".$issue_id);
    my $res = $self->furl->get($uri);
    unless ($res->is_success) {
      warn $res->status_line and return;
    }
    my $content = decode_json($res->content);
    my $browse_uri = $self->base_url->clone;
    $browse_uri->path("browse/".$project_key."-".$issue_id);
    return $browse_uri." : [".$content->{"fields"}->{"summary"}."] [".$content->{"fields"}->{"assignee"}->{"name"}."] [".$content->{"fields"}->{"status"}->{"name"}."] [".$content->{"fields"}->{"issuetype"}->{"name"}."]";
  }
}
1;
__END__
