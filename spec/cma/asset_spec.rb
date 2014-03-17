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
      asset.content.should == "Dummy content\n"
    end

    its(:content_type)   { should eql('application/pdf') }
    its(:owner)          { should eql(_case) }
    its(:filename)       { should eql('APS-letter.pdf')}

    it 'saves its details as JSON' do
      JSON.parse(asset.to_json).should eql({
        'original_url' => 'http://some.asset/APS-letter.pdf',
        'content_type' => 'application/pdf',
        'filename'     => 'case-base-name/APS-letter.pdf'
      })
    end

    describe 'equality' do
      let(:other_with_same_url) { CMA::Asset.new('http://some.asset/APS-letter.pdf', nil, nil, nil) }
      let(:other_with_diff_url) { CMA::Asset.new('http://some.asset/APS-letter2.pdf', nil, nil, nil) }

      it 'is equal to the first' do
        asset.should eql(other_with_same_url)
        asset.should == other_with_same_url
      end
      it 'is different to the second' do
        asset.should_not eql(other_with_diff_url)
        asset.should_not == other_with_diff_url
      end
      describe 'works in a Set' do
        subject { Set.new([asset, other_with_same_url, other_with_diff_url]).to_a }
        it      { should =~ [asset, other_with_diff_url] }
      end
    end

    describe 'saving' do
      before { asset.save! }

      it "saves the file in a folder named the same as its owning case's basename" do
        expect(File).to exist('spec/fixtures/store/case-base-name/APS-letter.pdf')
      end
    end

    it 'calculates a filename correctly when the original_url is a URI' do
      asset = CMA::Asset.new(
        URI('http://some.asset/APS-letter.pdf'),
        _case,
        File.read('spec/fixtures/oft/APS-letter.pdf'),
        'application/pdf')

      asset.filename.should == 'APS-letter.pdf'
    end
  end
end
