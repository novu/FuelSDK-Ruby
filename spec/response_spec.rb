require 'spec_helper'

describe FuelSDK::Response do
  #
  # needs a response as a subject model
  #


  shared_examples 'FuelSDK::Response' do
    let(:response) { subject }

    it { should respond_to(:code) }
    it { should_not respond_to(:code=) }
    it { should respond_to(:message) }
    it { should_not respond_to(:message=) }
    it { should respond_to(:results) }
    it { should_not respond_to(:results=) }
    it { should respond_to(:request_id) }
    it { should_not respond_to(:request_id=) }
    it { should respond_to(:body) }
    it { should_not respond_to(:body=) }
    it { should respond_to(:raw) }
    it { should_not respond_to(:raw=) }

    describe :success do

      it 'defaults to false' do
        expect(response.success).to be_false
      end
      it 'returns instance varaible @success' do
        response.instance_variable_set(:@success, true)
        expect(response.success).to be_true
      end
      it 'aliases to success?' do
        expect(response.success?).to eq response.success
      end
      it 'aliases to status' do
        expect(response.status).to eq response.success
      end

    end

    describe :more do

      it 'defaults to false' do
        expect(response.more).to be_false
      end
      it 'returns instance varaible @more' do
        response.instance_variable_set(:@more, true)
        expect(response.more).to be_true
      end
      it 'aliases to more?' do
        expect(response.more?).to eq response.more
      end

    end

    describe :continue do
      it 'raises a NotImplementedError' do
        expect(response).to raise(NotImplementedError)
      end
    end

  end

end
    # describe 'Group' do
    #   it_behaves_like 'Community::Item'
    #   let(:item)  { group }
    # end

    # describe 'Event' do
    #   it_behaves_like 'Community::Item'
    #   let(:item)  { event }
    # end
