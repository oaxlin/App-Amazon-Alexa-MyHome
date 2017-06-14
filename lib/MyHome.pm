package MyHome;
use Mojo::Base 'Mojolicious';
use lib ('/home/oaxlin/alexa/lib');
use Net::Amazon::Alexa::Dispatch;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Load configuration from hash returned by "my_app.conf"
    my $config = $self->plugin('Config');

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('docs#welcome');
    $r->any('/alexa_linking')->to('alexa#auth_alexa_user');
    $r->any('/AlexaMyHome/alexa_linking')->to('alexa#auth_alexa_user');

    my $auth_alexa = $r->under->to('alexa#auth_alexa');
    $auth_alexa->any('/alexa')->to('alexa#run_method');
    $auth_alexa->any('/AlexaMyHome/alexa')->to('alexa#run_method');
}

1;
