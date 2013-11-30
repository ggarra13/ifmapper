

#
# A simple class to show a filerequester that remembers the
# last directory visited.
#
class FXMapFileDialog < FXFileDialog
  @@last_path = nil

  KNOWN_LOAD_EXTENSIONS = [
    "#{EXT_MAP_FILES} (*.map,*.gmp,*.ifm,*.inf,*.t,*.t3m,*.trizbort)",
    EXT_ALL_FILES,
  ]

  KNOWN_SAVE_EXTENSIONS = [
    "#{EXT_MAP_FILES} (*.map,*.gmp,*.ifm,*.inf,*.inform,*.t,*.t3m,*.trizbort)",
    EXT_ALL_FILES,
  ]


  def initialize(parent, title, patterns = KNOWN_LOAD_EXTENSIONS)
    opts = 0
    if RUBY_PLATFORM =~ /mswin/
      opts |= FILEMATCH_NOESCAPE
    end
    super(parent, title, opts)
    setPatternList(patterns)
    self.directory = @@last_path if @@last_path
    if execute != 0
      @@last_path = filename.sub(/[\\\/][^\\\/]+$/, '')
    end
  end
end

