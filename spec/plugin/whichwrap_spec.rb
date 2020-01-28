require 'spec_helper'

RSpec.describe "HTML" do
  let(:filename) { 'test.html' }

  specify "changing whichwrap to include l" do
    vim.command 'set whichwrap+=l'

    set_file_contents <<~HTML
      <div>
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('cwarticle')

    assert_file_contents <<~HTML
      <article>
        <span>Text</span>
      </article>
    HTML
  ensure
    vim.command 'set whichwrap-=l'
  end
end
