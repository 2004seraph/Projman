# frozen_string_literal: true

# This file is a part of Projman, a group project orchestrator and management system,
# made by Team 5 for the COM3420 module [Software Hut] at the University of Sheffield.

if defined? Webpacker::Compiler
  shakapacker_compile_lock_path = Module.new do
    def open_lock_file
      lock_file_name = config.root_path.join('tmp', 'shakapacker.lock')
      File.open(lock_file_name, File::CREAT) do |lf|
        return yield lf
      end
    end
  end

  Webpacker::Compiler.prepend shakapacker_compile_lock_path
end
