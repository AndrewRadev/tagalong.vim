module Support
  module Vim
    def set_file_contents(string)
      write_file(filename, string)
      vim.edit!(filename)
    end

    def edit(keys)
      keys = keys.gsub('"', '\"')
      result = vim.echo("feedkeys(\"#{keys}\\<esc>\", 't')")
      fail result if result != "0"
      vim.write
    end

    def assert_file_contents(string)
      expect(IO.read(filename)).to eq(string)
    end
  end
end
