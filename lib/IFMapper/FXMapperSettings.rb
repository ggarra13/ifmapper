
begin
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('1.9.0')
    require 'iconv'
  end
rescue LoadError
  $stderr.puts 'Iconv could not be loaded.  Languages other than English will have problems'
  class Iconv
    def initialize(to, from)
    end

    def iconv(a)
      a
    end
  end
end


#
# This class contains the applicatio and map's settings
#
class FXMapperSettings < Hash

  class UnknownParameter < StandardError; end;

  #
  # Return the home location
  #
  # Result: home location for user
  #
  def home
    if ENV['HOME']
      homedir = File.expand_path('~')
      # Ahh... you have to love windows...
    elsif ENV['USERPROFILE']
      homedir = ENV['USERPROFILE']
    elsif ENV['HOMEDRIVE'] and ENV['HOMEPATH']
      homedir = ENV['HOMEDRIVE'] + ENV['HOMEPATH']
    else
      homedir = '.'
    end
    return homedir
  end


  #
  # Write out the preferences to disk.
  #
  # Result: none
  #
  def write
    begin
      file = home + '/.ifmapper'
      f = File.open(file, 'w')
      f.puts YAML.dump(self)
      f.close
    rescue => e
      $stderr.puts "Preferences not saved:"
      $stderr.puts e
    end
  end


  if RUBY_PLATFORM =~ /mswin/
    require 'Win32API'
    LOCALE_USER_DEFAULT = 0x400
    LOCALE_SLANGUAGE    = 0x1001

    FORMAT_MESSAGE_FROM_SYSTEM      = 0x00001000
    FORMAT_MESSAGE_ARGUMENT_ARRAY   = 0x00002000 
    FormatMessage = Win32API.new("kernel32","FormatMessage","LPLLPLP","L")  
    GetLastError  = Win32API.new("kernel32","GetLastError",[],"L") 
    GetLocaleInfo = Win32API.new('Kernel32.dll', 'GetLocaleInfo',
				 %w{l l p i}, 'i')

    LANGUAGES = {
      /English/  => 'en',
      /Spanish/  => 'es',
      # todo1
      /German/   => 'de',
      /Italian/  => 'it',
      /French/   => 'fr',
      /Japanese/ => 'ja',
      /Chinese/  => 'ch',
      /Korean/   => 'ko',
      /Arabic/   => 'ar',
      /Hebrew/   => 'he',
    }
  end


  #
  # Restore user preferences
  #
  # Result: 
  #
  def initialize
    has_yaml = true
    begin
      require 'yaml'
      f = home + '/.ifmapper'
      self.replace( YAML.load_file(f) )
    rescue LoadError
      has_yaml = false
    rescue
    end

    if RUBY_PLATFORM =~ /mswin/
      lcid   = LOCALE_USER_DEFAULT
      lctype = LOCALE_SLANGUAGE
      slanguage = '\0' * 256
      len = 256
      ret = GetLocaleInfo.call lcid, lctype, slanguage, len
      if ret == 0
	error_code = GetLastError.call
	msg = " " * 255
	FormatMessage.call(
            FORMAT_MESSAGE_FROM_SYSTEM +
            FORMAT_MESSAGE_ARGUMENT_ARRAY,
            '',
            error_code,
            0,
            msg,
            255,
            ''
         )
	msg.gsub!(/\000/, '')
	msg.strip!
	$stderr.puts msg
      end
      language = 'en'
      LANGUAGES.each { |re, locale|
	if slanguage =~ re
	  language = locale
	  break
	end
      }
    else
      locale = ENV['LC_ALL'] || ENV['LC_CTYPE'] || 'en_US'
      language = locale[0,2]
    end

    while ARGV.size > 0
      param = ARGV.shift
      case param
      when /^-l(anguage)?$/
	language = ARGV.shift
	language = language[0,2].downcase
	self['Language'] = language
      when /.*\.(?:map|ifm|gmp|t|t3m|inf|trizbort)$/
        self['Map'] = param
      else
	$stderr.puts "Unknown parameter '#{param}'."
	exit(1)
      end
    end

    defaults = {
      # Language
      'Language' => language,

      # Colors
      'BG Color'           => 'dark grey',
      'Arrow Color'        => 'black',
      'Box BG Color'       => 'white',
      'Box Darkness Color' => 'grey',
      'Box Border Color'   => 'black',
      'Box Number Color'   => 'grey',
      
      # Fonts
      'Font Text'          => 'Times',
      'Font Objects'       => 'Times',
      
      # Creation options
      'Create on Connection' => true,
      'Edit on Creation'     => false,
      'Automatic Connection' => true,


      # Display options
      'Use Room Cursor'      => false,
      'Paths as Curves'      => true,

      # Location options
      'Location Tasks'           => true,
      'Location Description'     => true,
      'Location Numbers'         => true,

      # Grid options
      'Grid Boxes' => true,
      'Grid Straight Connections' => true,
      'Grid Diagonal Connections' => false,

      # Map options
      'Map' => nil
    }

    self.replace( defaults.merge(self) )
    language = self['Language']

    begin
      require "IFMapper/locales/#{language}/Messages.rb"
    rescue LoadError
      $stderr.puts "Language '#{language}' was not found. Using English."
      require "IFMapper/locales/en/Messages.rb"
    end

    unless has_yaml
      $stderr.puts ERR_NO_YAML
    end
  end
end
