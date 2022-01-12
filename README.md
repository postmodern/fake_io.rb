# fake_io

[![CI](https://github.com/postmodern/fake_io.rb/actions/workflows/ruby.yml/badge.svg)](https://github.com/postmodern/fake_io.rb/actions/workflows/ruby.yml)
[![Gem Version](https://badge.fury.io/rb/fake_io.svg)](https://badge.fury.io/rb/fake_io)

* [Source](https://github.com/postmodern/fake_io.rb)
* [Issues](https://github.com/postmodern/fake_io.rb/issues)
* [Documentation](http://rubydoc.info/gems/fake_io/frames)

## Description

{FakeIO} is a mixin module for creating fake [IO]-like classes.

## Features

* Supports (almost) all of the usual [IO] methods by default.
* Emulates buffered I/O.
* UTF-8 aware.
* Can be included into any Class.
* Zero dependencies.

## Requirements

* [Ruby] >= 1.9.1

[Ruby]: https://www.ruby-lang.org/

## Install

```shell
$ gem install fake_io
```

### gemspec

```ruby
gem.add_dependency 'fake_io', '~> 1.0'
```

### Gemfile

```ruby
gem 'fake_io', '~> 1.0'
```

## Examples

```ruby
require 'fake_io'

class FakeFile

  include FakeIO

  def initialize(chunks=[])
    @index = 0
    @chunks = chunks

    io_initialize
  end

  protected

  def io_read
    unless (block = @chunks[@index])
      raise(EOFError,"end of stream")
    end

    @index += 1
    return block
  end

  def io_write(data)
    @chunks[@index] = data
    @index += 1

    return data.length
  end

end

file = FakeFile.new(["one\ntwo\n", "three\nfour", "\n"])
file.readlines
# => ["one\n", "two\n", "three\n", "four\n"]
```

## Copyright

Copyright (c) 2021 Hal Brodigan

See {file:LICENSE.txt} for details.

[IO]: https://rubydoc.info/stdlib/core/IO
