package Text::TokenStream::Types;

use v5.12;
use warnings;

use Type::Utils qw(as class_type coerce declare from role_type where via);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Standard qw(ClassName Str RegexpRef);

use Type::Library -base, -declare => qw(
    Identifier
    Lexer
    LexerRule
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

declare LexerRule, as RegexpRef|Str;

role_type Stream, { role => 'Text::TokenStream::Role::Stream' };

class_type Lexer, { class => 'Text::TokenStream::Lexer' };
class_type Token, { class => 'Text::TokenStream::Token' };
class_type TokenStream, { class => 'Text::TokenStream' };

1;
__END__
