require 'spec_helper'

RSpec.describe "JSX" do
  let(:filename) { 'test.jsx' }

  specify "Editing a <> react fragment" do
    pending "Old version on CircleCI" if ENV['CIRCLE_CI']

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
    pending "Old version on CircleCI" if ENV['CIRCLE_CI']

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
end
