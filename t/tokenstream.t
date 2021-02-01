#!perl

use v5.12;
use warnings;

use Test::Fatal qw(exception);
use Test::More;
use Test::Warnings qw(had_no_warnings :no_end_test);

use Text::TokenStream;
use Text::TokenStream::Lexer;

my $lexer = Text::TokenStream::Lexer->new(
    whitespace => [qr/\s+/],
    rules => [
        keyword => qr/(?:break|case|continue|do|else|goto|if|switch|while)\b/,
        identifier => qr/(?!\d) \w+/x,
        opening => qr/[\(\[\{]/,
        closing => qr/[\}\]\)]/,
        oct => qr/0[0-7]*\b/,
        hex => qr/0[xX][\da-f]+\b/,
        dec => qr/[1-9]\d*\b/,
        str => qr/" (?<contents> [^\"\\]*) "/x,
        sym => qr/[^\s\w]+/,
    ],
);

{
    package Test_::Token;
    use Moo;
    extends 'Text::TokenStream::Token';
    no Moo;
}

sub token {
    my ($type, $text, $position, $cuddled, %captures) = @_;
    return Test_::Token->new(
        type => $type,
        text => $text,
        position => $position,
        cuddled => $cuddled || 0,
        captures => \%captures,
    );
}

{
    my $input = <<'EOF';
{
    if (x == "foo" || n >= arr[0x1f]) {
        break;
    }
}
EOF
    my $stream = Text::TokenStream->new(
        input => $input,
        lexer => $lexer,
        token_class => 'Test_::Token',
    );
    # Also tests the token_class feature:
    is_deeply($stream->next, token(opening => '{', 0, 1),
        'get first token');
    is($stream->input, $input, 'next leaves input unchanged');

    is_deeply($stream->next, token(keyword => 'if', 6),
        'get second token');

    is($stream->current_position, 8, 'current stream position');

    is($stream->peek, $stream->peek, 'peek returns same object each time');
    is_deeply($stream->peek, token(opening => '(', 9),
        'peek looks ahead one token');
    is($stream->current_position, 8,
        'current stream position unchanged after peek');

    ok($stream->looking_at('('), 'looking_at one item');
    is($stream->current_position, 8,
        'current stream position unchanged after looking_at');

    ok($stream->looking_at('(', sub { $_->type eq 'identifier' }),
        'looking_at two items');

    is_deeply($stream->next, token(opening => '(', 9),
        'get third token');

    my @got = $stream->collect_upto('||');
    is_deeply(\@got, [
        token(identifier => 'x', 10, 1),
        token(sym => '==', 12),
        token(str => '"foo"', 15, 0, contents => 'foo'),
    ], 'collect_upto stops appropriately');
}

had_no_warnings();
done_testing();
