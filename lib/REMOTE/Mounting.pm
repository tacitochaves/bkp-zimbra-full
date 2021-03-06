package REMOTE::Mounting;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

# method to read and delivers remote access settings to the backup server
sub _read {
    my ( $self, $file ) = @_;

    $self->{_file} = $file if defined $file;

    open my $fh, '<', "$self->{_file}" or die "[error] file not found!\n";
    my @list = <$fh>;
    close $fh;

    for (@list) {
        chomp;

        my $line = $_;

        next if $line =~ m/^#/g;

        my ( $key, $val ) = split( /:/, $line );

        $self->{_config}->{$key} = $val;
    }

    return $self->{_config};
}

# just get the IP of the backup server on the local network
sub _parse {
    my ( $self, $dst ) = @_;

    $self->{_Destination} = $dst if defined $dst;
    $self->{_Destination} = $1 if $self->{_Destination} =~ m/^((\d{1,3}\.){3}\d+)/;

    return $self->{_Destination} if defined $dst;;
}

# checks if the share is already mounted on the server
sub check_assembly {
    my ( $self, $dir ) = @_;

    $self->{_assembly} = $dir if defined $dir;

    open my $df, "df -h |" or die "Error while checking the mounted directories!\n";
    my @list = <$df>;
    close $df;

    for my $l ( @list ) {
        return "is mounted" if $l =~ m/$self->{_assembly}/gi;
    }
}

# riding the remote server backup directory
sub mount {
    my ( $self, $config ) = @_;

    $self->{_username} = $config->{Username} if defined $config->{Username};
    $self->{_password} = $config->{Password} if defined $config->{Password};
    $self->{_destination} = $config->{Destination} if defined $config->{Destination};
    $self->{_directory} = $config->{Directory} if defined $config->{Directory};

    open my $mount, "mount -t cifs -o user=$self->{_username},password=$self->{_password} \/\/$self->{_destination} $self->{_directory} |" or die "Error! Host Unreachable\n";
    my @a = (<$mount>);
    close($mount);

}

# disassembles sharing
sub umount {
    my ( $self, $dir ) = @_;

    $self->{_directory} = $dir if defined $dir;

    open my $umount, "umount $self->{_directory} |" or die "[error] Directory not mounted\n";
    my @l = <$umount>;
    close $umount;

    return "umounted";
}

1;
