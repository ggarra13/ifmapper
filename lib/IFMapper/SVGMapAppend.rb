#!/usr/bin/env ruby

require "rexml/document"

mainfile = nil
otherfiles = []

ARGV.each_with_index { |item, index|
    if index == 0
        mainfile = item
    else
        otherfiles.push(item)
    end
}

if mainfile == nil
    $stderr.puts "--- #{File.basename($0)} ---\n\n"
    $stderr.puts "Usage: #{$0} <first map section svg file> [other map section svg files] > outputfile.svg"
    $stderr.puts "If other map section files are omitted then the directory containing the first map section file is searched for suitable matching section files."
    exit(1)

end

if File.exist?(mainfile) && File.file?(mainfile)
    mainxml = File.new( mainfile )
    $stderr.puts "Info: successfully opened first map section file: #{mainfile}"
else
    $stderr.puts "Error: first map section file [#{mainfile}] does not exist or is not a file."
    exit(2)
end

if otherfiles.length == 0
    $stderr.puts "Info: other map section files not specified, searching for suitable matches"
    $stderr.puts "Info: first map section path: #{mainxml.path}"
    $stderr.puts "Info: first map section basename: #{File.basename(mainxml.path)}"

    filename = File.basename(mainxml.path);
    searchdir = File.dirname(mainxml.path);

    $stderr.puts "Info: searching for section files in directory: #{searchdir}"
    Dir.chdir(searchdir);

    # Remove section number from filename if exists.
    cleanfilename = nil

    sectionrindex = filename.rindex("-section");
    if sectionrindex == nil
        # If section number not part of filename then just remove the .svg extension.
        cleanfilename = File.basename(filename, ".*")
    else
        cleanfilename = filename[0, filename.rindex("-section")];
    end

    Dir.glob(cleanfilename + "-section*") { |match|
        if match != filename
            $stderr.puts "Info: found potential matching section file: #{match}"
            otherfiles.push(File.join(Dir.pwd, match))
        end
    }

    otherfiles = otherfiles.sort

else
    $stderr.puts "Info: other map section files specified as arguments: #{otherfiles}"
end

$stderr.puts "---"
$stderr.puts "Info: first map section file: #{File.absolute_path(mainxml.path)}"
$stderr.puts "Info: other map section files: #{otherfiles}"
$stderr.puts "---"

maindoc = REXML::Document.new mainxml

maindocsectionypos = maindoc.elements["svg/use"].attributes["y"];
maindocdefs = maindoc.elements["svg/defs"];
maindocsvg = maindoc.elements["svg"];

$stderr.puts "Info: extracted section vertical offset: #{maindocsectionypos}"

otherfiles.each { |otherfile |
    $stderr.puts "Info: processing other section file: #{otherfile}"

    if File.exist?(otherfile) && File.file?(otherfile)

        otherfilexml = File.new( otherfile )
        otherfiledoc = REXML::Document.new otherfilexml

        otherfiledocheight = otherfiledoc.elements["svg"].attributes["height"];
        otherfiledocwidth = otherfiledoc.elements["svg"].attributes["width"];

        $stderr.puts "Info: -- section full height: #{otherfiledocheight}"

        otherfilesectionid = otherfiledoc.elements["svg/use"].attributes["xlink:href"];

        $stderr.puts "Info: -- section identifier: #{otherfilesectionid}"
        otherfilesectionx = otherfiledoc.elements["svg/use"].attributes["x"];
        otherfiledefid = otherfilesectionid[1, otherfilesectionid.length];

        otherfilesectiondef = otherfiledoc.elements["svg/defs/g[@id='" + otherfiledefid + "']"];

        maindocdefs.add_element otherfilesectiondef;

        maindocheight = maindocsvg.attributes["height"];
        maindocwidth = maindocsvg.attributes["width"];

        maindocsvg.add_element "use", { "xlink:href" => otherfilesectionid, "x" => otherfilesectionx, "y" =>  maindocheight.to_i + maindocsectionypos.to_i }

        maindocheight = maindocheight.to_i + otherfiledocheight.to_i;
        maindocsvg.attributes["height"] = maindocheight;
        maindocdefs.elements["pattern"].attributes["height"] = maindocheight;
        maindocdefs.elements["pattern"].elements["image"].attributes["height"] = maindocheight;
        maindocsvg.elements["path"].attributes["d"] = "'M5,5 l0," + maindocheight.to_s + " l" + maindocwidth + ",0 l0,-" + maindocheight.to_s + " l-" + maindocwidth + ",0'" unless maindocsvg.elements["path"].nil?;
        $stderr.puts "Info: -- updated document height: #{maindocsvg.attributes['height']}"

        if otherfiledocwidth.to_i > maindocwidth.to_i
            maindocsvg.attributes["width"] = otherfiledocwidth;
            maindocdefs.elements["pattern"].attributes["width"] = otherfiledocwidth;
            maindocdefs.elements["pattern"].elements["image"].attributes["width"] = otherfiledocwidth;
            maindocsvg.elements["path"].attributes["d"] = "M5,5 l0," + maindocheight.to_s + " l" + otherfiledocwidth + ",0 l0,-" + maindocheight.to_s + " l-" + otherfiledocwidth + ",0" unless maindocsvg.elements["path"].nil?;
            $stderr.puts "Info: -- updated document width: #{maindocsvg.attributes['width']}"
        end

    else

        $stderr.puts "Warn: -- other map section file [#{otherfile}] does not exist or is not a file. Ignoring this file!"
    end
}

$stderr.puts "Info: outputting combined svg file..."

formatter = REXML::Formatters::Pretty.new(2)
formatter.compact = true
formatter.width = 99999999
formatter.write(maindoc, $stdout)

$stderr.puts "Info: done"
