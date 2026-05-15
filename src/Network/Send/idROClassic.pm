########################################################################
# idROClassic (RevoclassicR) Custom Send Module
# Implements packet 0xF020 - custom plaintext login for gnjoy.id
# Protocol reverse-engineered from packet capture analysis
########################################################################
package Network::Send::idROClassic;

use strict;
use base qw(Network::Send::tRO);
use Globals qw(%config);
use Log qw(debug);

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new(@_);

    # Override master_login with custom F020 format
    # Format: fixed_header(4) + username(24) + password(24) +
    #         isGravityID(1) + hwid(19 raw) + pad(45) + ipv6(39 raw) + trail(7)
    # NOTE: use 'a' not 'Z' for hwid/ipv6 to avoid NUL-truncation of last byte
    my %packets = (
        'F020' => ['master_login',
            'a4 Z24 Z24 C a19 a45 a39 a7',
            [qw(custom_header username password isGravityID hwid pad45 ipv6addr trail)]],
        # Custom char server game_login packet (standard tRO uses 0x0275, this server uses 0xC4D9)
        'C4D9' => ['game_login',
            'a4 a4 a4 v C',
            [qw(accountID sessionID sessionID2 userLevel accountSex)]],
    );
    $self->{packet_list}{$_} = $packets{$_} for keys %packets;
    $self->{packet_lut}{master_login} = 'F020';
    $self->{packet_lut}{game_login}   = 'C4D9';
    $self->{packet_lut}{item_use}     = '0439';

    return $self;
}

sub reconstruct_master_login {
    my ($self, $args) = @_;

    # Fixed header bytes after packet ID (observed: 01 00 00 80)
    $args->{custom_header} = "\x01\x00\x00\x80";

    # isGravityID flag
    $args->{isGravityID} = 1;

    # Hardware ID - configurable, default from packet capture
    $args->{hwid} = $config{idroClassicHWID} || '0045-45FB-FB13-13E2';

    # 45 bytes of zero padding
    $args->{pad45} = "\x00" x 45;

    # IPv6 address string (39 bytes) - auto-detect or configurable
    my $ipv6 = $config{idroClassicIPv6} || _detect_ipv6();
    $args->{ipv6addr} = $ipv6;

    # 7 bytes trailing zeros
    $args->{trail} = "\x00" x 7;

    # Password is sent PLAINTEXT - no Rijndael, no MD5
    # username and password fields are used directly by the pack format
    debug "idROClassic login: user=$args->{username} hwid=$args->{hwid} ipv6=$args->{ipv6addr}\n";
}

sub _detect_ipv6 {
    my $ipv6 = '';
    eval {
        my @lines = `netsh interface ipv6 show addresses 2>nul`;
        for (@lines) {
            if (/\s+(2[0-9a-fA-F]{3}:[^\s]+)\s/) {
                $ipv6 = $1;
                last;
            }
        }
    };
    return $ipv6 || '';
}

1;
