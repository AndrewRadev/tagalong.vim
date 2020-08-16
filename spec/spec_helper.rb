require 'vimrunner'
require 'vimrunner/rspec'
require_relative './support/vim'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  plugin_path = File.expand_path('.')

  config.start_vim do
    vim = Vimrunner.start_gvim
    vim.set('backspace', 'indent,eol,start')
    vim.add_plugin(plugin_path, 'plugin/tagalong.vim')
    vim
  end
end

RSpec.configure do |config|
  config.include Support::Vim

  config.before :each do
    # Reset to default plugin settings
    vim.command('let g:tagalong_excluded_filetype_combinations = ["eruby.yaml"]')
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = "doc"

  config.order = :random
  Kernel.srand config.seed
end
