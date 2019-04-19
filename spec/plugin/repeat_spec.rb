require 'spec_helper'

# Note: Not actually using `.`, since repeat.vim is not installed for the test
# suite.
RSpec.describe "repeating" do
  let(:filename) { 'test.html' }

  specify "leaving other content intact" do
    pending "Doesn't seem to work on TravisCI" if ENV['TRAVIS_CI']

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
    pending "Doesn't seem to work on TravisCI" if ENV['TRAVIS_CI']

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
end
