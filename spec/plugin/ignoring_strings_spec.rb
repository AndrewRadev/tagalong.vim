require 'spec_helper'

RSpec.describe "HTML" do
  let(:filename) { 'test.html' }

  specify "ignoring HTML strings" do
    set_file_contents <<~HTML
      <div data-description="A<span>foo</span>">One</div>
    HTML

    vim.search('span')
    edit('cwstrong')

    assert_file_contents <<~HTML
      <div data-description="A<strong>foo</span>">One</div>
    HTML
  end
end
