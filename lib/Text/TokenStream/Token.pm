package Text::TokenStream::Token;

use v5.12;
use Moo;

use Carp qw(confess);
use Text::TokenStream::Types qw(Identifier Position);
use Types::Standard qw(Bool HashRef Str);

use namespace::clean;

has type => (is => 'ro', isa => Identifier, required => 1);
has text => (is => 'ro', isa => Str, required => 1);
has captures => (is => 'ro', isa => HashRef[Str], default => sub { +{} });
has cuddled => (is => 'ro', isa => Bool, default => 0);
has position => (is => 'ro', isa => Position, required => 1);

sub text_for_matching { shift->text }

sub matches {
    my ($self, $target) = @_;
    return $self->text_for_matching eq $target if Str->check($target);
    return !!grep $target->($_), $self;
}

sub repr {
    my ($self, $indent) = @_;

    return sprintf '%sToken type=%s position=%d cuddled=%d text=[%s]',
        $indent // '', $self->type, $self->position, $self->cuddled, $self->text;
}

1;
__END__
