requires 'perl', '>= 5.012';

requires 'Carp';
requires 'List::Util', '>= 1.29';
requires 'Moo';
requires 'Moo::Role';
requires 'Type::Library';
requires 'Type::Utils';
requires 'Types::Common::Numeric';
requires 'Types::Standard';
requires 'namespace::clean';

on 'test' => sub {
    requires 'Test::Fatal';
    requires 'Test::More';
    requires 'Test::Warnings';
};
