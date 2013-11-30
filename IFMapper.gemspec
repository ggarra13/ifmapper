require "rubygems"

VERSION = '1.2.8'

spec = Gem::Specification.new do |spec|
	spec.name = "ifmapper"
	spec.version = VERSION
	spec.author = "Gonzalo Garramuno" 
	spec.email = 'ggarra13@gmail.com'
	spec.license = 'GPL'
	spec.homepage = 'http://www.rubyforge.org/projects/ifmapper/'
	spec.summary = 'Interactive Fiction Mapping Tool.'
	spec.require_path = "lib"
	spec.executables = "IFMapper"
	spec.files = ['IFMapper.rbw'] + ['bin/IFMapper'] +
		     ['IFMapper.gemspec'] +
                     Dir.glob("lib/IFMapper/*.rb") + 
                     Dir.glob("lib/IFMapper/locales/*/*.rb") + 
                     Dir.glob("lib/IFMapper/locales/*/*.sh") + 
		     Dir.glob("maps/*.ifm") + Dir.glob("maps/*.map") + 
		     Dir.glob("icons/*")
	spec.description = <<-EOF
	Interactive Fiction Mapping Tool.
EOF
	spec.add_dependency("rake-compiler", ">= 0.7.1" )
	spec.add_dependency("fxruby", ">= 1.6.0")
	spec.add_dependency("pdf-writer", ">= 1.1.1")
	spec.extra_rdoc_files = ["HISTORY.txt", "TODO.txt"] + 
				Dir.glob("docs/*/*")
	spec.has_rdoc = true
	spec.rubyforge_project = 'ifmapper'
	spec.required_ruby_version = '>= 1.8.0'
end
