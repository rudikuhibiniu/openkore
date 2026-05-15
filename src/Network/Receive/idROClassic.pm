########################################################################
# idROClassic (RevoclassicR) Custom Receive Module
# Handles packet 0xD3A7 - custom login success response from gnjoy.id
# Protocol reverse-engineered from packet capture analysis
########################################################################
package Network::Receive::idROClassic;

use strict;
use base qw(Network::Receive::tRO);
use Log qw(message debug);

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new(@_);

    # Custom login success packet D3A7 format (body after 2-byte packet ID):
    # v=length(2) + sessionID(4) + accountID(4) + sessionID2(4) +
    # lastLoginIP(4) + lastLoginTime(26) + sex(1) + token(17) + serverInfo(*)
    my %packets = (
        'D3A7' => ['account_server_info',
            'v a4 a4 a4 a4 a26 C a17 a*',
            [qw(len sessionID accountID sessionID2 lastLoginIP lastLoginTime accountSex token serverInfo)]],
    );
    $self->{packet_list}{$_} = $packets{$_} for keys %packets;

    return $self;
}

1;
