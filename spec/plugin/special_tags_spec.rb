require 'spec_helper'

RSpec.describe "Special tags" do
  let(:filename) { 'test.html' }

  specify "XML-style namespaces with :" do
    set_file_contents <<~HTML
      <namespace:tag attribute="value">
        <span>Text</span>
      </namespace:tag>
    HTML

    vim.search('namespace')
    edit('cWscope:name')

    assert_file_contents <<~HTML
      <scope:name attribute="value">
        <span>Text</span>
      </scope:name>
    HTML
  end

  specify "react-style namespaces with ." do
    set_file_contents <<~HTML
      <MyComponents.DatePicker color="blue">
        <span>Text</span>
      </MyComponents.DatePicker>
    HTML

    vim.search('DatePicker')
    edit('cwDateTimePicker')

    assert_file_contents <<~HTML
      <MyComponents.DateTimePicker color="blue">
        <span>Text</span>
      </MyComponents.DateTimePicker>
    HTML

    vim.search('<\zsMyComponents')
    edit('cWUtil.OtherStuff')

    assert_file_contents <<~HTML
      <Util.OtherStuff color="blue">
        <span>Text</span>
      </Util.OtherStuff>
    HTML
  end

  specify "editing the closing tag" do
    set_file_contents <<~HTML
      <MyComponents.DatePicker color="blue">
        <span>Text</span>
      </MyComponents.DatePicker>
    HTML

    vim.search('\/MyComponents\.\zsDatePicker')
    edit('cwDateTimePicker')

    assert_file_contents <<~HTML
      <MyComponents.DateTimePicker color="blue">
        <span>Text</span>
      </MyComponents.DateTimePicker>
    HTML

    vim.search('<\/\zsMyComponents')
    edit('cWUtil.OtherStuff>')

    assert_file_contents <<~HTML
      <Util.OtherStuff color="blue">
        <span>Text</span>
      </Util.OtherStuff>
    HTML
  end
end
