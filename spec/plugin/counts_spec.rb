require 'spec_helper'

RSpec.describe "Counts" do
  let(:filename) { 'test.html' }

  specify "with a count after the action" do
    set_file_contents <<~HTML
      <div prop class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('c2wspan')

    assert_file_contents <<~HTML
      <span class="test">
        <span>Text</span>
      </span>
    HTML
  end

  specify "with a count before the action" do
    set_file_contents <<~HTML
      <div prop class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('2cwspan')

    assert_file_contents <<~HTML
      <span class="test">
        <span>Text</span>
      </span>
    HTML
  end
end
