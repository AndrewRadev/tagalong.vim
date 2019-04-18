require 'spec_helper'

RSpec.describe "Negative examples" do
  let(:filename) { 'test.html' }

  specify "does not work with pasting" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </div>
    HTML

    vim.search('span')
    vim.normal 'yiw'
    vim.search('div')
    edit('viwp')

    assert_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
      </span>
    HTML
  end

  specify "doesn't do anything with unclosed tags" do
    set_file_contents <<~HTML
      <div class="test">
        <span>Text</span>
    HTML

    vim.search('div')
    edit('cwarticle')

    assert_file_contents <<~HTML
      <article class="test">
        <span>Text</span>
    HTML
  end

  specify "doesn't do anything with mismatched nested tags" do
    set_file_contents <<~HTML
      <div class="test">
        <div>Text</div>
    HTML

    vim.search('div')
    edit('cwarticle')

    assert_file_contents <<~HTML
      <article class="test">
        <div>Text</div>
    HTML
  end
end
