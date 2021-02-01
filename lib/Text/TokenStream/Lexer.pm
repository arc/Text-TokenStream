package Text::TokenStream::Lexer;

use v5.12;
use Moo;

use Carp qw(confess);
use List::Util qw(pairmap);
use Text::TokenStream::Types qw(Identifier LexerRule);
use Types::Standard qw(ArrayRef CycleTuple ScalarRef Str);

use namespace::clean;

has rules => (
    is => 'ro',
    isa => CycleTuple[Identifier, LexerRule],
    required => 1,
);

has whitespace => (
    is => 'ro',
    isa => ArrayRef[LexerRule],
    default => sub { [] },
);

has _whitespace_rx => (is => 'lazy', init_arg => undef, builder => sub {
    my ($self) = @_;
    my @whitespace = map ref() ? $_ : quotemeta, @{ $self->whitespace }
        or return qr/(*FAIL)/;
    local $" = '|';
    return qr/^(?:@whitespace)/;
});

has _rules_rx => (is => 'lazy', init_arg => undef, builder => sub {
    my ($self) = @_;
    my @annotated_rules = pairmap { qr/$b(*MARK:$a)/ }
        pairmap { $a => (ref $b ? $b : quotemeta $b) }
        @{ $self->rules }
            or return qr/(*FAIL)/;
    local $" = '|';
    qr/^(?|@annotated_rules)/;
});

sub skip_whitespace {
    my ($self, $str_ref) = @_;
    (ScalarRef[Str])->assert_valid($str_ref);

    my $ret = 0;
    my $whitespace_rx = $self->_whitespace_rx;
    $ret = 1 while $$str_ref =~ s/$whitespace_rx//;

    return $ret;
}

sub next_token {
    my ($self, $str_ref) = @_;
    (ScalarRef[Str])->assert_valid($str_ref);

    my $saw_whitespace = $self->skip_whitespace($str_ref);

    return undef if !length $$str_ref;

    if ($$str_ref !~ $self->_rules_rx) {
        my $text = substr $$str_ref, 0, 30;
        confess("No matching rule; next text is: $text");
    }

    my $type = our $REGMARK;
    my $captures = { %+ };
    my $text = substr($$str_ref, 0, $+[0], '');

    return {
        type => $type,
        captures => $captures,
        text => $text,
        cuddled => 0+!$saw_whitespace,
    };
}

1;
__END__
