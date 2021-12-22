#
# The {FakeIO} module provides an API for communicating with controlled
# resources, that is still compatible with the standard
# [IO](http://rubydoc.info/stdlib/core/IO) class.
#
# To utilize the {FakeIO} module, simply include it into a class and define
# either {#io_read} and/or {#io_write}, to handle the reading and writting
# of data.
#
# The {#io_open} method handles optionally opening and assigning the
# file descriptor for the IO stream. The {#io_close} method handles
# optionally closing the IO stream.
#
module FakeIO

  include Enumerable
  include File::Constants

  # The position within the IO stream
  attr_reader :pos

  # The end-of-file indicator
  attr_reader :eof

  alias eof? eof

  # The file descriptor
  attr_reader :fd

  alias fileno fd
  alias to_i fd

  #
  # Initializes the IO stream.
  #
  def initialize
    @read   = true
    @write  = true
    @closed = true

    @binmode = false
    @tty     = false

    open
  end

  alias tell pos

  #
  # Iterates over each block within the IO stream.
  #
  # @yield [block]
  #   The given block will be passed each block of data from the IO
  #   stream.
  #
  # @yieldparam [String] block
  #   A block of data from the IO stream.
  #
  # @return [Enumerator]
  #   If no block is given, an enumerator object will be returned.
  #
  # @raise [IOError]
  #   The stream is closed for reading.
  #
  def each_chunk
    return enum_for(__method__) unless block_given?

    unless @read
      raise(IOError,"closed for reading")
    end

    # read from the buffer first
    yield read_buffer unless empty_buffer?

    until @eof
      begin
        # no data currently available, sleep and retry
        until (chunk = io_read)
          sleep(1)
        end
      rescue EOFError
        break
      end

      unless chunk.empty?
        @pos += chunk.bytesize
        yield chunk
      else
        # short read
        @eof = true
      end
    end
  end

  #
  # Reads data from the IO stream.
  #
  # @param [Integer, nil] length
  #   The maximum amount of data to read. If `nil` is given, the entire
  #   IO stream will be read.
  #
  # @param [#<<] buffer
  #   The optional buffer to append the data to.
  #
  # @return [String]
  #   The data read from the IO stream.
  #
  def read(length=nil,buffer=nil)
    bytes_remaining = (length || Float::INFINITY)
    result = String.new

    each_chunk do |chunk|
      if bytes_remaining < chunk.bytesize
        fragment  = chunk.byteslice(0,bytes_remaining)

        remaining_length = chunk.bytesize - bytes_remaining
        remaining_data   = chunk.byteslice(bytes_remaining,remaining_length)

        result << fragment
        append_buffer(remaining_data)
        break
      else
        result << chunk
        bytes_remaining -= chunk.bytesize
      end

      # no more data to read
      break if bytes_remaining == 0
    end

    unless result.empty?
      buffer << result if buffer
      return result
    end
  end

  alias sysread read
  alias read_nonblock read

  #
  # Reads partial data from the IO stream.
  #
  # @param [Integer] length
  #   The maximum amount of data to read.
  #
  # @param [#<<] buffer
  #   The optional buffer to append the data to.
  #
  # @return [String]
  #   The data read from the IO stream.
  #
  # @see #read
  #
  def readpartial(length,buffer=nil)
    read(length,buffer)
  end

  #
  # Reads a byte from the IO stream.
  #
  # @return [Integer]
  #   A byte from the IO stream.
  #
  # @note
  #   Only available on Ruby > 1.9.
  #
  def getbyte
    if (c = read(1))
      c.bytes.first
    end
  end

  #
  # Reads a character from the IO stream.
  #
  # @return [String]
  #   A character from the IO stream.
  #
  def getc
    read(1)
  end

  #
  # Un-reads a byte from the IO stream, append it to the read buffer.
  #
  # @param [Integer, String] byte
  #   The byte to un-read.
  #
  # @return [nil]
  #   The byte was appended to the read buffer.
  #
  # @note
  #   Only available on Ruby > 1.9.
  #
  def ungetbyte(byte)
    byte = case byte
           when Integer then byte.chr
           else              byte.to_s
           end

    prepend_buffer(byte)
    return nil
  end

  #
  # Un-reads a character from the IO stream, append it to the
  # read buffer.
  #
  # @param [#to_s] char
  #   The character to un-read.
  #
  # @return [nil]
  #   The character was appended to the read buffer.
  #
  def ungetc(char)
    prepend_buffer(char.to_s)
    return nil
  end

  #
  # Reads a string from the IO stream.
  #
  # @param [String] separator
  #   The separator character that designates the end of the string
  #   being read.
  #
  # @return [String]
  #   The string from the IO stream.
  #
  def gets(separator=$/)
    # increment the line number
    @lineno += 1

    # if no separator is given, read everything
    return read if separator.nil?

    line = String.new

    while (c = read(1))
      line << c

      break if c == separator # separator reached
    end

    if line.empty?
      # a line should atleast contain the separator
      raise(EOFError,"end of file reached")
    end

    return line
  end

  #
  # Reads a character from the IO stream.
  #
  # @return [Integer]
  #   The character from the IO stream.
  #
  # @raise [EOFError]
  #   The end-of-file has been reached.
  #
  # @see #getc
  #
  def readchar
    unless (c = getc)
      raise(EOFError,"end of file reached")
    end

    return c
  end

  #
  # Reads a byte from the IO stream.
  #
  # @return [Integer]
  #   A byte from the IO stream.
  #
  # @raise [EOFError]
  #   The end-of-file has been reached.
  #
  def readbyte
    unless (c = read(1))
      raise(EOFError,"end of file reached")
    end

    return c.bytes.first
  end

  #
  # Reads a line from the IO stream.
  #
  # @param [String] separator
  #   The separator character that designates the end of the string
  #   being read.
  #
  # @return [String]
  #   The string from the IO stream.
  #
  # @raise [EOFError]
  #   The end-of-file has been reached.
  #
  # @see #gets
  #
  def readline(separator=$/)
    unless (line = gets(separator))
      raise(EOFError,"end of file reached")
    end

    return line
  end

  #
  # Iterates over each byte in the IO stream.
  #
  # @yield [byte]
  #   The given block will be passed each byte in the IO stream.
  #
  # @yieldparam [Integer] byte
  #   A byte from the IO stream.
  #
  # @return [Enumerator]
  #   If no block is given, an enumerator object will be returned.
  #
  def each_byte(&block)
    return enum_for(__method__) unless block

    each_chunk { |chunk| chunk.each_byte(&block) }
  end

  alias bytes each_byte

  #
  # Iterates over each character in the IO stream.
  #
  # @yield [char]
  #   The given block will be passed each character in the IO stream.
  #
  # @yieldparam [String] char
  #   A character from the IO stream.
  #
  # @return [Enumerator]
  #   If no block is given, an enumerator object will be returned.
  #
  def each_char(&block)
    return enum_for(__method__) unless block

    each_chunk { |chunk| chunk.each_char(&block) }
  end

  alias chars each_char

  #
  # Passes the Integer ordinal of each character in the stream.
  #
  # @yield [ord]
  #   The given block will be passed each codepoint.
  #
  # @yieldparam [String] ord
  #   The ordinal of a character from the stream.
  #
  # @return [Enumerator]
  #   If no block is given an Enumerator object will be returned.
  #
  # @note
  #   Only available on Ruby > 1.9.
  #
  def each_codepoint
    return enum_for(__method__) unless block_given?

    each_char { |c| yield c.ord }
  end

  alias codepoints each_codepoint

  #
  # Iterates over each line in the IO stream.
  #
  # @yield [line]
  #   The given block will be passed each line in the IO stream.
  #
  # @yieldparam [String] line
  #   A line from the IO stream.
  #
  # @return [Enumerator]
  #   If no block is given, an enumerator object will be returned.
  #
  # @see #gets
  #
  def each_line(separator=$/)
    return enum_for(__method__,separator) unless block_given?

    loop do
      begin
        line = gets(separator)
      rescue EOFError
        break
      end

      yield line
    end
  end

  alias each each_line
  alias lines each_line

  #
  # Reads every line from the IO stream.
  #
  # @return [Array<String>]
  #   The lines in the IO stream.
  #
  # @see #gets
  #
  def readlines(separator=$/)
    enum_for(:each_line,separator).to_a
  end

  #
  # Writes data to the IO stream.
  #
  # @param [String] data
  #   The data to write.
  #
  # @return [Integer]
  #   The number of bytes written.
  #
  # @raise [IOError]
  #   The stream is closed for writting.
  #
  def write(data)
    unless @write
      raise(IOError,"closed for writting")
    end

    io_write(data.to_s) if @write
  end

  alias syswrite write
  alias write_nonblock write

  #
  # Writes a byte or a character to the IO stream.
  #
  # @param [String, Integer] data
  #   The byte or character to write.
  #
  # @return [String, Integer]
  #   The byte or character that was written.
  #
  def putc(data)
    char = case data
           when String then data.chr
           else             data
           end

    write(char)
    return data
  end

  #
  # Prints data to the IO stream.
  #
  # @param [Array] arguments
  #   The data to print to the IO stream.
  #
  # @return [nil]
  # 
  def print(*arguments)
    arguments.each { |data| write(data) }
    return nil
  end

  #
  # Prints data with new-line characters to the IO stream.
  #
  # @param [Array] arguments
  #   The data to print to the IO stream.
  #
  # @return [nil]
  #
  def puts(*arguments)
    arguments.each { |data| write("#{data}#{$/}") }
    return nil
  end

  #
  # Prints a formatted string to the IO stream.
  #
  # @param [String] format_string
  #   The format string to format the data.
  #
  # @param [Array] arguments
  #   The data to format.
  #
  # @return [nil]
  # 
  def printf(format_string,*arguments)
    write(format_string % arguments)
    return nil
  end

  alias << write

  #
  # @raise [NotImplementedError]
  #   {#pid} is not implemented.
  #
  def pid
    raise(NotImplementedError,"#{self.class}#pid is not implemented")
  end

  #
  # @raise [NotImplementedError]
  #   {#stat} is not implemented.
  #
  def stat
    raise(NotImplementedError,"#{self.class}#stat is not implemented")
  end

  #
  # Indicates whether the IO stream is associated with a terminal device.
  #
  # @return [Boolean]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def isatty
    @tty
  end

  #
  # @see #isatty
  #
  def tty?
    @tty
  end

  #
  # @raise [NotImplementedError]
  #   {#seek} is not implemented.
  #
  def seek(new_pos,whence=SEEK_SET)
    raise(NotImplementedError,"#{self.class}#seek is not implemented")
  end

  #
  # @see #seek
  #
  def sysseek(offset,whence=SEEK_SET)
    seek(new_pos,whence)
  end

  #
  # @see #seek
  #
  def pos=(new_pos)
    seek(new_pos,SEEK_SET)
  end

  #
  # The current line-number (how many times {#gets} has been called).
  #
  # @return [Integer]
  #   The current line-number.
  #
  # @raise [IOError]
  #   The stream was not opened for reading.
  #
  def lineno
    unless @read
      raise(IOError,"not opened for reading")
    end

    return @lineno
  end

  #
  # Manually sets the current line-number.
  #
  # @param [Integer] number
  #   The new line-number.
  #
  # @return [Integer]
  #   The new line-number.
  #
  # @raise [IOError]
  #   The stream was not opened for reading.
  #
  def lineno=(number)
    unless @read
      raise(IOError,"not opened for reading")
    end

    return @lineno = number.to_i
  end

  #
  # @return [IO]
  #
  # @see #seek
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def rewind
    @lineno = 0
    seek(0,SEEK_SET)
  end

  #
  # @return [IO]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def binmode
    @binmode = true
    return self
  end

  #
  # @return [Boolean]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def binmode?
    @binmode == true
  end

  #
  # @return [IO]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def autoclose=(mode)
    self
  end

  #
  # @return [true]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def autoclose?
    true
  end

  #
  # @return [IO]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def close_on_exec=(mode)
    self
  end

  #
  # @return [true]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def close_on_exec?
    true
  end

  #
  # @raise [NotImplementedError]
  #   {#ioctl} was not implemented in {FakeIO}.
  #
  def ioctl(command,argument)
    raise(NotImplementedError,"#{self.class}#ioctl was not implemented")
  end

  #
  # @raise [NotImplementedError]
  #   {#fcntl} was not implemented in {FakeIO}.
  #
  def fcntl(command,argument)
    raise(NotImplementedError,"#{self.class}#fcntl was not implemented")
  end

  #
  # @return [0]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def fsync
    fflush
    return 0
  end

  alias fdatasync fsync

  #
  # @return [true]
  #   Returns `true` for compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def sync
    true
  end

  #
  # @param [Boolean] mode
  #   The sync mode.
  #
  # @return [Boolean]
  #   Returns the sync mode, for compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def sync=(mode)
    mode
  end

  #
  # @return [IO]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def flush
    self
  end

  #
  # @raise [NotImplementedError]
  #   {#reopen} is not implemented.
  #
  def reopen(*arguments)
    raise(NotImplementedError,"#{self.class}#reopen is not implemented")
  end

  #
  # Closes the read end of a duplex IO stream.
  #
  def close_read
    if @write then @read = false
    else           close
    end

    return nil
  end

  #
  # Closes the write end of a duplex IO stream.
  #
  def close_write
    if @read then @write = false
    else          close
    end

    return nil
  end

  #
  # Determines whether the IO stream is closed.
  #
  # @return [Boolean]
  #   Specifies whether the IO stream has been closed.
  #
  def closed?
    @closed == true
  end

  #
  # Closes the IO stream.
  #
  def close
    io_close

    @fd = nil

    @read   = false
    @write  = false
    @closed = true
    return nil
  end

  #
  # @return [IO]
  #
  # @note
  #   For compatibility with
  #   [IO](http://rubydoc.info/stdlib/core/IO).
  #
  def to_io
    self
  end

  #
  # Inspects the IO stream.
  #
  # @return [String]
  #   The inspected IO stream.
  #
  def inspect
    "#<#{self.class}: #{@fd.inspect if @fd}>"
  end

  protected

  #
  # Opens the IO stream.
  #
  # @return [IO]
  #   The opened IO stream.
  #
  def open
    @pos    = 0
    @lineno = 0
    @eof    = false

    clear_buffer!

    @fd = io_open
    @closed = false
    return self
  end

  #
  # @group Abstract Methods
  #

  #
  # Place holder method used to open the IO stream.
  #
  # @return [fd]
  #   The abstract file-descriptor that represents the stream.
  #
  # @abstract
  #
  def io_open
  end

  #
  # Place holder method used to read a block from the IO stream.
  #
  # @return [String]
  #   Available data to be read.
  #
  # @raise [EOFError]
  #   The end of the stream has been reached.
  #
  # @abstract
  #
  def io_read
  end

  #
  # Place holder method used to write data to the IO stream.
  #
  # @param [String] data
  #   The data to write to the IO stream.
  #
  # @abstract
  #
  def io_write(data)
    0
  end

  #
  # Place holder method used to close the IO stream.
  #
  # @abstract
  #
  def io_close
  end

  #
  # @group Buffer Methods
  #

  #
  # Clears the read buffer.
  #
  def clear_buffer!
    @buffer = nil
  end

  #
  # Determines if the read buffer is empty.
  #
  # @return [Boolean]
  #   Specifies whether the read buffer is empty.
  #
  def empty_buffer?
    @buffer.nil?
  end

  #
  # Reads data from the read buffer.
  #
  # @return [String]
  #   Data read from the buffer.
  #
  def read_buffer
    chunk = @buffer
    @pos += @buffer.bytesize

    clear_buffer!
    return chunk
  end

  #
  # Prepends data to the front of the read buffer.
  #
  # @param [String] data
  #   The data to prepend.
  #
  def prepend_buffer(data)
    @buffer ||= String.new
    @buffer.insert(0,data)
  end

  #
  # Appends data to the read buffer.
  #
  # @param [String] data
  #   The data to append.
  #
  def append_buffer(data)
    @pos -= data.bytesize

    @buffer ||= String.new
    @buffer << data
  end

end
