shared_examples 'it has no markup or fluff' do
  it { should_not include '<p>'}
  it { should_not include '&nbsp;'}
  it { should_not include '<script'}
  it { should_not include '<span>'}
  it { should_not include '<div'}
  it { should_not include '[Initial'}
  it { should_not include 'backtotop'}
  it { should_not include '<!--'}
  it { should_not include '{:'}
end
