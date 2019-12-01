require 'spec_helper'

RSpec.describe "Existing mappings" do
  let(:filename) { 'test.html' }

  specify "existing mapping for i" do
    vim.command('nmap i ifoo_')

    set_file_contents <<~HTML
      <div>
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('ibar_')

    assert_file_contents <<~HTML
      <foo_bar_div>
        <span>Text</span>
      </foo_bar_div>
    HTML

    vim.command('unmap i')
  end
end
