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

    # JSX support not built-in in earlier versions, so matchit support not
    # built-in. We can't check if it really works, but we can check if the
    # mapping is there, at least.
    specify "has mapping for 'javascript.jsx'" do
      set_file_contents <<~HTML
        <div>Text</div>
      HTML

      vim.set(:filetype, 'javascript.jsx')
      expect(vim.command('map c')).to include('tagalong#Trigger')
    end

    specify "has mapping for 'javascriptreact'" do
      set_file_contents <<~HTML
        <div>Text</div>
      HTML

      vim.set(:filetype, 'javascriptreact')
      expect(vim.command('map c')).to include('tagalong#Trigger')
    end
  end

  describe "ERB" do
    let(:filename) { 'test.erb' }

    specify "works" do
      set_file_contents <<~HTML
        <div>Text</div>
      HTML

      vim.search('div')
      edit('cwarticle')

      assert_file_contents <<~HTML
        <article>Text</article>
      HTML
    end

    specify "doesn't affect templating" do
      set_file_contents <<~HTML
        <div class="<%= class_list %>">Text</div>
      HTML

      vim.search('class_list')
      edit('cwlist_of_classes')

      assert_file_contents <<~HTML
        <div class="<%= list_of_classes %>">Text</div>
      HTML
    end
  end

  describe "PHP" do
    let(:filename) { 'test.php' }

    specify "works" do
      set_file_contents <<~HTML
        <div><?php echo "OK" ?></div>
      HTML

      vim.search('div')
      edit('cwarticle')

      assert_file_contents <<~HTML
        <article><?php echo "OK" ?></article>
      HTML
    end

    specify "doesn't affect templating" do
      set_file_contents <<~HTML
        <div class="<?= class_list ?>">Text</div>
      HTML

      vim.search('class_list')
      edit('cwlist_of_classes')

      assert_file_contents <<~HTML
        <div class="<?= list_of_classes ?>">Text</div>
      HTML
    end
  end

  describe "Vue" do
    let(:filename) { 'test.vue' }

    specify "works" do
      set_file_contents <<~HTML
        <div>Text</div>
      HTML
      vim.set 'filetype', 'vue'

      vim.search('div')
      edit('cwarticle')

      assert_file_contents <<~HTML
        <article>Text</article>
      HTML
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

  describe "excluding filetypes" do
    let(:filename) { 'test.html' }

    specify "allows excluding filetypes with a setting" do
      vim.command('let g:tagalong_excluded_filetype_combinations = ["html"]')

      set_file_contents <<~HTML
        <div>Text</div>
      HTML

      vim.search('div')
      edit('cwspan')

      # Doesn't work anymore
      assert_file_contents <<~HTML
        <span>Text</div>
      HTML
    end
  end
end
