require 'spec_helper'
require 'nokogiri'
require 'cma/oft/competition/case_list'
require 'cma/oft'
require 'fileutils'

module CMA
  module OFT
    module Competition
      describe CaseList do
        describe '.from_html' do
          subject(:cases) do
            CaseList.from_html(
              Nokogiri::HTML(File.read('spec/fixtures/oft/oft-current.html')))
          end

          it { should have(12).cases }

          describe 'the first case' do
            subject do
              cases.first
            end
            its(:original_url) { should eql('http://oft.gov.uk/OFTwork/oft-current-cases/competition-case-list-2005/interchage-fees-mastercard') }
            its(:title)        { should eql('Mastercard / VISA MIFs') }
            its(:sector)       { should eql('financial-services') }
            its(:case_type)    { should eql('ca98-and-civil-cartels') }
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
