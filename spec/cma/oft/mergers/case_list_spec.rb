require 'spec_helper'
require 'nokogiri'
require 'cma/oft/mergers/case_list'
require 'fileutils'

module CMA
  module OFT
    module Mergers

      describe CaseList do
        describe '.from_html' do
          subject(:cases) do
            CaseList.from_html(
              Nokogiri::HTML(File.read('spec/fixtures/oft/mergers.html')))
          end

          it { should have(15).cases }

          describe 'saving them' do
            before do
              FileUtils.rmdir('spec/fixtures/store')
              cases.save!
            end

            after do
              FileUtils.rmdir('spec/fixtures/store')
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
