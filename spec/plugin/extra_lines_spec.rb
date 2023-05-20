require 'spec_helper'

RSpec.describe "Extra lines" do
  let(:filename) { 'test.html' }

  specify "adding an extra line above still works when editing opening tag" do
    set_file_contents <<~HTML

      <div>
        <div>Bottom</div>
      </div>
    HTML

    vim.search('div\ze>Bottom')
    edit("cwa href=\"test\"\\<up>\\<up>extra\\<cr>\\<down>\\<down>#{'\<right>' * 4}")

    assert_file_contents <<~HTML
      extra

      <div>
        <a href="test">Bottom</a>
      </div>
    HTML
  end

  specify "adding an extra line above still works when editing closing tag" do
    set_file_contents <<~HTML

      <div>
        <div>Bottom</div>
      </div>
    HTML

    vim.search('Bottom<\/\zsdiv>')
    edit("cwspan\\<up>\\<up>extra\\<cr>\\<down>\\<down>#{'\<right>' * 16}")

    assert_file_contents <<~HTML
      extra

      <div>
        <span>Bottom</span>
      </div>
    HTML
  end
end
