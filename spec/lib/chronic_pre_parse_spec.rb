require 'spec_helper'

describe ChronicPreParse do

  describe '.token_is_time?' do
    
    describe 'when token is a supported format of time of day' do

      it 'is true' do
        times = %W{9.10am 9am 10.10am 10am 9.10pm 9pm 10.10pm 10pm}
        times.each { |t| expect(ChronicPreParse.token_is_time?(t)).to be_truthy }
      end
    end

    describe 'when token is not a supported format of time of day' do

      it 'is false' do
        times = %W{9.10gm 9gm 1010am fooam g.10pm spm 1010pm 10p}
        times.each { |t| expect(ChronicPreParse.token_is_time?(t)).to be_nil }
      end
    end
  end

  describe '.parse' do
    def parse(s)
      ChronicPreParse.parse(s)
    end
    let(:durations) { %W{week day month hour minute} }
    let(:plural_durations) { durations.map {|d| "#{d}s"} }

    it 'returns nil when no patterns are matched' do
      expect(parse(1)).to be_nil
    end
    
    it 'parses tomorrow into 24 hours from now' do
      expect(parse('tomorrow')).to eq(' 24 hours from now ')
    end

    it 'parses bumper syntax correctly into Chronic friendly syntax' do
      expect(parse('july14')).to eq(' july 14 ')
      expect(parse('september20-3.45pm')).to eq(' september 20  at 3.45pm ')
      expect(parse('thursday-4.45am')).to eq('thursday at 4.45am ')
      durations.product(plural_durations).each do |(d1, d2)|
        expect(parse("1#{d1}")).to eq(" 1 #{d1} from now ")
        expect(parse("22#{d2}")).to eq(" 22 #{d2} from now ")

        expect(parse("1#{d1}")).to eq(" 1 #{d1} from now ")
        expect(parse("1#{d1}-7.30pm")).to eq(" 1 #{d1} from now  at 7.30pm ")
        expect(parse("22#{d2}")).to eq(" 22 #{d2} from now ")
        expect(parse("22#{d2}-7.30pm")).to eq(" 22 #{d2} from now  at 7.30pm ")

        input = "1#{d1}2#{d2}"
        output = " 1 #{d1} and 2 #{d2} from now "
        expect(parse(input)).to eq(output)
        expect(parse("#{input}-5pm")).to eq("#{output} at 5pm ")
      end
    end
  end
end
