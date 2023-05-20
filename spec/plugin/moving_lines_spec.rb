require 'spec_helper'

RSpec.describe "Moving lines" do
  let(:filename) { 'test.html' }

  specify "adding an extra line above still works" do
    set_file_contents <<~HTML

      <div>
        <div>Bottom</div>
      </div>
    HTML

    vim.search('div\ze>Bottom')
    edit('cwa href="test"\<up>\<up>extra\<cr>\<down>\<down>\<right>\<right>\<right>\<right>')

    assert_file_contents <<~HTML
      extra

      <div>
        <a href="test">Bottom</a>
      </div>
    HTML
  end
end
