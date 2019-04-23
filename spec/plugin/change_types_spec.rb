require 'spec_helper'

RSpec.describe "Change types" do
  let(:filename) { 'test.html' }

  specify "complete line change with C" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('Cspan>')

    assert_file_contents <<~HTML
      <span>
        <span>Text</span>
      </span>
    HTML
  end

  specify "visual mode" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('vlcna')

    assert_file_contents <<~HTML
      <nav class="test">
        <span>Text</span>
      </nav>
    HTML
  end

  specify "insert mode with i" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('li_')

    assert_file_contents <<~HTML
      <d_iv class="test">
        <span>Text</span>
      </d_iv>
    HTML
  end

  specify "insert mode with a" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('la_')

    assert_file_contents <<~HTML
      <di_v class="test">
        <span>Text</span>
      </di_v>
    HTML
  end

  specify "insert, backspace, change" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('ea\<bs>\<bs>\<bs>span')

    assert_file_contents <<~HTML
      <span class="test">
        <span>Text</span>
      </span>
    HTML
  end

  specify "change in <> with cursor anywhere in brackets" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('class')
    edit('ci>span')

    assert_file_contents <<~HTML
      <span>
        <span>Text</span>
      </span>
    HTML
  end
end
