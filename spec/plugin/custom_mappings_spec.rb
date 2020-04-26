require 'spec_helper'

RSpec.describe "Custom mappings" do
  let(:filename) { 'test.html' }

  specify "override c mapping" do
    vim.command("let g:_original_tagalong_mappings = g:tagalong_mappings")
    vim.command("let g:tagalong_mappings = [{'c': '_c', 'C': '_C'}, 'v', 'i', 'a']")

    set_file_contents <<~HTML
      <div>
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('_cwfoo')

    assert_file_contents <<~HTML
      <foo>
        <span>Text</span>
      </foo>
    HTML

    vim.search('<foo')
    edit('lcwdiv')

    assert_file_contents <<~HTML
      <div>
        <span>Text</span>
      </foo>
    HTML
  ensure
    vim.command("let g:tagalong_mappings = g:_original_tagalong_mappings")
  end

  specify "override c mapping with another plugin mapping c" do
    vim.command("let g:_original_tagalong_mappings = g:tagalong_mappings")
    vim.command("let g:tagalong_mappings = [{'c': '_c', 'C': '_C'}, 'v', 'i', 'a']")

    set_file_contents <<~HTML
      <div>
        <span>Text</span>
      </div>
    HTML
    vim.command("nnoremap <buffer><expr> c 'd'")

    vim.search('<div')
    edit('lcwl')

    # No change to buffer, because native c has been remapped
    assert_file_contents <<~HTML
      <>
        <span>Text</span>
      </div>
    HTML
  ensure
    vim.command("let g:tagalong_mappings = g:_original_tagalong_mappings")
  end
end
