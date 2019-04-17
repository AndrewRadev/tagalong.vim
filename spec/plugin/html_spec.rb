require 'spec_helper'

RSpec.describe "cw" do
  let(:filename) { 'test.html' }

  specify "changing a simple multiline tag" do
    set_file_contents <<~HTML
      <div>
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('cwarticle')
    vim.write

    assert_file_contents <<~HTML
      <article>
        <span>Text</span>
      </article>
    HTML
  end

  specify "changing a simple single-line tag" do
    set_file_contents <<~HTML
      <div><span>Text</span></div>
    HTML

    vim.search('div')
    edit('cwarticle')
    vim.write

    assert_file_contents <<~HTML
      <article><span>Text</span></article>
    HTML

    vim.search('span')
    edit('cwa')
    vim.write

    assert_file_contents <<~HTML
      <article><a>Text</a></article>
    HTML
  end

  specify "keeping and adding attributes" do
    set_file_contents <<~HTML
      <div class="example">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('cwarticle')
    vim.write

    assert_file_contents <<~HTML
      <article class="example">
        <span>Text</span>
      </article>
    HTML

    vim.search('span')
    edit('cwa href="http://test.host"')
    vim.write

    assert_file_contents <<~HTML
      <article class="example">
        <a href="http://test.host">Text</a>
      </article>
    HTML
  end

  specify "invalid tag changes" do
    set_file_contents <<~HTML
      <div class="example">
        <span>Text</span>
      </div>
    HTML

    vim.search('div')
    edit('cw')
    vim.write

    assert_file_contents <<~HTML
      < class="example">
        <span>Text</span>
      </div>
    HTML

    vim.search('span')
    edit('cw')
    vim.write

    assert_file_contents <<~HTML
      < class="example">
        <>Text</span>
      </div>
    HTML
  end

  specify "changing closing tag" do
    set_file_contents <<~HTML
      <div class="example">
        <span>Text</span>
      </div>
    HTML

    vim.search('<\/\zsdiv')
    edit('cwarticle')
    vim.write

    assert_file_contents <<~HTML
      <article class="example">
        <span>Text</span>
      </article>
    HTML
  end
end