package Text::TokenStream::Types;

use v5.12;
use warnings;

use Type::Utils qw(as class_type declare role_type where);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Standard qw(ClassName Str);

use Type::Library -base, -declare => qw(
    Identifier
    Lexer
    Position
    Stream
    Token
    TokenClass
    TokenStream
);

declare Identifier, as Str, where { /^ (?![0-9]) [0-9a-zA-Z_]+ \z/x };
declare Position, as PositiveOrZeroInt;

declare TokenClass, as ClassName,
    where { $_->isa('Text::TokenStream::Token') };

role_type Stream, { role => 'Text::TokenStream::Role::Stream' };

class_type Lexer, { class => 'Text::TokenStream::Lexer' };
class_type Token, { class => 'Text::TokenStream::Token' };
class_type TokenStream, { class => 'Text::TokenStream' };

1;
__END__
