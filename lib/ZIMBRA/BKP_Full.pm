package ZIMBRA::BKP_Full;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

sub handle_accounts {
    my ( $self, $zmprov, $domain ) = @_;

    $self->{_zmprov} = $zmprov if defined $zmprov;
    $self->{_domain} = $domain if defined $domain;

    open my $ACCOUNTS, "$self->{_zmprov} -l gaa $self->{_domain} |" or die "Comando não encontrado\n";
    my @t_accounts = <$ACCOUNTS>;
    close $ACCOUNTS;
   
    my $all_accounts;
    $all_accounts = \@t_accounts;

    return $all_accounts;
}

sub bkp_dados {
    my ( $self, $zmmailbox, $account, $directory ) = @_;

    $self->{_zmmailbox} = $zmmailbox if defined $zmmailbox;
    $self->{_account}   = $account if defined $account;
    $self->{_directory} = $directory if defined $directory;
    
    if ( -e "$self->{_directory}" and -e "$self->{_directory}/data") {
        open my $BKP, "$self->{_zmmailbox} -z -m $self->{_account} getRestURL '//?fmt=tar\' > '$self->{_directory}/$self->{_account}.tar' |" or die "Comando não encontrado\n";
        close $BKP;
    }
    else {
        mkdir "$self->{_directory}";
        mkdir "$self->{_directory}/data";
        open my $BKP, "$self->{_zmmailbox} -z -m $self->{_account} getRestURL '//?fmt=tar\' > '$self->{_directory}/$self->{_account}.tar' |" or die "Comando não encontrado\n";
        close $BKP;
    }
}

sub handle_passwords {
    my ( $self, $account ) = @_;

    $self->{_account} = $account if defined $account;


    open my $ENCRYPTED, "$self->{_zmprov} -l ga $self->{_account} userPassword |" or die "Comando não encontrado\n";
    my @adicionais = <$ENCRYPTED>;
    close $ENCRYPTED;

    my $detalhes = {};

    for my $dados ( @adicionais ) {
 
        if ( $dados =~ m/name\s(.*)@.*/ ) {
            $self->{_email} = "$1";
        }

        if ( $dados =~ m/userPassword:\s(.*)/ ) {
            $self->{_password} = $1;
        }

        $detalhes->{$self->{_email}}->{password} = $self->{_password};
 
    }
  
    return $detalhes;

}

sub adding_tar_file {
    my ( $self, $account, $password, $domain, $directory ) = @_;

    $self->{_account} = $account if defined $account;
    $self->{_password} = $password if defined $password;
    $self->{_domain} = $domain if defined $domain;
    $self->{_directory} = $directory if defined $directory;

    if ( -e "$self->{_directory}/$self->{_account}" . "\@" . "$self->{_domain}.tar" ) {
        open CREATE, ">", "$self->{_directory}/" . "data/$self->{_account}.pas" or die "Não foi possível criar o arquivo de caixas de entrada\n";
        print CREATE "Password: $self->{_password}\n";
        close CREATE;
        chdir "$self->{_directory}/data";
        open my $tar, "tar rf $self->{_directory}/$self->{_account}\@$self->{_domain}.tar $self->{_account}.pas |" 
            or die "Erro na compressão do arquivo: $self->{_directory}/data/$self->{_account}\n";
        close $tar;
    }
}

sub load_backup_dir {
    my ( $self, $directory ) = @_;

    $self->{_directory} = $directory if defined $directory;

    opendir my $dh, "$self->{_directory}/" or die "Diretório não encontrado: $self->{_directory}\n";
    chomp ( my @list = readdir $dh );
    close $dh;

    my $load_backup = [];

    map { push @{$load_backup}, $_ if m/\@/g } @list;

    return $load_backup;
}

sub _compression {
    my ( $self, $directory, $file ) = @_;
    
    $self->{_directory} = $directory if defined $directory;
    $self->{_file}      = $file if defined $file;

    open my $bzip, "gzip -9 -f $self->{_directory}/$self->{_file} 2>/dev/null |" or die "Não foi possível fazer a compressão\n";
    close $bzip;
    
}

sub restore_password {
    my ( $self, $zmprov, $account, $password ) = @_;

    $self->{_zmprov} = $zmprov if defined $zmprov;
    $self->{_account} = $account if defined $account;
    $self->{_password} = $password if defined $password;

    #open my $restore, "$self->{_zmprov} ma $self->{_account} userPassword '$self->{_password}' |" or die "Erro ao criar a conta\n";
    #my @list = <$restore>;
    #close $restore
    print "$self->{_zmprov} ma $self->{_account} userPassword '$self->{_password}'\n";
}

1;
