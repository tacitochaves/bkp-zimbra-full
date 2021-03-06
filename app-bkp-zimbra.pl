#!/usr/bin/env perl
#
# app-bkp-zimbra.pl
#
# Este programa tem por objetivo realizar o backup de todas as contas de um determinado servidor de correio. 
# O backup cobre: obtenção de caixas de entrada, saída e demais mensagens trocadas, calendários, alguns outros
# atributos de mensagens e autenticação de usuário. Ao final o agente gera um email passando algumas informações.
#
# Author: Tácito Chaves - 2015-02-03
# e-mail: tacitochaves@gmail.com
# skype: tacito.chaves

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Copy qw(copy);
use ZIMBRA::BKP_Full;
use REMOTE::Availability;
use REMOTE::Mounting;

my $self = ZIMBRA::BKP_Full->new;
my $c    = REMOTE::Availability->new;
my $d    = REMOTE::Mounting->new;

my $param = {
    binary       => { zmprov    => "/opt/zimbra/bin/zmprov", zmmailbox => "/opt/zimbra/bin/zmmailbox" },
    dst_backup   => { mailboxes => "/bkp-zimbra", password => "/bkp-zimbra/data" },
    domain       => "acai.com.br",
};

my $all_accounts = $self->handle_accounts( "$param->{binary}->{zmprov}", "$param->{domain}" );

# criando backup dos dados: envio/recebimento
for my $conta ( @{$all_accounts} ) {
    chomp $conta;
    $self->bkp_dados( "$param->{binary}->{zmmailbox}", $conta, $param->{dst_backup}->{mailboxes} );
}

my $data = [];

map { chomp $_; push @{ $data }, $self->handle_passwords($_) } @{ $all_accounts };

# criando backup das senhas de todas as contas
for my $encrypted ( @{ $data } ) {
    for my $emails ( keys %{ $encrypted } ) {
        $self->adding_tar_file( "$emails", "$encrypted->{$emails}->{password}", $param->{domain}, "$param->{dst_backup}->{mailboxes}" );
    }
}

# carregando todos os backups no diretório: /bkp-zimbra/
my $load_backup = $self->load_backup_dir( "$param->{dst_backup}->{mailboxes}" );

for my $file ( @{ $load_backup } ) {
    $self->_compression( "$param->{dst_backup}->{mailboxes}", "$file" );
}

# import data of the conection
my $fh = $d->_read($ARGV[0]);

# takes the server ip network
my $host = $d->_parse( $fh->{Destination} );

# checks if the host is accessible on the network
my $result = $c->check_host( $host );

if ( $result ne 100 ) {

    my $check_point = $d->check_assembly( $fh->{Directory} );

    # carregando todos os backups no diretório: /bkp-zimbra/
    $load_backup = $self->load_backup_dir( "$param->{dst_backup}->{mailboxes}" );

    if ( $check_point ne "is mounted" ) {

        # montando o compartilhamento no servidor de backup
        $d->mount($fh);

        # realizando a cópia para o servidor de backup
        for my $compacted ( @{ $load_backup } ) {

            copy "$param->{dst_backup}->{mailboxes}/$compacted", "$fh->{Directory}/";

        }
    }

    $d->umount( $fh->{Directory} );

}
