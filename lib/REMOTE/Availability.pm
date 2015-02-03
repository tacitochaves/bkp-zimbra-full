package REMOTE::Availability;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

# method that tests whether the host is accessible via local network
sub check_host {
    my ( $self, $host ) = @_;

    $self->{_host} = $host if defined $host;

    open my $ping, "ping -c3 $self->{_host} |" or die "Destination Host Unreachable\n";
    my @result = <$ping>;
    close $ping;

    map { $self->{_loss} = $1 if m/(\d+)%/g } @result;

    return $self->{_loss};
}

1;
