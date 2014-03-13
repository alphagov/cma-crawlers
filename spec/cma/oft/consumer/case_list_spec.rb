require 'spec_helper'
require 'nokogiri'
require 'cma/oft/consumer/case_list'
require 'cma/oft'
require 'fileutils'

module CMA
  module OFT
    module Consumer
      describe CaseList do
        describe '.from_html' do
          subject(:cases) do
            CaseList.from_html(
              Nokogiri::HTML(File.read('spec/fixtures/oft/oft-current.html')))
          end

          it { should have(5).cases }

          describe 'the first case' do
            subject do
              cases.first
            end
            its(:original_url) { should eql('http://oft.gov.uk/OFTwork/oft-current-cases/consumer-case-list-2012/furniture-carpets') }
            its(:title)        { should eql('Investigations into the use of misleading reference pricing by certain furniture and carpet businesses') }
            its(:sector)       { should eql('retail-and-wholesale') }
            its(:case_type)    { should eql('consumer-enforcement') }
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
