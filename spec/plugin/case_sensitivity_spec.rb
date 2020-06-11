require 'spec_helper'

RSpec.describe "HTML" do
  let(:filename) { 'test.html' }

  specify "performs case changes" do
    vim.command 'set ignorecase'

    set_file_contents <<~HTML
      <div>
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('cwDiv')

    assert_file_contents <<~HTML
      <Div>
        <span>Text</span>
      </Div>
    HTML
  ensure
    vim.command 'set ignorecase&'
  end
end
