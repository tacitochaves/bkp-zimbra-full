package MAIL::Send;

use strict;
use warnings;

use Net::SMTP::TLS; 

sub new {
    return bless {}, shift;
}

sub send_mail {
    return new Net::SMTP::TLS(
        'smtp.gmail.com',
        Port => 587,
        User => 'remetente@gmail.com',
        Password => '123@mudar',
        Timeout => 30,
    );
}

1;
