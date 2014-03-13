require 'spec_helper'
require 'nokogiri'
require 'cma/oft/markets/case_list'
require 'cma/oft'
require 'fileutils'

module CMA
  module OFT
    module Markets
      describe CaseList do
        describe '.from_html' do
          subject(:cases) do
            CaseList.from_html(
              Nokogiri::HTML(File.read('spec/fixtures/oft/oft-current.html')))
          end

          it { should have(6).cases }

          describe 'the first case' do
            subject do
              cases.first
            end
            its(:original_url) { should eql('http://oft.gov.uk/OFTwork/oft-current-cases/markets-work2013/higher-education-cfi') }
            its(:title)        { should eql('Higher Education sector call for information') }
            its(:sector)       { should include('Missing mapping') }
            its(:case_type)    { should eql('markets') }
          end


          describe 'saving them' do
            before do
              FileUtils.rmdir('spec/fixtures/store')
              cases.save!
            end

            it 'saved all cases' do
              cases.each do |c|
                expect(File).to exist(File.join(CaseStore.instance.location, c.filename))
              end
            end
          end
        end
      end

    end
  end
end
