package Text::TokenStream;

use v5.12;
use Moo;

use List::Util qw(max);
use Types::Standard qw(ArrayRef Int ScalarRef Str);
use Text::TokenStream::Token;
use Text::TokenStream::Types qw(Lexer Position TokenClass);

use namespace::clean;

has input => (is => 'ro', isa => Str, required => 1);

has lexer => (
    is => 'ro',
    isa => Lexer,
    required => 1,
    handles => { next_lexer_token => 'next_token' },
);

has token_class => (
    is => 'lazy',
    isa => TokenClass,
    builder => sub { 'Text::TokenStream::Token' },
);

has _pending => (is => 'ro', isa => ArrayRef, default => sub { [] });

has _input_ref => (is => 'lazy', isa => ScalarRef[Str], builder => sub {
    my ($self) = @_;
    my $copy = $self->input;
    return \$copy;
});

has current_position => (
    is => 'ro',
    writer => '_set_current_position',
    isa => Position,
    default => 0,
    init_arg => undef,
);

with qw(Text::TokenStream::Role::Stream);

# Only to be called if the buffer has at least one token
sub _next {
    my ($self) = @_;
    my $tok = shift @{ $self->_pending };
    $self->_set_current_position( $tok->position + length($tok->text) );
    return $tok;
}

sub next {
    my ($self) = @_;
    $self->fill(1) or return undef;
    return $self->_next;
}

sub fill {
    my ($self, $n) = @_;

    my $input_ref = $self->_input_ref;
    my $input_len = length($self->input);

    my $pending = $self->_pending;
    while (@$pending < $n) {
        my $tok = $self->next_lexer_token($input_ref) // return 0;
        my $position = $input_len - length($$input_ref) - length($tok->{text});
        push @$pending, $self->create_token(%$tok, position => $position);
    }

    return 1;
}

sub create_token {
    my ($self, %data) = @_;
    return $self->token_class->new(%data);
}

sub peek {
    my ($self) = @_;
    $self->fill(1) or return undef;
    return $self->_pending->[0];
}

sub skip_optional {
    my ($self, $target) = @_;
    my $tok = $self->peek // return 0;
    return 0 if !$tok->matches($target);
    $self->_next;
    return 1;
}

sub looking_at {
    my ($self, @targets) = @_;

    $self->fill(scalar @targets) or return 0;

    my $pending = $self->_pending;
    for my $i (0 .. $#targets) {
        return 0 if !$pending->[$i]->matches($targets[$i]);
    }

    return 1;
}

sub next_of {
    my ($self, $target, $where) = @_;
    my $tok = $self->peek
        // $self->err(join ' ', "Missing token", grep defined, $where);
    $self->token_err($tok, join ' ', "Unexpected", $tok->type, "token", grep defined, $where)
        if !$tok->matches($target);
    return $self->_next;
}

sub _err {
    my ($self, $token, @message) = @_;
    my $position = $token ? $token->position : $self->current_position;
    my $marker = '^' x max(6, map length($_->text), grep defined, $token);
    my $input = $self->input;
    my $prefix = substr $input, 0, $position;
    (my $line_prefix = $prefix) =~ s/^.*\n//s;
    (my $space_prefix = $line_prefix) =~ tr/\t/ /c;
    (my $line_suffix = substr $input, $position) =~ s/\r?\n.*//s;
    my $line_number = 1 + ($prefix =~ tr/\n//);
    my $column_number = 1 + length $line_prefix;
    @message = q[Something's wrong] if !@message;
    my $message = join '', (
        "SORRY! Line $line_number, column $column_number: ", @message, "\n",
        $line_prefix, $line_suffix, "\n",
        $space_prefix, $marker, "\n",
    );
    die $message;
}

sub token_err { shift->_err(       @_) }
sub       err { shift->_err(undef, @_) }

1;
__END__
