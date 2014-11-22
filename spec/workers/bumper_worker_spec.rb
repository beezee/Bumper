describe BumperWorker do
  let(:email) { OpenStruct.new({from: {email: 'foo'}, body: 'body'}) }

  describe '#perform' do
    
    it 'enforces uniqueness on schedule_token and from address for 20 min' do
      expect {
        10.times do
          email.body = "#{email.body}1"
          BumperWorker.perform_async('1', email)
          BumperWorker.perform_async('2', email)
          BumperWorker.perform_async('3', email)
        end
      }.to change(BumperWorker.jobs, :size).by(3)
    end
  end
end
