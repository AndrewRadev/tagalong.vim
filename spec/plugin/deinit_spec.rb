require 'spec_helper'

RSpec.describe "TagalongDeinit" do
  let(:filename) { 'test.html' }

  specify "de-initializing and re-initializing the plugin" do
    set_file_contents <<~HTML
      <div>Example</div>
    HTML

    vim.command 'TagalongDeinit'
    vim.search '<\zsdiv'
    edit('cwspan')

    assert_file_contents <<~HTML
      <span>Example</div>
    HTML

    vim.command 'undo'
    vim.command 'TagalongInit'
    vim.search '<\zsdiv'
    edit('cwspan')

    assert_file_contents <<~HTML
      <span>Example</span>
    HTML
  end
end
