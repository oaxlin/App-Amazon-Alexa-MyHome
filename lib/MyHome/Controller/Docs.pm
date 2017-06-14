package MyHome::Controller::Docs;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {
  my $self = shift;

  # Render template "docs/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
