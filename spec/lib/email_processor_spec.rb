describe EmailProcessor do
  let(:email_settings) { {} }
  let(:email) { OpenStruct.new(email_settings) }
  let(:email_params) do
    {from: email.from[:email], subject: email.subject,
      text: email.raw_text, html: email.raw_html}
  end
             
  let(:processor) { EmailProcessor.new(email) }

  class ToAddressGenerator
    def to(token, host=Bumper::Application.config.settings.from_host)
      {token: token, host: host}
    end

    def with_others(addresses)
      addresses + 
        [to('tomorrow', 'gmail.com'), to('1week-4.30pm', 'hotmail.com')]
    end

    def build_to(bumper_to_tokens)
      with_others(bumper_to_tokens.map {|t| to(t)})
    end
  end
  let(:to_gen) { ToAddressGenerator.new }
  
  describe '#from_authorized?' do
    
    describe 'when message is from whitelisted address' do
      let(:email_settings) { {from: {email: 'test_email@address.com'}} }

      it 'is true' do

        expect(processor.from_authorized?).to be_truthy
      end
    end
    
    describe 'when message is not from whitelisted address' do

      let(:email_settings) { {from: {email: 'not_test_email@address.com'}} }

      it 'is false' do

        expect(processor.from_authorized?).to be_falsy
      end
    end
  end

  describe '#time_from_token' do

    it 'defaults to UTC' do
      expect(Bumper::Application.config.settings).to receive(:timezone).
        and_return(nil).exactly(1).times
      expect(processor.time_from_token('tomorrow').zone).to eq('UTC')
    end

    it 'reads tz from config when present' do
      expect(Bumper::Application.config.settings).to receive(:timezone).
        and_return('EST').exactly(1).times
      expect(processor.time_from_token('tomorrow').zone).to eq('EST')
    end
  end

  describe '#bumper_addresses' do
    before { Timecop.freeze }
    after { Timecop.return }

    describe 'with one supported to address' do
      let(:email_settings) { {to: to_gen.build_to(['10days'])} }

      it 'returns a sends hash with the match under :supported' do
        expect(processor.bumper_addresses).to eq(
          {supported: [['10days', 10.days.from_now]], unsupported: []}) 
      end
    end

    describe 'with multiple supported to addresses' do
      let(:email_settings) { {to: to_gen.build_to(['1week', 'tomorrow'])} }

      it 'returns a sends hash with the matches under :supported' do
        expect(processor.bumper_addresses).to eq(
          {supported: [['1week', 1.week.from_now], ['tomorrow', 1.day.from_now]],
            unsupported: []})
      end
    end

    # this is impossible in practice, but hey let's be thorough
    describe 'with no supported addresses' do
      let(:email_settings) { {to: to_gen.build_to([])}  }

      it 'returns a sends hash with empty :supported and :unsupported' do
        expect(processor.bumper_addresses).to eq(
          {supported: [], unsupported: []})
      end
    end

    describe 'with only unsupported addresses' do
      let(:email_settings) { {to: to_gen.build_to(['1bad', '2bad'])} }

      it 'returns a sends hash with matches under :unsupported' do
        expect(processor.bumper_addresses).to eq(
          {supported: [], unsupported: ['1bad', '2bad']})
      end
    end

    describe 'with some unsupported/invalid and some supported addresses' do
      let(:email_settings) { {to: to_gen.build_to(['monday-3.15pm', '1'])} }

      it 'returns a sends hash with matches under :supported and :unsupported' do
        expect(processor.bumper_addresses).to eq(
          {supported: [['monday-3.15pm', Chronic.parse('monday at 3.15pm')]],
            unsupported: ['1']})
      end
    end
  end

  describe '#process' do
    let(:bad_to_addresses) { [1, 'bad', 'another bad'] }
    let(:good_to_addresses) { ['1week1day', 'thursday-4.45pm'] }
    
    shared_examples 'not sending howto' do
      
      it 'does not trigger HowToUseBumperWorker' do
        expect(HowToUseBumperWorker).to_not receive(:perform_async)
        processor.process
      end
    end

    shared_examples 'not sending reminders' do

      it 'does not trigger BumperWorker' do
        expect(BumperWorker).to_not receive(:perform_at)
        processor.process
      end
    end

    shared_examples 'sending howto' do

      it 'triggers HowToUseBumperWorker with from address and bad to addresses' do
        expect(HowToUseBumperWorker).to receive(:perform_async).
          with('test_email@address.com', bad_to_addresses).
          exactly(1).times
        processor.process
      end
    end

    shared_examples 'sending reminders' do
      
      it 'hands off to BumperWorker with supported emails' do
        expect(BumperWorker).to receive(:perform_at).
          with(8.days.from_now, '1week1day', email_params).
          exactly(1).times
        expect(BumperWorker).to receive(:perform_at).
          with(Chronic.parse('thursday at 4.45pm'), 'thursday-4.45pm', email_params).
          exactly(1).times
        processor.process
      end
    end

    describe 'when from an unauthorized email address' do
      let(:email_settings) do
        {from: {email: 'unauthorized@email.com'}, 
          to: to_gen.build_to(['tomorrow'])}
      end
      
      it_behaves_like 'not sending howto'
      it_behaves_like 'not sending reminders'
    end

    describe 'when from an authorized email address' do
      before { Timecop.freeze }
      after { Timecop.return }

      describe 'with unsupported to addresses and no supported' do
        let(:email_settings) do
          {from: {email: 'test_email@address.com'}, 
            to: to_gen.build_to(bad_to_addresses)}
        end

        it_behaves_like 'not sending reminders'
        it_behaves_like 'sending howto'
      end


      describe 'with supported to addresses and no unsupported' do
        let(:email_settings) do
          {from: {email: 'test_email@address.com'},
            to: to_gen.build_to(good_to_addresses)}
        end

        it_behaves_like 'sending reminders'
        it_behaves_like 'not sending howto'
      end

      describe 'with both supported and unsupported to addresses' do
        let(:email_settings) do
          {from: {email: 'test_email@address.com'},
            to: to_gen.build_to((good_to_addresses + bad_to_addresses))}
        end

        it_behaves_like 'sending reminders'
        it_behaves_like 'sending howto'

      end
    end
  end
end
