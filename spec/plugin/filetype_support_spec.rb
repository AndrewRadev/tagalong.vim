require 'spec_helper'

RSpec.describe "Filetype support" do
  describe "HTML" do
    let(:filename) { 'test.html' }

    specify "works" do
      set_file_contents <<~HTML
      <div>Text</div>
      HTML

      vim.search('div')
      edit('cwspan')

      assert_file_contents <<~HTML
      <span>Text</span>
      HTML
    end
  end

  describe "XML" do
    let(:filename) { 'test.xml' }

    specify "works" do
      set_file_contents <<~HTML
        <Thing>Text</Thing>
      HTML

      vim.search('Thing')
      edit('cwOther')

      assert_file_contents <<~HTML
        <Other>Text</Other>
      HTML
    end
  end

  describe "JSX" do
    let(:filename) { 'test.jsx' }

    # JSX support not built-in, so matchit support not built-in. We can't
    # check if it really works, but we can check if the mapping is there, at
    # least.
    specify "has mapping" do
      set_file_contents <<~HTML
        <div>Text</div>
      HTML

      expect(vim.command('map c')).not_to include('tagalong#Trigger')
      vim.set(:filetype, 'javascript.jsx')
      expect(vim.command('map c')).to include('tagalong#Trigger')
    end
  end

  describe "other" do
    let(:filename) { 'test.txt' }

    specify "doesn't work" do
      set_file_contents <<~HTML
        <div>Text</div>
      HTML

      vim.search('div')
      edit('cwspan')

      assert_file_contents <<~HTML
        <span>Text</div>
      HTML
    end
  end
end
