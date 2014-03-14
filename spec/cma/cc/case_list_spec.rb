require 'spec_helper'
require 'cma/cc/our_work/case_list'

module CMA
  module CC
    module OurWork
      describe CaseList do
        let(:doc) { Nokogiri::HTML(File.read('spec/fixtures/cc/our-work.html')) }

        describe '.from_html' do
          subject(:cases) do
            CaseList.from_html(doc)
          end

          it { should have(17).cases }

          describe 'the first case' do
            subject { cases.first }

            its(:original_url) { should eql('http://www.competition-commission.org.uk/our-work/directory-of-all-inquiries/aggregates-cement-ready-mix-concrete') }
            its(:title)        { should eql('Aggregates, cement and ready-mix concrete') }
          end

          describe 'saving them' do
            before do
              FileUtils.rmtree('spec/fixtures/store')
              cases.save!
            end

            after do
              FileUtils.rmtree('spec/fixtures/store')
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
