require 'spec_helper'
require 'fake_io'

require 'classes/test_io'

describe FakeIO do
  let(:expected_blocks) { ["one\n", "two\nthree\n", "four\n"] }
  let(:expected) { expected_blocks.join }
  let(:expected_bytes) { expected_blocks.join.each_byte.to_a }
  let(:expected_chars) { expected_blocks.join.each_char.to_a }
  let(:expected_lines) { expected_blocks.join.each_line.to_a }

  subject { TestIO.new }

  describe "#initialize" do
    it "should open the IO stream" do
      expect(subject).not_to be_closed
    end

    it "should set the file descriptor returned by io_open" do
      expect(subject.fd).to eq(3)
    end
  end

  it "should read each block of data" do
    expect(subject.each_block.to_a).to eq(expected_blocks)
  end

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

  it "should get a line" do
    expect(subject.gets).to eq(expected_lines.first)
  end

  it "should read bytes" do
    expect(subject.readbyte).to eq(expected_bytes.first)
  end

  if RUBY_VERSION > '1.9.'
    context "when Ruby > 1.9" do
      it "should get a character" do
        expect(subject.getc).to eq(expected_chars.first)
      end

      it "should read a char" do
        expect(subject.readchar).to eq(expected_chars.first)
      end

      it "should un-get characters back into the IO stream" do
        data = subject.read(4)
        data.each_char.reverse_each { |c| subject.ungetc(c) }

        expect(subject.read(4)).to eq(data)
      end
    end
  else
    context "when Ruby 1.8" do
      it "should get a character" do
        expect(subject.getc).to eq(expected_bytes.first)
      end

      it "should read a char" do
        expect(subject.readchar).to eq(expected_bytes.first)
      end

      it "should un-get characters back into the IO stream" do
        data = subject.read(4)
        data.each_byte.reverse_each { |c| subject.ungetc(c) }

        expect(subject.read(4)).to eq(data)
      end
    end
  end

  it "should read a line" do
    expect(subject.readline).to eq(expected_lines.first)
  end

  it "should read all lines" do
    expect(subject.readlines).to eq(expected_lines)
  end

  it "should read each byte of data" do
    expect(subject.each_byte.to_a).to eq(expected_bytes)
  end

  it "should read each char of data" do
    expect(subject.each_char.to_a).to eq(expected_chars)
  end

  it "should read each line of data" do
    expect(subject.each_line.to_a).to eq(expected_lines)
  end
end
