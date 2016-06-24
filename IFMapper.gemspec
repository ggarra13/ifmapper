require "rubygems"

VERSION = '2.0.0'

gem = Gem::Specification.new do |s|
	s.name = "ifmapper"
	s.version = VERSION
	s.author = "Gonzalo Garramuno" 
	s.email = 'ggarra13@gmail.com'
	s.license = 'GPL'
	s.homepage = 'http://www.rubyforge.org/projects/ifmapper/'
	s.summary = 'Interactive Fiction Mapping Tool.'
	s.require_path = "lib"
	s.executables = "IFMapper"
	s.files = ['IFMapper.rbw'] + ['bin/IFMapper'] +
		     ['IFMapper.gemspec'] +
                     Dir.glob("lib/IFMapper/*.rb") + 
                     Dir.glob("lib/IFMapper/locales/*/*.rb") + 
                     Dir.glob("lib/IFMapper/locales/*/*.sh") + 
		     Dir.glob("maps/*.ifm") + Dir.glob("maps/*.map") + 
		     Dir.glob("icons/*")
	s.description = <<-EOF
	Interactive Fiction Mapping Tool.
EOF
	s.add_runtime_dependency("rake-compiler", "~> 0.7.1", ">= 0.7.1" )
	s.add_runtime_dependency("fxruby", "~> 1.6.0", ">= 1.6.0")
	s.add_runtime_dependency("pdf-writer", "~> 1.1.1", ">= 1.1.1")
	s.extra_rdoc_files = ["HISTORY.txt", "TODO.txt"] + 
				Dir.glob("docs/*/*")
	s.has_rdoc = true
	s.rubyforge_project = 'ifmapper'
	s.required_ruby_version = '>= 1.8.0'
end
