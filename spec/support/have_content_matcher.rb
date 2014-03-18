RSpec::Matchers.define :have_content do |expected_content|
  match do |actual|
    expected_regex = @preceding_content ?
      Regexp.new((@preceding_content + '.*' + expected_content), Regexp::MULTILINE) :
      Regexp.new(expected_content)

    actual.should =~ expected_regex
  end

  failure_message_for_should do |actual|
    "Expected that the body of length #{actual.length} would contain "\
    "'#{@preceding_content + '\' followed by ' if @preceding_content}"\
    "#{expected_content}"
  end

  chain :under do |preceding_content|
    @preceding_content = preceding_content
  end

  diffable
end
