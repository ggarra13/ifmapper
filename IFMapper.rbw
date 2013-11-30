#!/usr/bin/env ruby 


# cd to install path, so modules are found locally
install_loc = $0.sub(/\/?[^\/]*$/, '')
install_loc = '.' if install_loc == ''
Dir.chdir(install_loc)
$LOAD_PATH << './lib'
require 'IFMapper/FXMapperWindow'

if __FILE__ == $0
  # Make application
  application = FXApp.new("IFMapper", "gga")

  # Make window
  m = FXMapperWindow.new(application)

  # Create the application windows
  application.create

  # Optionally, open a map from command-line
  file = FXMapperWindow::default_options['Map']
  if file
    m.open_file(file)
  end

  # Run the application
  begin
    application.run
  rescue => e
    m.autosave
    $stderr.puts e
    $stderr.flush
    raise e
  end
end

