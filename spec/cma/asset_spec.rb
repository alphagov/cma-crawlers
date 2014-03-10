require 'spec_helper'
require 'cma/asset'
require 'cma/case_store'
require 'json'

describe CMA::Asset do
  describe 'creating from a big chunk o\'bytes' do
    let(:_case) do
      double('case').tap do |c|
        c.stub(:base_name).and_return('case-base-name')
        c.stub(:original_url).and_return('http://some.case')
      end
    end

    after do
      CMA::CaseStore.instance.clean!
    end

    subject(:asset) do
      CMA::Asset.new(
        'http://some.asset/APS-letter.pdf',
        _case,
        File.read('spec/fixtures/oft/APS-letter.pdf'),
        'application/pdf')
    end

    it 'has content' do
      asset.content.length.should == 111026
    end

    its(:content_type)   { should eql('application/pdf') }
    its(:owner)          { should eql(_case) }
    its(:filename)       { should eql('APS-letter.pdf')}

    it 'saves its details as JSON' do
      JSON.parse(asset.to_json).should eql({
        'original_url' => 'http://some.asset/APS-letter.pdf',
        'content_type' => 'application/pdf',
        'filename'     => 'APS-letter.pdf'
      })
    end

    describe 'saving' do
      before { asset.save! }

      it "saves the file in a folder named the same as its owning case's basename" do
        expect(File).to exist('spec/fixtures/store/case-base-name/APS-letter.pdf')
      end
    end
  end
end
