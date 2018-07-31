package MyHome::Controller::Alexa;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(url_escape);
use lib qw(/home/oaxlin/alexa/lib);
use lib qw(/home/oaxlin/bravia/lib);
use lib qw(/home/oaxlin/hue/lib);

sub auth_alexa_user {
    my $self = shift;
    local $SIG{__WARN__} = sub { $self->alexa_log(@_); };
    my $config = $self->config;
    my $alexa = Net::Amazon::Alexa::Dispatch->new($config);
    my $nvp = $self->req->params->to_hash;

    #make debugging with an initial GET a bit easier
    $nvp->{$_} = shift @{$nvp->{$_}} foreach grep { ref $nvp->{$_} && $_ ne 'Password' } keys %$nvp;

    if (! defined $nvp->{'client_id'} || ! defined $nvp->{'redirect_uri'} || $nvp->{'response_type'} ne 'token') {
        $self->render(template=>'server_error',msg=>'Missing expected NVP data',format=>'html',status=>400); # 400 bad request
        return undef;
    }

    my $token = eval{$alexa->alexa_authenticate_params($nvp)};
    $self->app->log->warn($@) if $@;
    if (!$token) {
        delete $nvp->{'Password'};
        $self->render('login',msg=>$alexa->skill_name,nvp=>$nvp,status=>401);
        return undef;
    }

    $self->res->code(307); # 307 Temporary Redirect
    my $uri = $nvp->{'redirect_uri'}.'#token_type=Bearer&access_token='.url_escape($token).'&state='.url_escape($nvp->{'state'});
    $self->redirect_to($uri);
    return 1;
}

sub auth_alexa {
    my $self = shift;
    local $SIG{__WARN__} = sub { $self->alexa_log(@_); };
    my $config = $self->config;
    my $alexa = Net::Amazon::Alexa::Dispatch->new($config);
    my $json = $self->req->json;
    my $auth = eval { $alexa->alexa_authenticate_json($json); };
    my $e = $@;
    return 1 if $auth;
    $e = { error => $e } unless ref $e eq 'Throw'; # put $e into a hash protects it in msg_to_hash
    $self->render(json => $alexa->msg_to_hash($e,'Not authorized'),status=>401);
    return undef;
}

sub run_method { # expects you've previously checked auth_alexa via $r->under
    my $self = shift;
    local $SIG{__WARN__} = sub { $self->alexa_log(@_); };
    my $config = $self->config;
    my $alexa = Net::Amazon::Alexa::Dispatch->new($config);
    my $json = $self->req->json;
    my $status = 200;
    my $ret = eval { $alexa->run_method($json) };
    my $e = $@;
    if ($e) {
        $status = 500;
        if (ref $e eq 'Throw' && $e->{'alexa_safe'}) {
            $status = $e->{'status'} if exists $e->{'http_status'} && $e->{'http_status'};
            $ret = $e;
        } else {
            $status = 500;
            $e = { error => $e };
        }
    }
    $self->render(json => $alexa->msg_to_hash($ret,'Unknown response'),status=>$status);
}

sub alexa_log {
    my $self = shift;
    my $msg = shift;
    chomp($msg); # the trailing \n is annoying
    $self->app->log->warn($msg,@_);
}

1;
