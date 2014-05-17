package Config::DWIM::Hashject;


"Hashject is a really stupid name"
__END__

=head1 DESCRIPTION

  Config::DWIM::Hashject - An object interface to hash keys

=head1 SYNOPSIS

    use Config::DWIM::Hashject;
    my $hashject = Config::DWIM::Hashject->new({
      foo => 'at foo',
      bar => 'at bar',
      foo__bar => 'at foo__bar',
      'foo:_-:bar' => 'at foo:_-:bar',
    });
    print $hashject->foo # at foo
    print $hashject->bar # at bar
    print join(",",$hashject->foo_bar) # at foo_bar,at foo_bar

=head2 OBJECT NAME FOLDING RULES

1. All characters that are not alphabetical are replaced with underscores.
2. Repeated underscores are replaced with a singular underscore
3. It is conceivable that keys will clash. In this case, we return an ArrayRef of both possibilities. These are returned in insertion order to the hashject.
4. To unambiguously refer to an item, call C<get($key)>.

=head1 METHODS

=head2 get($key: Str) => Any

Returns the entry from the hashject with the exactly matching key C<$key>.

=head2 keys() => List[Str]

Returns the list of keys in the hashject.

