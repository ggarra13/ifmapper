# coding: utf-8
require "rubygems"

VERSION = '2.3.0'
AUTHOR = "Gonzalo Garramuño"
HOMEPAGE = 'http://ggarra13.github.io/ifmapper/en/start.html'
EMAIL = 'ggarra13@gmail.com'

gem = Gem::Specification.new do |s|
        s.name = "ifmapper"
        s.version = VERSION
        s.author = AUTHOR
        s.email = EMAIL
        s.license = 'GPL-2.0'
        s.homepage = HOMEPAGE
        s.summary = 'Interactive Fiction Mapping Tool.'
        s.require_path = "lib"
        s.executables = "IFMapper"
        s.files = ['IFMapper.rbw'] + ['bin/IFMapper'] +
                     ['IFMapper.gemspec'] +
                     ['LICENSE'] +
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
        s.add_runtime_dependency("prawn", "~> 1.0.0", ">= 1.0.0")
        s.extra_rdoc_files = ["HISTORY.txt", "TODO.txt"] +
                                Dir.glob("docs/*/*")
        # s.rubyforge_project = 'ifmapper'
        s.required_ruby_version = '>= 3.0.0'
end
