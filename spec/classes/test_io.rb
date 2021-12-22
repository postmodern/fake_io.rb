require 'fake_io'

class TestIO
  
  include FakeIO

  def initialize(chunks)
    @index  = 0
    @blocks = chunks

    super()
  end

  protected

  def io_open
    3
  end

  def io_read
    unless (block = @blocks[@index])
      raise(EOFError,"end of stream")
    end

    @index += 1
    return block
  end

  def io_write(data)
    @blocks[@index] = data
    @index += 1

    return data.length
  end

end
