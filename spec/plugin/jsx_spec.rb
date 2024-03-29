require 'spec_helper'

RSpec.describe "JSX" do
  let(:filename) { 'test.jsx' }

  specify "Editing a <> react fragment" do
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

  specify "Handling nested components with similar names" do
    set_file_contents <<~HTML
      <Example>
        <ExampleItem />
      </Example>
    HTML

    vim.search('<\zsExample>')
    edit('cwChanged')

    assert_file_contents <<~HTML
      <Changed>
        <ExampleItem />
      </Changed>
    HTML
  end

  specify "Handling nested self-closing components with same name" do
    set_file_contents <<~HTML
      <Example>
        <Example />
      </Example>
    HTML

    vim.search('<\zsExample>')
    edit('cwChanged')

    assert_file_contents <<~HTML
      <Changed>
        <Example />
      </Changed>
    HTML
  end
end
