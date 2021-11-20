require 'spec_helper'

RSpec.describe "JSX" do
  let(:filename) { 'test.jsx' }

  specify "Editing a <> react fragment" do
    pending "Old Vim version on CI" if ENV['CI']

    set_file_contents <<~HTML
      <>
        <span>Text</span>
      </>
    HTML

    vim.search('<\zs>')
    edit('iFoo.Bar baz={bla}')

    assert_file_contents <<~HTML
      <Foo.Bar baz={bla}>
        <span>Text</span>
      </Foo.Bar>
    HTML
  end

  specify "Editing a </> react fragment" do
    pending "Old Vim version on CI" if ENV['CI']

    set_file_contents <<~HTML
      <>
        <span>Text</span>
      </>
    HTML

    vim.search('<\/\zs>')
    edit('iFoo.Bar')

    assert_file_contents <<~HTML
      <Foo.Bar>
        <span>Text</span>
      </Foo.Bar>
    HTML
  end

  specify "Ignoring self-closing components" do
    set_file_contents <<~HTML
      <Example>
        <Example />
      </Example>
    HTML

    vim.search('<\zsExample />')
    edit('cwChanged')

    assert_file_contents <<~HTML
      <Example>
        <Changed />
      </Example>
    HTML
  end
end
