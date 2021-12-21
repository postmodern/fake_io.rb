require 'spec_helper'
require 'fake_io'

require 'classes/test_io'

describe FakeIO do
  let(:expected_chunks) { ["one\n", "two\nthree\n", "four\n"] }
  let(:expected) { expected_chunks.join }
  let(:expected_bytes) { expected_chunks.join.each_byte.to_a }
  let(:expected_chars) { expected_chunks.join.each_char.to_a }
  let(:expected_lines) { expected_chunks.join.each_line.to_a }

  subject { TestIO.new }

  describe "#initialize" do
    it "should open the IO stream" do
      expect(subject).not_to be_closed
    end

    it "should set the file descriptor returned by io_open" do
      expect(subject.fd).to eq(3)
    end
  end

  describe "#each_chunk" do
    it "should read each block of data" do
      expect(subject.each_chunk.to_a).to eq(expected_chunks)
    end
  end

  describe "#read" do
    it "should read all of the data" do
      expect(subject.read).to eq(expected)
    end

    it "should read partial sections of the data" do
      expect(subject.read(3)).to eq(expected[0,3])
      expect(subject.read(1)).to eq(expected[3,1])
    end

    it "should read individual blocks of data" do
      expect(subject.read(4)).to eq(expected[0,4])
    end
  end

  describe "#gets" do
    it "should get a line" do
      expect(subject.gets).to eq(expected_lines.first)
    end
  end

  describe "#readbyte" do
    it "should read bytes" do
      expect(subject.readbyte).to eq(expected_bytes.first)
    end
  end

  describe "#getc" do
    it "should get a character" do
      expect(subject.getc).to eq(expected_chars.first)
    end
  end

  describe "#readchar" do
    it "should read a char" do
      expect(subject.readchar).to eq(expected_chars.first)
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
      expect(subject.readline).to eq(expected_lines.first)
    end
  end

  describe "#readlines" do
    it "should read all lines" do
      expect(subject.readlines).to eq(expected_lines)
    end
  end

  describe "#each_byte" do
    it "should read each byte of data" do
      expect(subject.each_byte.to_a).to eq(expected_bytes)
    end
  end

  describe "#each_char" do
    it "should read each char of data" do
      expect(subject.each_char.to_a).to eq(expected_chars)
    end
  end

  describe "#each_line" do
    it "should read each line of data" do
      expect(subject.each_line.to_a).to eq(expected_lines)
    end
  end
end
