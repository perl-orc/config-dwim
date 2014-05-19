package Config::DWIM;

use 5.14.0;
use strict;
use warnings FATAL => 'all';

use Carp qw/ cluck /;

use Config::DWIM::Utility;
use Config::DWIM::Utility::Merge;
use Config::Any;
use Path::Tiny qw(path);
use Data::Dumper 'Dumper';

our $VERSION = '0.01';

sub _process {
  my ($self, @args) = @_;
  return Config::DWIM::Utility::Merge::process(@args);
}

sub _merge {
  my ($self, @args) = @_;
  return Config::DWIM::Utility::reduce(
    sub {Config::DWIM::Utility::Merge::merge(@args);},
    @args
  );
}

sub _include_path_stems {
  my ($self, $library, $stems) = @_;
  map {
    my $p = "${_}/${library}";
    # warn "Pushing to search path by stem path: $p";
    $p;
  } @$stems;
}
sub _include_path_include {
  my ($self, $library, $stems) = @_;
  my $include_path = path($self->{'include_path'});
  my $p = "@{[${include_path}->absolute]}/${library}";
  # warn "Pushing to search path by include path: $p";
  $p;
}

sub _include_path_stem_includes {
  my ($self, $library, $stems) = @_;
  my $include_path = $self->{'include_path'};
  if ($include_path) {
    $include_path = path($include_path);
    map {
      if ($include_path->absolute eq $include_path) {
        # warn "Absolute path found, not pushing root with stem: $include_path";
      } else {
        my $p = "${_}/${include_path}/${library}";
        # warn "absolute: " . $include_path->absolute;
        # warn "relative: " . $include_path;
        # warn "library: " . $library;
        # warn "Pushing to search path by stem and relative include path: $p";
        $p;
      }
    } @$stems;
  }
}

sub dedupe {
  my %foo;
  @foo{@_} = ();
  sort {$a cmp $b} keys %foo;
}

sub _get_include_paths {
  my ($self, $include, $stems) = @_;
  my @stem_roots = dedupe(map {
    path($_)->parent->absolute;
  } @$stems);
  # warn Dumper [@stem_roots];
  my @include_paths;
  $include = path($include);
  push @include_paths,
    $self->_include_path_include($include, [@stem_roots]),
    $self->_include_path_stems($include, [@stem_roots]),
    $self->_include_path_stem_includes($include, [@stem_roots]);
  return @include_paths;
}

sub _get_include {
  my ($self, $include, $stems) = @_;
  my @include_paths = $self->_get_include_paths($include, $stems);
  my $ret = $self->read_stems(map {"".$_} @include_paths);
  if (!$ret) {
    # warn "Include failed: $include:" . Dumper [@include_paths];
  }
  return $ret;
}

sub _include_merge {
  my ($self,@things) = @_;
  # warn "include_merge: " . Dumper [@things];
  my $ret;
  my $include_merger = ($self->{'include_merger'} || 'r');
  if ($include_merger eq 'r') {
#    cluck "Popping";
    $ret = pop @things;
  } elsif ($include_merger eq 'l') {
     # warn "Shifting";
    $ret = shift @things;
  } else {
    # warn "Defaulting";
    # Default to size
    $ret = $self->_merge(@things);
  }
  # warn "Included: " . Dumper $ret;
  return $ret;
}

sub _includes {
  # warn "includes: @_";
  my ($self, $thing, $stems) = @_;
  return () if !$thing;
  return [map $self->_includes($_),@$thing] if ref($thing) eq 'ARRAY';
  return $thing if ref($thing) ne 'HASH';

  my %new;
  my $include;
  # We have to mark now and sweep later so we've transformed local children
  # before we try the include. Otherwise we're left in a non-atomic state
  foreach my $k (keys %$thing) {
    if ($k eq $self->{'include_key'}) {
      # warn "Found include key $k";
      $include = $k;
    } else {
      $new{$k} = $self->_includes($thing->{$k},$stems);
      # warn Dumper $thing;
      # warn '$new{'.$k. '}: '.Dumper($new{$k});
    }
  }
  if ($include) {
    # warn "Acting on include key $include:";
    my $included = $self->_get_include($thing->{$include},$stems);
    return $self->_include_merge({%new}, $included);
  }
  return {%new};
}

sub _preprocess {
  my ($self, $configs, $stems) = @_;
#  cluck @$configs;
  my $merged = $self->_merge(@$configs);
  # warn "Merged: " . ($merged ? Dumper($merged) : '');
  my $included = $self->_includes($merged, $stems);
  # warn "Included: " . ($included ? Dumper($included) : '');
  $included;
}

sub read_stems {
  my ($self, @stems) = @_;
  my @configs = values %{Config::Any->load_stems({
    stems => [@stems],
    use_ext => 1,
    flatten_to_hash => 1,
  })};
  # warn "Read stems : " . Dumper [@configs];
  return $self->_preprocess([@configs],[@stems]);
}

sub process {
  my ($self, @stems) = @_;
  my $config = $self->read_stems;
  $self->_process($config);
}

sub new {
  my ($class, %kwargs) = @_;
  bless {%kwargs}, $class;
}

q(I think you know what I mean)
__END__

=head1 DESCRIPTION

Config::DWIM - Config that Does What I Mean

=head1 SYNOPSIS

    use Config::DWIM;
    # We'll use a key 'environment' to load in a config
    my $conf = Config::DWIM->new(
      include_key => 'environment',
      include_path => 'environments',
      include_merger => 'r'
    );
    # Find 'config.yml', 'config.cnf', 'config.json' etc.
    my config = $conf->read_stems('config');
    # Get the same back as a L<Config::DWIM::Hashject>
    $config = $conf->process('config');

=head1 HOW DOES IT WORK?

It's a thin wrapper over Config::Any.

You probably want this:

    use Config::DWIM;
    my $conf = Config::DWIM->new->process('config');
    print $conf->deeply->nested->key[2];

=head1 METHODS

=head2 new(%kwargs) => Config::DWIM

Creates a new Config::DWIM. Keyword args are:

  include_key - the key to trigger an include
  include_path - a directory path that will be searched for include files

=head2 process(@stems) => Hashject

Calls C<read_stems(@stems)> and then postprocesses for more convenient access.

Stems are turned into L<Config::DWIM::Hashject> objects

=head2 read_stems(@stems) => HashRef[Any]

This function takes file stems, parts of filenames without the extension (e.g. C<config> means C<config.yml>, C<config.json> etc.)

At time of writing, the following config file mappings are in order for L<Config::Any>, on which this module is based:

     ini: .ini (requires Config::Tiny)
    json: .json (requires JSON::XS, JSON::PP, JSON::DWIW or JSON::Syck)
    perl: .pl .perl
     xml: .xml (requires XML::Simple, XML::NamespaceSupport)
    yaml: .yml .yaml (requires YAML::XS, YAML or YAML::Syck)

Each stem is read and the config is turned into a hashref. Configs are then merged to produce a singular hashref. The following rules are applied:

1. Configs are merged two at a time in a reduce()/foldl()-like pattern.
2. Keys from each config are compared as hashrefs. There is no guaranteed ordering.
3. We apply the L<COMPARISON RULES> to the key and the values from the left and right for that key.
4. If the key matches the C<include_key>, we then apply the L<INCLUDE RULES>

=head3 COMPARISON RULES

1.'Bigger' datatypes always win. Hashrefs are bigger than Arrayrefs, Arrayrefs are bigger than Scalars, defined is bigger than undefined. If one side is bigger than the other, it wins.
<At this point they are the same type>
2. If the data are not HashRefs, the right hand side wins.
3. Reapply the rules to the hashref

=head3 INCLUDE RULES

1. If the include is a hashref, its values are turned into an arrayref and we proceed as if this were the input
2. If the include is an arrayref, we include each string item in turn and then apply the L<MERGE RULES> above
3. The right hand side wins. The right hand side include file is included.
4. Keys at the toplevel are then merged per L<MERGE RULES> with the HashRef in which the include directive resides

=head1 AUTHOR

James Edward Daniel, C<< <cpan at dysfunctionalprogramming.org> >>

=head1 CAVEATS

Hashjects (and thus the return of process()) leak packages, one per hashref instantiated. Minor if you're using it for the intended purpose, but if you're abusing it...

This module doesn't correctly process includes. You probably won't notice, but if some of the stems are in different directories, then ALL stems are used as the base path from which to append the relative prefix.

=head1 BUGS

Please report any bugs or feature requests through the github issues tracker L<https://github.com/dysfunctionalprogramming/config-dwim/issues/new>

=head1 READING THIS PAGE ELSEWHERE

You can use perldoc to read this in your terminal emulator:

    perldoc Config::DWIM

You can also read this on metacpan: L<http://metacpan.org/pod/Config::DWIM>

You could even read this on github, where development happens: L<https://github.com/dysfunctionalprogramming/config-dwim/>

=head1 ACKNOWLEDGEMENTS

This module is dedicated to the beauty of the craft of programming, which we so rarely have time for these days.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 James Edward Daniel

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
