require 'spec_helper'

# Note: Not actually using `.`, since repeat.vim is not installed for the test
# suite.
RSpec.describe "repeating" do
  let(:filename) { 'test.html' }

  specify "leaving other content intact" do
    set_file_contents <<~EOF
      <ul>
        <span class="first">One</span>
        <span class="second">Two</span>
        <span class="third">Three</span>
      </ul>
    EOF

    vim.search('span.*One')
    edit('cwli')

    vim.search('span.*Two')
    vim.command('call tagalong#Reapply()')

    vim.search('span.*Three')
    vim.command('call tagalong#Reapply()')

    vim.write

    assert_file_contents <<~EOF
      <ul>
        <li class="first">One</li>
        <li class="second">Two</li>
        <li class="third">Three</li>
      </ul>
    EOF
  end

  specify "removing other content" do
    set_file_contents <<~EOF
      <ul>
        <span class="first">One</span>
        <span class="second">Two</span>
        <span class="third">Three</span>
      </ul>
    EOF

    vim.search('span.*One')
    edit('ci<li')

    vim.search('span.*Two')
    vim.echo('tagalong#Reapply()')

    vim.search('span.*Three')
    vim.echo('tagalong#Reapply()')

    vim.write

    assert_file_contents <<~EOF
      <ul>
        <li>One</li>
        <li>Two</li>
        <li>Three</li>
      </ul>
    EOF
  end

  specify "repeating the last normal operation if tag editing does not apply" do
    set_file_contents <<~EOF
      <div>Text</div>
      something
    EOF

    vim.search('div')
    edit('cwarticle')

    vim.search('something')
    vim.echo('tagalong#Reapply()')
    vim.write

    assert_file_contents <<~EOF
      <article>Text</article>
      article
    EOF
  end

  specify "repeating the last normal operation if tag editing applied to other part of tag" do
    set_file_contents <<~EOF
      <span class="one">One</span>
      <span class="two">Two</span>
      <span class="three">Three</span>
    EOF

    vim.search('span class="one"')
    edit('cwli')
    vim.search('two')
    vim.echo('tagalong#Reapply()')
    vim.search('span class="three"')
    vim.echo('tagalong#Reapply()')

    vim.write

    assert_file_contents <<~EOF
      <li class="one">One</li>
      <span class="li">Two</span>
      <li class="three">Three</li>
    EOF
  end
end
