require 'spec_helper'

describe FuelSDK::Targeting do

  subject { Class.new.new.extend(FuelSDK::Targeting) }
  let(:client) { subject }
  let(:expected_url) {'S#.authentication.target'}

  it { should respond_to(:endpoint) }
  it { should_not respond_to(:endpoint=) }
  it { should respond_to(:get) }
  it { should respond_to(:post) }
  it { should respond_to(:patch) }
  it { should respond_to(:delete) }
  it { should respond_to(:access_token) }


  describe :instance_methods do
    before do
      client.stub(:access_token).and_return('open_sesame')
      client.stub(:get)
        .with('https://www.exacttargetapis.com/platform/v1/endpoints/soap',{'params'=>{'access_token'=>'open_sesame'}})
        .and_return({'url' => expected_url})
    end

    describe '#determine_stack' do

      it 'is a protected_method' do
        subject.protected_methods.include?(:determine_stack)
      end

      it 'returns the detected endpoint url' do
        expect(client.send(:determine_stack)).to eq expected_url
      end

      it 'sets @endpoint to the returned endpoint url' do
        client.send(:determine_stack)
        expect(client.instance_variable_get(:@endpoint)).to eq expected_url
        expect(client.endpoint).to eq expected_url
      end

    end


    describe '#endpoint' do

      it 'calls determine_stack to find target' do
        expect(client.endpoint).to eq expected_url
      end

      context '@endpoint not yet defined' do
        before { client.instance_variable_set(:@endpoint, nil) }
        it 'calls determine_stack to find target' do
          expect(client).to receive(:determine_stack)
          client.endpoint
        end
        it 'caches the result' do
          expect(client).to receive(:determine_stack).once.and_call_original
          expect(client.endpoint).to eq expected_url
          expect(client.endpoint).to eq expected_url
        end
      end

      context '@endpoint defined' do
        before { client.instance_variable_set(:@endpoint, expected_url) }
        it 'returns @endpoint witout calling #determine_stack to find target' do
          expect(client).not_to receive(:determine_stack)
          expect(client.endpoint).to eq expected_url
        end
      end

    end
  end
end
