require 'spec_helper'
require 'fake_io'

require 'classes/test_io'

describe FakeIO do
  let(:chunks) { ["one\n", "two\nthree\n", "four\n"] }
  let(:string) { chunks.join }
  let(:bytes)  { chunks.join.each_byte.to_a }
  let(:chars)  { chunks.join.each_char.to_a }
  let(:lines)  { chunks.join.each_line.to_a }

  subject { TestIO.new(chunks) }

  describe "#initialize" do
    it "should open the IO stream" do
      expect(subject).not_to be_closed
    end

    it "must default #autoclose? to true" do
      expect(subject.autoclose?).to be(true)
    end

    it "must default #close_on_exec? to true" do
      expect(subject.close_on_exec?).to be(true)
    end

    it "should set the file descriptor returned by io_open" do
      expect(subject.fileno).to eq(3)
    end

    it "must set #pos to 0" do
      expect(subject.pos).to eq(0)
    end

    it "must set #lineno to 0" do
      expect(subject.lineno).to eq(0)
    end

    it "must set #eof to false" do
      expect(subject.eof).to be(false)
    end

    it "must default #tty? to false" do
      expect(subject.tty?).to be(false)
    end

    it "must default #pid to nil" do
      expect(subject.pid).to be(nil)
    end

    it "must default #sync to false" do
      expect(subject.sync).to be(false)
    end
  end

  describe "#advise" do
    it "must return nil" do
      expect(subject.advise(:normal,0,0)).to be(nil)
    end
  end

  describe "#autoclose=" do
    let(:autoclose) { false }

    before { subject.autoclose = autoclose }

    it "must set #autoclose?" do
      expect(subject.autoclose?).to be(autoclose)
    end
  end

  describe "#autoclose?" do
    it "must return true by default" do
      expect(subject.autoclose?).to be(true)
    end

    context "when #autoclose= is set to false" do
      before { subject.autoclose = false }

      it "must return false" do
        expect(subject.autoclose?).to be(false)
      end
    end
  end

  describe "#close_on_exec=" do
    let(:close_on_exec) { false }

    before { subject.close_on_exec = close_on_exec }

    it "must set #close_on_exec?" do
      expect(subject.close_on_exec?).to be(close_on_exec)
    end
  end

  describe "#close_on_exec?" do
    it "must return true by default" do
      expect(subject.close_on_exec?).to be(true)
    end

    context "when #close_on_exec= is set to false" do
      before { subject.close_on_exec = false }

      it "must return false" do
        expect(subject.close_on_exec?).to be(false)
      end
    end
  end

  describe "#binmode" do
    before { subject.binmode }

    it "must cause #binmode? to return true" do
      expect(subject.binmode?).to be(true)
    end
  end

  describe "#binmode?" do
    it "must return false by default" do
      expect(subject.binmode?).to be(false)
    end

    context "when binmode is set" do
      before { subject.binmode }

      it "must return true" do
        expect(subject.binmode?).to be(true)
      end
    end
  end

  describe "#isatty" do
    it "must return false by default" do
      expect(subject.isatty).to be(false)
    end
  end

  describe "#tty?" do
    it "must return false by default" do
      expect(subject.tty?).to be(false)
    end
  end

  describe "#each_chunk" do
    it "should read each block of data" do
      expect(subject.each_chunk.to_a).to eq(chunks)
    end
  end

  describe "#read" do
    context "when no length is given" do
      it "should read all of the data" do
        expect(subject.read).to eq(string)
      end

      context "and when a buffer is also given" do
        let(:buffer) { String.new }

        it "must append the all read bytes to the buffer" do
          subject.read(nil,buffer)

          expect(buffer).to eq(string)
        end
      end
    end

    context "when a length is given" do
      it "should read partial sections of the data" do
        expect(subject.read(3)).to eq(string[0,3])
        expect(subject.read(1)).to eq(string[3,1])
      end

      it "should read individual blocks of data" do
        expect(subject.read(4)).to eq(string[0,4])
      end

      context "but the data is UTF-8" do
        let(:chunks) { ["Σὲ ", "γνωρίζω ἀπὸ", " τὴν κόψη"] }

        it "must read exactly N bytes, not N chars" do
          expect(subject.read(1)).to eq(string.byteslice(0,1))
        end
      end

      context "and when a buffer is also given" do
        let(:buffer) { String.new }

        it "must append the read bytes to the buffer" do
          subject.read(3,buffer)
          subject.read(1,buffer)

          expect(buffer).to eq(string[0,3 + 1])
        end
      end
    end
  end

  describe "#readpartial" do
    let(:length) { 3 }

    it "must read at most N bytes" do
      expect(subject.readpartial(length).length).to eq(length)
    end

    context "when also given a buffer" do
      let(:buffer) { String.new }

      it "must append the read bytes to the buffer" do
        subject.readpartial(length,buffer)
        subject.readpartial(length,buffer)

        expect(buffer).to eq(string[0,length * 2])
      end
    end
  end

  describe "#gets" do
    it "should get a line" do
      expect(subject.gets).to eq(lines.first)
    end
  end

  describe "#readbyte" do
    it "should read bytes" do
      expect(subject.readbyte).to eq(bytes.first)
    end
  end

  describe "#getc" do
    it "should get a character" do
      expect(subject.getc).to eq(chars.first)
    end
  end

  describe "#readchar" do
    it "should read a char" do
      expect(subject.readchar).to eq(chars.first)
    end
  end

  describe "#ungetc" do
    it "should un-get characters back into the IO stream" do
      data = subject.read(4)
      data.each_char.reverse_each { |c| subject.ungetc(c) }

      expect(subject.read(4)).to eq(data)
    end
  end

  describe "#readline" do
    it "should read a line" do
      expect(subject.readline).to eq(lines.first)
    end
  end

  describe "#readlines" do
    it "should read all lines" do
      expect(subject.readlines).to eq(lines)
    end
  end

  describe "#each_byte" do
    it "should read each byte of data" do
      expect(subject.each_byte.to_a).to eq(bytes)
    end
  end

  describe "#each_char" do
    context "when a block is given" do
      it "must yield each read char of the data" do
        expect { |b|
          subject.each_char(&b)
        }.to yield_successive_args(*chars)
      end
    end

    context "when no block is given" do
      it "must return an Enumerator that read each char of data" do
        expect(subject.each_char.to_a).to eq(chars)
      end
    end
  end

  describe "#each_line" do
    it "should read each line of data" do
      expect(subject.each_line.to_a).to eq(lines)
    end
  end

  describe "#to_io" do
    it "must return self" do
      expect(subject.to_io).to be(subject)
    end
  end

  context "when running under Ruby 2.x" do
    if RUBY_VERSION < '3.'
      it "must define #bytes" do
        expect(subject).to respond_to(:bytes)
      end

      it "must define #chars" do
        expect(subject).to respond_to(:chars)
      end

      it "must define #codepoints" do
        expect(subject).to respond_to(:codepoints)
      end

      it "must define #lines" do
        expect(subject).to respond_to(:lines)
      end
    end
  end

  context "when running under Ruby 3.x" do
    if RUBY_VERSION > '3.'
      it "must not define #bytes" do
        expect(subject).to_not respond_to(:bytes)
      end

      it "must not define #chars" do
        expect(subject).to_not respond_to(:chars)
      end

      it "must not define #codepoints" do
        expect(subject).to_not respond_to(:codepoints)
      end

      it "must not define #lines" do
        expect(subject).to_not respond_to(:lines)
      end
    end
  end
end
