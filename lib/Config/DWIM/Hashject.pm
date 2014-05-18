package Config::DWIM::Hashject;

use Scalar::Util qw(blessed);
use Data::Dumper qw(Dumper);

sub _fold {
  my $name = shift;
  $name =~ s/[^a-z_]+/_/g;
  $name =~ s/__+/_/g;
  $name;
}

sub _gen_accessor {
  my ($self, $name, $constant) = @_;
  *{blessed($self)."::$name"} = sub {$constant};
}

sub is_package_taken {
  return !!%{(shift)."::"};
}

sub _rebless {
  my ($self,$package) = @_;
  return bless {%$self}, $package;
}

sub _try_for_package {
  my ($self, $package) = @_;
  return 0 if is_package_taken($package);
  return _rebless($self,$package);
}

sub _gen_package {
  my $self = shift;
  my $root = (blessed($self)."::gensym");
  my $counter = do {
    no warnings 'uninitialized';
    # -3: AUTOLOAD, ISA, DESTROY
    keys( %$self ) - 3;
  };
  my $ret;
  for( ; !$ret ; $counter++) {
    my $name = $root . $counter;
    $ret = $self->_try_for_package($name);
  }
  {
    no strict 'refs';
    @{(blessed $ret)."::ISA"} = qw(Config::DWIM::Hashject);
  }
  $ret;
}

sub _gen_accessors {
  my $self = shift;
  my %taken;
  foreach my $k (keys %$self) {
    my $folded = _fold($k);
    if (defined($taken{$folded})) {
      $taken{$folded} = [(ref($taken{$folded}) eq 'ARRAY' ? @{$taken{$folded}} : $taken{$folded}), $self->{$k}];
    } else {
      $taken{$folded} = $self->{$k};
    }
  }
  foreach my $k (keys %taken) {
    my $val = $taken{$k};
    my $name = _fold($k);
    $self->_gen_accessor($name, $val);
  }
  $self;
}

sub _setup {
  shift->_gen_package->_gen_accessors;
}

sub new {
  my ($class,$hashref) = @_;
  bless $hashref, $class;
  $hashref->_setup;
}

sub get {
  my ($self, $key) = @_;
  return $self->{$key};
}

sub keys {
  return keys %{shift()};
}

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

=head1 CAVEAT

This module leaks memory very slowly. New packages will be allocated as a hack to generate accessors without using AUTOLOAD (which is a more horrible hack). These packages will never be reaped. If you're going to regularly parse files using this during a process, you'll want to occasionally reap the process (good anyway, since most modules are badly behaved). If you're reading a config once per process run, this will not be a problem at all.
