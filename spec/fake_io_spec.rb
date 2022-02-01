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

    it "must default #external_encoding to Encoding.default_external" do
      expect(subject.external_encoding).to eq(Encoding.default_external)
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

  describe "#set_encoding" do
    context "when given a single String" do
      let(:string) { 'ASCII' }

      before { subject.set_encoding(string) }

      it "must set the #external_encoding" do
        expect(subject.external_encoding).to eq(Encoding.find(string))
      end

      it "must not set the #internal_encoding" do
        expect(subject.internal_encoding).to be(nil)
      end

      context "and the String contains a ':'" do
        let(:ext_enc) { 'UTF-8' }
        let(:int_enc) { 'ASCII' }
        let(:string)  { "#{ext_enc}:#{int_enc}" }

        it "must set the #external_encoding" do
          expect(subject.external_encoding).to eq(Encoding.find(ext_enc))
        end

        it "must set the #internal_encoding" do
          expect(subject.internal_encoding).to eq(Encoding.find(int_enc))
        end
      end

      context "and the String contains a ','" do
        let(:ext_enc) { 'UTF-8' }
        let(:int_enc) { 'ASCII' }
        let(:string)  { "#{ext_enc},#{int_enc}" }

        it "must set the #external_encoding" do
          expect(subject.external_encoding).to eq(Encoding.find(ext_enc))
        end

        it "must set the #internal_encoding" do
          expect(subject.internal_encoding).to eq(Encoding.find(int_enc))
        end
      end
    end

    context "when given a single Encoding object" do
      let(:encoding) { Encoding::ASCII }

      before { subject.set_encoding(encoding) }

      it "must set the #external_encoding" do
        expect(subject.external_encoding).to eq(encoding)
      end

      it "must not set the #internal_encoding" do
        expect(subject.internal_encoding).to be(nil)
      end
    end

    context "when given two Encoding objects" do
      let(:external_encoding) { Encoding::UTF_8 }
      let(:internal_encoding) { Encoding::ASCII }

      before { subject.set_encoding(external_encoding,internal_encoding) }

      it "must set the #external_encoding" do
        expect(subject.external_encoding).to eq(external_encoding)
      end

      it "must set the #internal_encoding" do
        expect(subject.internal_encoding).to eq(internal_encoding)
      end
    end

    context "when given another Object besides a String or an Encoding" do
      it do
        expect {
          subject.set_encoding(Object.new)
        }.to raise_error(TypeError,"argument must be a String or Encoding object")
      end
    end

    context "when no arguments are given" do
      it do
        expect {
          subject.set_encoding
        }.to raise_error(ArgumentError,"wrong number of arguments (given 0, expected 1..3)")
      end
    end

    context "when given more than three arguments" do
      it do
        expect {
          subject.set_encoding(
            Encoding::ASCII,
            Encoding::ASCII,
            Encoding::ASCII,
            Encoding::ASCII
          )
        }.to raise_error(ArgumentError,"wrong number of arguments (given 4, expected 1..3)")
      end
    end
  end

  describe "#set_encoding_by_bom" do
    class TestBOM

      include FakeIO

      def initialize(data)
        @data = data
        super()
      end

      private

      def io_read
        if (data = @data)
          @data = nil
          return data
        else
          raise(EOFError,"end of stream")
        end
      end

    end

    subject { TestBOM.new(data) }

    before { subject.set_encoding_by_bom }

    context "when the first byte is 0x00" do
      context "and the second byte is 0x00" do
        context "and the thrid byte is 0xFE" do
          context "and the fourth byte is 0xFF" do
            let(:data) do
              "\x00\x00\xFE\xFFhello".force_encoding(Encoding::ASCII_8BIT)
            end

            let(:encoding) { Encoding::UTF_32BE }

            it "must set #external_encoding to Encoding::UTF_32BE" do
              expect(subject.external_encoding).to eq(encoding)
            end

            it "must consume the BOM bytes" do
              expect(subject.read).to eq(
                data.byteslice(4..).force_encoding(encoding)
              )
            end
          end

          context "but the fourth byte is not 0xFF" do
            let(:data) do
              "\x00\x00\xFEXhello".force_encoding(Encoding::ASCII_8BIT)
            end

            it "must not set #external_encoding" do
              expect(subject.external_encoding).to be(
                Encoding.default_external
              )
            end

            it "must put the bytes back into the read buffer" do
              expect(subject.read).to eq(
                data.force_encoding(subject.external_encoding)
              )
            end
          end

          context "but EOF is reached" do
            let(:data) do
              "\x00\x00\xFE".force_encoding(Encoding::ASCII_8BIT)
            end

            it "must not set #external_encoding" do
              expect(subject.external_encoding).to be(
                Encoding.default_external
              )
            end

            it "must put the bytes back into the read buffer" do
              expect(subject.read).to eq(
                data.force_encoding(subject.external_encoding)
              )
            end
          end
        end

        context "but the third byte is not 0xFE" do
          let(:data) do
            "\x00\x00XXhello".force_encoding(Encoding::ASCII_8BIT)
          end

          it "must not set #external_encoding" do
            expect(subject.external_encoding).to be(Encoding.default_external)
          end

          it "must put the bytes back into the read buffer" do
            expect(subject.read).to eq(
              data.force_encoding(subject.external_encoding)
            )
          end
        end

        context "but EOF is reached" do
          let(:data) do
            "\x00\x00".force_encoding(Encoding::ASCII_8BIT)
          end

          it "must not set #external_encoding" do
            expect(subject.external_encoding).to be(Encoding.default_external)
          end

          it "must put the bytes back into the read buffer" do
            expect(subject.read).to eq(
              data.force_encoding(subject.external_encoding)
            )
          end
        end
      end

      context "but the second byte is not 0x00" do
        let(:data) do
          "\x00XXXhello".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end

      context "but EOF is reached" do
        let(:data) do
          "\x00".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end
    end

    context "but the first byte is not 0x00" do
      let(:data) do
        "XXXXhello".force_encoding(Encoding::ASCII_8BIT)
      end

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end

      it "must put the bytes back into the read buffer" do
        expect(subject.read).to eq(
          data.force_encoding(subject.external_encoding)
        )
      end
    end

    context "when the first byte is 0x28" do
      context "and the second byte is 0x2F" do
        context "and the third byte is 0x76" do
          let(:data) do
            "\x28\x2F\x76hello".force_encoding(Encoding::ASCII_8BIT)
          end

          let(:encoding) { Encoding::UTF_7 }

          it "must set #external_encoding to Encoding::UTF_7" do
            expect(subject.external_encoding).to eq(encoding)
          end

          it "must consume the BOM bytes" do
            pending "Cannot convert from UTF-8 to UTF-7"

            expect(subject.read).to eq(
              data.byteslice(2..).force_encoding(encoding)
            )
          end
        end

        context "but the third byte is not 0x76" do
          let(:data) do
            "\x28\x2FXhello".force_encoding(Encoding::ASCII_8BIT)
          end

          it "must not set #external_encoding" do
            expect(subject.external_encoding).to be(Encoding.default_external)
          end

          it "must put the bytes back into the read buffer" do
            expect(subject.read).to eq(
              data.force_encoding(subject.external_encoding)
            )
          end
        end

        context "but EOF is reached" do
          let(:data) do
            "\x28\x2F".force_encoding(Encoding::ASCII_8BIT)
          end

          it "must not set #external_encoding" do
            expect(subject.external_encoding).to be(Encoding.default_external)
          end

          it "must put the bytes back into the read buffer" do
            expect(subject.read).to eq(
              data.force_encoding(subject.external_encoding)
            )
          end
        end
      end

      context "but the second byte is not 0x2F" do
        let(:data) do
          "\x28XXhello".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end

      context "but EOF is reached" do
        let(:data) do
          "\x28".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end
    end

    context "but the first byte is not 0x2F" do
      let(:data) do
        "XXXhello".force_encoding(Encoding::ASCII_8BIT)
      end

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end

      it "must put the bytes back into the read buffer" do
        expect(subject.read).to eq(
          data.force_encoding(subject.external_encoding)
        )
      end
    end

    context "when the first byte is 0xEF" do
      context "and the second byte is 0xBB" do
        context "and the third byte is 0xBF" do
          let(:data) do
            "\xEF\xBB\xBFhello".force_encoding(Encoding::ASCII_8BIT)
          end

          let(:encoding) { Encoding::UTF_8 }

          it "must set #external_encoding to Encoding::UTF_8" do
            expect(subject.external_encoding).to eq(encoding)
          end

          it "must consume the BOM bytes" do
            expect(subject.read).to eq(
              data.byteslice(3..).force_encoding(encoding)
            )
          end
        end

        context "but the third byte is not 0xBF" do
          let(:data) do
            "\xEF\xBBXhello".force_encoding(Encoding::ASCII_8BIT)
          end

          it "must not set #external_encoding" do
            expect(subject.external_encoding).to be(Encoding.default_external)
          end

          it "must put the bytes back into the read buffer" do
            expect(subject.read).to eq(
              data.force_encoding(subject.external_encoding)
            )
          end
        end

        context "but EOF is reached" do
          let(:data) do
            "\xEF\xBB".force_encoding(Encoding::ASCII_8BIT)
          end

          it "must not set #external_encoding" do
            expect(subject.external_encoding).to be(Encoding.default_external)
          end

          it "must put the bytes back into the read buffer" do
            expect(subject.read).to eq(
              data.force_encoding(subject.external_encoding)
            )
          end
        end
      end

      context "but the second byte is not 0xBB" do
        let(:data) do
          "\xEFXXhello".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end

      context "but EOF is reached" do
        let(:data) do
          "\xEF".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end
    end

    context "but the first byte is not 0xEF" do
      let(:data) do
        "XXXhello".force_encoding(Encoding::ASCII_8BIT)
      end

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end

      it "must put the bytes back into the read buffer" do
        expect(subject.read).to eq(
          data.force_encoding(subject.external_encoding)
        )
      end
    end

    context "when the first byte is 0xFE" do
      context "and the second byte is 0xFF" do
        let(:data) do
          "\xFE\xFFhello".force_encoding(Encoding::ASCII_8BIT)
        end

        let(:encoding) { Encoding::UTF_16BE }

        it "must set #external_encoding to Encoding::UTF_16BE" do
          expect(subject.external_encoding).to eq(encoding)
        end

        it "must consume the BOM bytes" do
          expect(subject.read).to eq(
            data.byteslice(2..).force_encoding(encoding)
          )
        end
      end

      context "but the second byte is not 0xFF" do
        let(:data) do
          "\xFEXhello".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end

      context "but EOF is reached" do
        let(:data) do
          "\xFE".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end
    end

    context "but the first byte is not 0xFE" do
      let(:data) do
        "XXhello".force_encoding(Encoding::ASCII_8BIT)
      end

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end

      it "must put the bytes back into the read buffer" do
        expect(subject.read).to eq(
          data.force_encoding(subject.external_encoding)
        )
      end
    end

    context "but EOF is reached" do
      let(:data) do
        "".force_encoding(Encoding::ASCII_8BIT)
      end

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end
    end

    context "when the first byte is 0xFF" do
      context "and the second byte is 0xFE" do
        let(:data) do
          "\xFF\xFEhello".force_encoding(Encoding::ASCII_8BIT)
        end

        let(:encoding) { Encoding::UTF_16LE }

        it "must set #external_encoding to Encoding::UTF_16LE" do
          expect(subject.external_encoding).to eq(encoding)
        end

        it "must consume the BOM bytes" do
          expect(subject.read).to eq(
            data.byteslice(2..).force_encoding(encoding)
          )
        end
      end

      context "but the second byte is not 0xFE" do
        let(:data) do
          "\xFFXhello".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end

      context "but EOF is reached" do
        let(:data) do
          "\xFF".force_encoding(Encoding::ASCII_8BIT)
        end

        it "must not set #external_encoding" do
          expect(subject.external_encoding).to be(Encoding.default_external)
        end

        it "must put the bytes back into the read buffer" do
          expect(subject.read).to eq(
            data.force_encoding(subject.external_encoding)
          )
        end
      end
    end

    context "but the first byte is not 0xFF" do
      let(:data) do
        "XXhello".force_encoding(Encoding::ASCII_8BIT)
      end

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end

      it "must put the bytes back into the read buffer" do
        expect(subject.read).to eq(
          data.force_encoding(subject.external_encoding)
        )
      end
    end

    context "but EOF is reached" do
      let(:data) { "".force_encoding(Encoding::ASCII_8BIT) }

      it "must not set #external_encoding" do
        expect(subject.external_encoding).to be(Encoding.default_external)
      end
    end
  end

  describe "#each_chunk" do
    it "should read each block of data" do
      expect(subject.each_chunk.to_a).to eq(chunks)
    end

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.each_chunk.first.encoding).to eq(Encoding.default_external)
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.each_chunk.first.encoding).to eq(subject.external_encoding)
      end
    end
  end

  describe "#read" do
    context "when no length is given" do
      it "should read all of the data" do
        expect(subject.read).to eq(string)
      end

      it "must set the encoding of the String to Encoding.default_external" do
        expect(subject.read.encoding).to eq(Encoding.default_external)
      end

      it "must advance #pos by the number of bytes read" do
        previous_pos = subject.pos
        read_data    = subject.read

        expect(subject.pos - previous_pos).to eq(read_data.bytesize)
      end

      context "when #external_encoding diffs from Encoding.default_external" do
        let(:external_encoding) { Encoding::ASCII_8BIT }

        before { subject.external_encoding = external_encoding }

        it "must set the encoding of the String to #external_encoding" do
          expect(subject.read.encoding).to eq(subject.external_encoding)
        end
      end

      context "and when a buffer is also given" do
        let(:buffer) { String.new }

        it "must append the all read bytes to the buffer" do
          subject.read(nil,buffer)

          expect(buffer).to eq(string)
        end
      end
    end

    describe "#getbyte" do
      it "should get byte" do
        expect(subject.getbyte).to eq(bytes.first)
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

      it "must advance #pos by the number of bytes read" do
        previous_pos = subject.pos
        length       = 4
        read_data    = subject.read(length)

        expect(subject.pos - previous_pos).to eq(length)
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

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.readpartial(length).encoding).to eq(Encoding.default_external)
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.readpartial(length).encoding).to eq(subject.external_encoding)
      end
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

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.gets.encoding).to eq(Encoding.default_external)
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.gets.encoding).to eq(subject.external_encoding)
      end
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

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.getc.encoding).to eq(Encoding.default_external)
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.getc.encoding).to eq(subject.external_encoding)
      end
    end
  end

  describe "#readchar" do
    it "should read a char" do
      expect(subject.readchar).to eq(chars.first)
    end

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.readchar.encoding).to eq(Encoding.default_external)
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.readchar.encoding).to eq(subject.external_encoding)
      end
    end
  end

  describe "#ungetc" do
    it "should un-get characters back into the IO stream" do
      data = subject.read(4)
      data.each_char.reverse_each { |c| subject.ungetc(c) }

      expect(subject.read(4)).to eq(data)
    end

    it "must decrement #pos" do
      data         = subject.read(4)
      previous_pos = subject.pos
      char         = data.chars.last

      subject.ungetc(char)

      expect(previous_pos - subject.pos).to eq(char.bytesize)
    end
  end

  describe "#readline" do
    it "should read a line" do
      expect(subject.readline).to eq(lines.first)
    end

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.readline.encoding).to eq(Encoding.default_external)
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.readline.encoding).to eq(subject.external_encoding)
      end
    end
  end

  describe "#readlines" do
    it "should read all lines" do
      expect(subject.readlines).to eq(lines)
    end

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.readlines.map(&:encoding)).to all(eq(Encoding.default_external))
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.readlines.map(&:encoding)).to all(eq(subject.external_encoding))
      end
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

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.each_char.map(&:encoding)).to all(eq(Encoding.default_external))
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.each_char.map(&:encoding)).to all(eq(subject.external_encoding))
      end
    end
  end

  describe "#each_line" do
    it "should read each line of data" do
      expect(subject.each_line.to_a).to eq(lines)
    end

    it "must set the encoding of the String to Encoding.default_external" do
      expect(subject.each_line.map(&:encoding)).to all(eq(Encoding.default_external))
    end

    context "when #external_encoding diffs from Encoding.default_external" do
      let(:external_encoding) { Encoding::ASCII_8BIT }

      before { subject.external_encoding = external_encoding }

      it "must set the encoding of the String to #external_encoding" do
        expect(subject.each_line.map(&:encoding)).to all(eq(subject.external_encoding))
      end
    end
  end

  describe "#write" do
    let(:data) { "foo" }

    it "must call #io_write with the data" do
      expect(subject).to receive(:io_write).with(data)

      subject.write(data)
    end

    context "when the given data is not a String" do
      let(:data) { :foo }

      it "must convert the data to a String before calling #io_write" do
        expect(subject).to receive(:io_write).with(data.to_s)

        subject.write(data)
      end
    end

    context "when #internal_encoding is not nil" do
      let(:internal_encoding) { Encoding::ASCII_8BIT }
      let(:encoded_data)      { data.encode(internal_encoding) }

      before { subject.internal_encoding = internal_encoding }

      it "it must convert the given data to #internal_encoding before calling #io_write" do
        expect(data).to receive(:force_encoding).with(internal_encoding).and_return(encoded_data)
        expect(subject).to receive(:io_write).with(encoded_data)

        subject.write(data)
      end
    end

    context "when the object is not opened for writing" do
      before { subject.close_write }

      it do
        expect {
          subject.write(data)
        }.to raise_error(IOError,"closed for writing")
      end
    end
  end

  describe "#to_io" do
    it "must return self" do
      expect(subject.to_io).to be(subject)
    end
  end

  describe "#inspect" do
    let(:fd) { subject.instance_variable_get('@fd') }

    it "must return the inspected object as a string, including the @fd" do
      expect(subject.inspect).to eq("#<#{subject.class}: #{fd}>")
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
