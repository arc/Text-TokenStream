package Text::TokenStream::Role::Stream;

use v5.12;
use Moo::Role;

use namespace::clean;

requires qw(
    current_position
    err
    fill
    looking_at
    next
    next_of
    peek
    skip_optional
    token_err
);

sub collect_all {
    my ($self) = @_;

    my @ret;
    while (my $tok = $self->next) {
        push @ret, $tok;
    }

    return @ret;
}

sub collect_upto {
    my ($self, $target) = @_;

    my @ret;
    while (my $tok = $self->peek) {
        last if $tok->matches($target);
        push @ret, $self->next;
    }

    return @ret;
}

1;
__END__
