require 'IFMapper/MapPrinting'
require 'rexml/document'
require 'rexml/cdata'

DEBUG_OUTPUT    = false
SVG_ZOOM        = 1
SVG_ROOM_WIDTH  = W  * SVG_ZOOM
SVG_ROOM_HEIGHT = H  * SVG_ZOOM
SVG_ROOM_WS     = WS * SVG_ZOOM
SVG_ROOM_HS     = HS * SVG_ZOOM

class SVGUtilities
  
  def self.new_svg_doc ( width, height)
    svg = REXML::Document.new
    svg << REXML::XMLDecl.new

    svg.add_element "svg", {
        "width"        => width,
        "height"    => height,
        "version"    => "1.1",
        "xmlns"        => "http://www.w3.org/2000/svg",
        "xmlns:xlink" => "http://www.w3.org/1999/xlink"}
    return svg
    
  end
  
  def self.add_text( svg, x, y, font_size, text, opts, fill_colour )
    if DEBUG_OUTPUT; puts "svg::FXMap::svg_draw_name_text:" end
    y = y + font_size

    t = svg.root.add_element "text", {
    "x"            => x,
    "y"            => y,
    "style"        => "font-size:" + font_size.to_s() + "pt;fill:#" + fill_colour.to_s()}

    t.text = text

    return [svg, x, y]
  end  
        
  def self.num_text_lines ( text, maxlinelength )
    if text and not text == ''
      return SVGUtilities::break_text_lines(text.chomp().strip(), maxlinelength).length
    else
      return 0
    end
  end

  def self.break_text_lines( text, maxlinelength )
    if DEBUG_OUTPUT; printf("SVGUtilities::break_text_lines:text=%s\r\n", text) end
    
    out = Array.new

    max_chars = maxlinelength
    words = text.split(" ")
    cur_str = ""

    words.each { |word|
      new_len = cur_str.length + word.length
      if DEBUG_OUTPUT; printf("SVGUtilities::break_text_lines:current word: %s :: new_len: %d\r\n", word, new_len) end
      new_len = cur_str.length + word.length
      if new_len <= max_chars
        cur_str = cur_str + word + " "
      else
        out << cur_str
        cur_str = "" + word + " "
      end
    }
    out << cur_str

    return out
  end
  
  def self.get_compass_svg_group()
    
    file = File.new( "icons/compass.svg" )
    doc = REXML::Document.new file
    
    newgroup = REXML::Element.new "g"
    newgroup.attributes["id"] = "compass"
    
    doc.root.elements.each {|elem|
      newgroup.add_element(elem)  
    }
    
    return newgroup
        
  end
  
  def self.add_compass(svg)
    compassgroup = SVGUtilities::get_compass_svg_group()
        
    defs = svg.root.add_element "defs"
    
    defs.add_element compassgroup
    
    return svg
  end
  
  
  def self.svg_add_script( svg, opts )
    svg.root.attributes["onload"] = "Init(evt)"

    script = svg.root.add_element "script", {
    "type"            => "text/ecmascript" }

    script.add( REXML::CData.new("
    var SVGDocument = null;
    var SVGRoot = null;

    function Init(evt)
    {
       SVGDocument = evt.target.ownerDocument;
       SVGRoot = SVGDocument.documentElement;
    }

    function ToggleOpacity(evt, targetId)
    {
       var newTarget = evt.target;
       if (targetId)
       {
          newTarget = SVGDocument.getElementById(targetId);
       }
       var newValue = newTarget.getAttributeNS(null, 'opacity')

       if ('0' != newValue)
       {
          newValue = '0';
       }
       else
       {
          newValue = '1';
       }
       newTarget.setAttributeNS(null, 'opacity', newValue);

       if (targetId)
       {
          SVGDocument.getElementById(targetId + 'Exception').setAttributeNS(null, 'opacity', '1');
       }
    }
    "))

    return svg;
  end

  def self.add_titles( svg, opts, x, y, font_size, mapname, mapcreator )
    if DEBUG_OUTPUT; puts "svg::SVGUtilities::add_titles" end

    if opts['print_title'] == true
      if not mapname or mapname == ''
        if DEBUG_OUTPUT; puts "svg::SVGUtilities::add_titles:name is empty, not printing" end
      else
        svg, x, y = SVGUtilities::add_text(svg, x, y, font_size*1.5, mapname, opts, '000000')
        y = y + (opts['name_line_spacing'] * 4)
      end
    end

    if opts['print_creator'] == true
      if not mapcreator or mapcreator == ''
        if DEBUG_OUTPUT; puts "svg::SVGUtilities::add_titles:creator is empty, not printing" end
      else
        svg, x, y = SVGUtilities::add_text(svg, x, y, font_size*0.85, 'Map ' + opts['creator_prefix'] + mapcreator, opts, '000000')
        y = y + (opts['name_line_spacing'] * 4)
      end
    end
    
    return [svg, x, y]
  end
  
end
#
# Open all the map class and add all SVG methods there
# Gotta love Ruby's flexibility to just inject in new methods.
#
class FXConnection
  def _cvt_pt(p, opts)
    if DEBUG_OUTPUT; puts "svg::FXConnection::_cvt_pt" end
    x = (p[0] - WW / 2.0) / WW.to_f
    y = (p[1] - HH / 2.0) / HH.to_f
    x = x * opts['ww'] + opts['margin'] + opts['w'] / 2.0
    y = y * opts['hh'] + opts['margin'] + opts['hs'] - 2
    return [x, y]
  end

  def svg_draw_arrow(svg, opts, x1, y1, x2, y2)
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_arrow:#{x1},#{y1},#{x2},#{y2}" end
    return if @dir == BOTH

    pt1, d = _arrow_info( x1, y1, x2, y2, 0.5 )

    if DEBUG_OUTPUT; printf("svg::FXConnection::svg_draw_arrow: pt1[0]=%0.01f,pt1[1]=%0.01f,d[0]=%0.01f,d[1]=%0.01f\r\n", pt1[0], pt1[1], d[0], d[1]) end

    mx = pt1[0];
    my = pt1[1];

    if DEBUG_OUTPUT; printf("svg::FXConnection::svg_draw_arrow: mx=%0.01f,my=%0.01f\r\n",mx,my) end

    lx1 = pt1[0] + d[0]
    ly1 = pt1[1] + d[1]

    if DEBUG_OUTPUT; printf("svg::FXConnection::svg_draw_arrow: lx1=%0.01f,ly1=%0.01f\r\n",lx1,ly1) end

    lx2 = pt1[0] + d[1]
    ly2 = pt1[1] - d[0]

    if DEBUG_OUTPUT; printf("svg::FXConnection::svg_draw_arrow: lx2=%0.01f,ly2=%0.01f\r\n",lx2,ly2) end

    points =  sprintf("%0.01f", mx) + "," + sprintf("%0.01f", my) + " "
    points << sprintf("%0.01f", lx1) + "," + sprintf("%0.01f", ly1) + " "
    points << sprintf("%0.01f", lx2) + "," + sprintf("%0.01f", ly2) + " "

    svg.root.add_element "polygon", {
        "style"        => sprintf("stroke:%s;stroke-width:%s;fill:%s",opts['arrow_line_colour'],opts['arrow_line_width'],opts['arrow_fill_colour']),
        "points"    => points }

  end

  def svg_draw_complex_as_bspline( svg, opts )
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_complex_as_bspline" end
    p = []
    p << _cvt_pt(@pts[0], opts)
    p << p[0]
    p << p[0]
    @pts.each { |pt|
      p << _cvt_pt(pt, opts)
    }
    p << p[-1]
    p << p[-1]
    p << p[-1]
    return FXSpline::bspline(p)
  end

  def svg_draw_complex_as_lines( svg, opts )
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_complex_as_lines" end
    p = []
    @pts.each { |pt|
      p << _cvt_pt(pt, opts)
    }
    return p
  end

  def svg_draw_door( svg, x1, y1, x2, y2 , opts)
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_arrow:#{x1},#{y1},#{x2},#{y2}" end
    v = [ (x2-x1), (y2-y1) ]
    t = 10 / Math.sqrt(v[0]*v[0]+v[1]*v[1])
    v = [ v[0]*t, v[1]*t ]
    m = [ (x2+x1)/2, (y2+y1)/2 ]
    x1, y1 = [m[0] + v[1], m[1] - v[0]]
    x2, y2 = [m[0] - v[1], m[1] + v[0]]

    v = [ v[0] / 3, v[1] / 3]

    poly = svg.root.add_element "polygon", {
        "style"            => sprintf("stroke:%s;stroke-width:%s", opts['door_line_colour'],opts['door_line_width']),
        "points"        => sprintf("%0.01f,%0.01f %0.01f,%0.01f %0.01f,%0.01f %0.01f,%0.01f",
                                    x1-v[0], y1-v[1], x1+v[0], y1+v[1], x2+v[0], y2+v[1], x2-v[0], y2-v[1]) }

    if @type == LOCKED_DOOR
      poly.attributes["style"] << sprintf(";fill:%s", opts['door_line_colour'])
    else
      poly.attributes["style"] << ";fill:none"
    end
  end

  def svg_draw_complex( svg, opts, sx ,sy )
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_complex" end
    if opts['Paths as Curves']
      if @room[0] == @room[1]
        dirA, dirB = dirs
        if dirA == dirB
          p = svg_draw_complex_as_lines( svg, opts )
        else
          p = svg_draw_complex_as_bspline( svg, opts )
        end
      else
        p = svg_draw_complex_as_bspline( svg, opts )
      end
    else
      p = svg_draw_complex_as_lines( svg, opts )
    end

    p.each { |pt|
        pt[0] = pt[0] + sx
        pt[1] = pt[1] + sy }

    d = "M" + sprintf("%0.01f", p[0][0]) + "," + sprintf("%0.01f", p[0][1]) + " "

    p.each { |pt|
      d = d + "L" + sprintf("%0.01f", pt[0]) + "," + sprintf("%0.01f", pt[1]) + " " }

    path = svg.root.add_element "path", {
        "style"        => sprintf("stroke:%s;stroke-width:%s;fill:none",opts['conn_line_colour'],opts['conn_line_width']),
        "d"            => d }

    if @type == SPECIAL
      path.attributes["style"] << ";stroke-dasharray:9,5"
    end

    x1, y1 = [p[0][0], p[0][1]]
    x2, y2 = [p[-1][0], p[-1][1]]

    svg_draw_arrow(svg, opts, x1, y1, x2, y2)

    if @type == LOCKED_DOOR or @type == CLOSED_DOOR
      t = p.size / 2
      x1, y1 = [ p[t][0], p[t][1] ]
      x2, y2 = [ p[t-2][0], p[t-2][1] ]

      svg_draw_door(svg, x1, y1, x2, y2, opts)
    end
  end

  def svg_draw_simple(svg, opts, sx, sy)
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_simple" end
    return if not @room[1]

    dir    = @room[0].exits.index(self)
    x1, y1 = @room[0].svg_corner(opts, self, dir)
    x2, y2 = @room[1].svg_corner(opts, self)

    x1 = x1 + sx;
    x2 = x2 + sx;
    y1 = y1 + sy;
    y2 = y2 + sy;

    line = svg.root.add_element "line", {
        "x1"        => x1,
        "y1"        => y1,
        "x2"        => x2,
        "y2"        => y2,
        "style"        => sprintf("stroke:%s;stroke-width:%s", opts['conn_line_colour'],opts['conn_line_width']) }

    if @type == SPECIAL
      line.attributes["style"] << ";stroke-dasharray:9,5"
    end

    svg_draw_arrow(svg, opts, x1, y1, x2, y2)
    if @type == LOCKED_DOOR or @type == CLOSED_DOOR
      svg_draw_door(svg, x1, y1, x2, y2, opts)
    end
  end

  #
  # Draw the connection text next to the arrow ('I', 'O', etc)
  #
  def svg_draw_text(svg, x, y, dir, text, arrow)
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_text:#{x},#{y},#{text}" end
    if dir == 7 or dir < 6 and dir != 1
      if arrow and (dir == 0 or dir == 4)
        x += 5
      end
      x += 2.5
    elsif dir == 6 or dir == 1
      x -= 7.5
    end

    if dir > 5 or dir < 4
      if arrow and (dir == 6 or dir == 2)
        y -= 5
      end
      y -= 2.5
    elsif dir == 4 or dir == 5
      y += 7.5
    end

    font_size = 6

    t = svg.root.add_element "text", {
        "x"                => x,
        "y"                => y,
        "style"            => "font-size:" + font_size.to_s() + "pt"}

    t.text = text;
  end

  def svg_draw_exit_text(pdf, opts, sx, sy)
    if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw_exit_text" end
    if @exitText[0] != 0
      dir  = @room[0].exits.index(self)
      x, y = @room[0].svg_corner(opts, self, dir)
      x = x + sx
      y = y + sy
      svg_draw_text( pdf, x, y, dir,
           EXIT_TEXT[@exitText[0]], @dir == BtoA)
    end

    if @exitText[1] != 0
      dir  = @room[1].exits.rindex(self)
      x, y = @room[1].svg_corner(opts, self, dir)
      x = x + sx
      y = y + sy
      svg_draw_text( pdf, x, y, dir,
            EXIT_TEXT[@exitText[1]], @dir == AtoB)
    end
  end

  def svg_draw(svg, opts, x, y)
    if DEBUG_OUTPUT; printf("svg::FXConnection::svg_draw:draw_connections=%s\r\n", opts['draw_connections'].to_s()) end
    if opts['draw_connections'] == true
      if DEBUG_OUTPUT; puts "svg::FXConnection::svg_draw" end

      svg_draw_exit_text(svg, opts, x, y)
    
      if @pts.size > 0
        svg_draw_complex(svg, opts, x, y)
      else
        svg_draw_simple(svg, opts, x, y)
      end
    end
  end
end


class FXRoom
  def svg_corner( opts, c, idx = nil )
    if DEBUG_OUTPUT; puts "svg::FXRoom::svg_corner" end
    x, y = _corner(c, idx)

    ww = opts['ww']
    hh = opts['hh']
    w = opts['w']
    h = opts['h']

    x = @x * ww + x * w + opts['margin']
    y = @y * hh + y * h + opts['margin']

    return [x, y]
  end

  def svg_draw_box( svg, opts, idx, sx, sy )
    if DEBUG_OUTPUT; puts "svg::FXRoom::svg_draw_box" end
    x = sx + (@x * opts['ww']) + opts['margin']
    y = sy + (@y * opts['hh']) + opts['margin']

    if DEBUG_OUTPUT; printf("svg::FXRoom::svg_draw_box[x=%s,y=%s,w=%s,h=%s]\r\n", x,y,opts['w'],opts['h']) end

    roomrect = svg.root.add_element "rect", {
        "x"            => x,
        "y"            => y,
        "width"        => opts['w'],
        "height"    => opts['h'],
        "style"        => sprintf("stroke:%s;stroke-width:%s", opts['room_line_colour'],opts['room_line_width'])}

    if @darkness
      if DEBUG_OUTPUT; puts "svg::FXRoom::svg_draw_box:DARKNESS" end
      roomrect.attributes["style"] << ";fill:gray"
    else
      if DEBUG_OUTPUT; puts "svg::FXRoom::svg_draw_box:not darkness" end
      roomrect.attributes["style"] << ";fill:none"
    end

    if opts['print_room_nums'] == true

      # Add the room number to the bottom right hand corner!

      pad = 2
      font_size = 8
      numbox_width = (pad*2) + (3*font_size)
      numbox_height = (pad*2)+font_size
      numbox_x = (x + opts['w']) - numbox_width
      numbox_y = (y + opts['h']) - numbox_height

      numbox_rect = svg.root.add_element "rect", {
          "x"            => numbox_x,
          "y"            => numbox_y,
          "width"        => numbox_width,
          "height"        => numbox_height,
          "style"        => sprintf("stroke:%s;stroke-width:%s;fill:%s", opts['num_line_colour'],opts['num_line_width'],opts['num_fill_colour']) }

      numtext_x = numbox_x + pad
      numtext_y = numbox_y + font_size + pad

      if idx < 100
        numtext_x += font_size
      end

      if idx < 10
        numtext_x += font_size
      end

      numtext = svg.root.add_element "text", {
          "x"            => numtext_x,
          "y"            => numtext_y,
          "style"         => "font-size:" + font_size.to_s() + "pt" }

      numtext.text = (idx+1).to_s()

    end
  end

  def svg_draw_text( svg, opts, x, y, text, font_size )
    if DEBUG_OUTPUT; printf("svg::FXRoom::svg_draw_text:text=%s\r\n", text) end

    t = svg.root.add_element "text", {
        "x"            => x,
        "y"            => y,
        "style"        => "font-size:" + font_size.to_s() + "pt"}

    max_chars = opts['text_max_chars']
    words = text.split(" ")
    dy = 0
    ypos = 0
    lasty = opts['h'] - opts['text_margin']
    cur_str = ""

    words.each { |word|
      new_len = cur_str.length + word.length
      if DEBUG_OUTPUT; printf("current word: %s :: new_len: %d\r\n", word, new_len) end
      new_len = cur_str.length + word.length
      if new_len <= max_chars
          cur_str = cur_str + word + " "
      else
        ypos = ypos + font_size + opts['text_line_spacing']
        if ypos >= lasty
            break
        end
        tspan = t.add_element "tspan", {
            "x"        => x,
            "dy"    => dy }
        tspan.text = cur_str
        if dy == 0
            dy = font_size + opts['text_line_spacing']
        end
        cur_str = "" + word + " "
      end
    }

    if ypos < lasty
      tspan = t.add_element "tspan", {
          "x"        => x,
          "dy"    => dy }
      tspan.text = cur_str
    end

    return [x, y+ypos]
  end

  def svg_draw_objects(svg, opts, x, y)
    if DEBUG_OUTPUT; puts "svg::FXRoom::svg_draw_objects" end
    font_size = 6
    objs = @objects.split("\n")
    objs = objs.join(', ')
    return svg_draw_text( svg, opts, x, y, objs, font_size )
  end

  def svg_draw_name(svg, opts, sx, sy)
    if DEBUG_OUTPUT; printf("svg::FXRoom::svg_draw_name:name=%s\r\n", @name) end

    x = sx + (@x * opts['ww']) + opts['margin'] + opts['text_margin']
    y = sy + (@y * opts['hh']) + opts['margin'] + opts['text_margin']
    font_size = 8
    y = y + font_size

    return svg_draw_text( svg, opts, x, y, @name, font_size )
  end

  def svg_draw_interactive( svg, opts, idx, sx, sy, section_idx )
    if DEBUG_OUTPUT; puts "svg::FXRoom::svg_draw_interactive" end

    if (@objects and not @objects == '') or (@tasks and not @tasks == '') or (@comment and not @comment == '')

      x = sx + (@x * opts['ww']) + opts['margin'] + opts['w']
      y = sy + (@y * opts['hh']) + opts['margin']

      x1 = x - opts['corner_size']
      y1 = y

      x2 = x
      y2 = y + opts['corner_size']

      poly = svg.root.add_element "polygon", {
      "style"            => sprintf("stroke:%s;stroke-width:%s;fill:%s", opts['corner_line_colour'],opts['corner_line_width'],opts['corner_fill_colour']),
      "points"        => sprintf("%0.01f,%0.01f %0.01f,%0.01f %0.01f,%0.01f", x, y, x1, y1, x2, y2),
      "onclick"        => "ToggleOpacity(evt, \"section"+section_idx.to_s()+"room"+idx.to_s()+"\")" }

      objs_font_size = opts['objects_font_size']
      num_chars_per_line = opts['objects_width'] / (objs_font_size)

      numObjsLines = 0
      numTaskLines = 0
      numCommLines = 0

      if(@objects)
        numObjsLines = SVGUtilities::num_text_lines(@objects, num_chars_per_line);
      end

      if(@tasks)
        numTaskLines = SVGUtilities::num_text_lines(@tasks, num_chars_per_line);
      end

      if(@comment)
        numCommLines = SVGUtilities::num_text_lines(@comment, num_chars_per_line);
      end

      if(numObjsLines > 0)
        numObjsLines = numObjsLines + 2
      end

      if(numTaskLines > 0)
        numTaskLines = numTaskLines + 2
      end

      if(numCommLines > 0)
        numCommLines = numCommLines + 2
      end

      lines = numObjsLines + numTaskLines + numCommLines

      objs_height = (lines+1) * (objs_font_size + opts['text_line_spacing'])

      g = svg.root.add_element "g", {
      "id"            => "section"+section_idx.to_s()+"room"+idx.to_s(),
      "opacity"        => "0" }

      rect_x = x - opts['objects_width'] - opts['corner_size']
      rect_y = y + opts['corner_size']

      g.add_element "rect", {
      "x"                => rect_x,
      "y"                => rect_y,
      "width"            => opts['objects_width'],
      "height"        => objs_height,
      "z-index"        => "1",
      "style"            => sprintf("stroke:%s;stroke-width:%s;fill:%s", opts['objs_line_colour'],opts['objs_line_width'],opts['objs_fill_colour']) }

      text_x = rect_x + opts['text_margin']
      text_y = rect_y + opts['text_margin'] + objs_font_size

      if @objects and not @objects == ''
        t1 = g.add_element "text", {
        "x"            => text_x,
        "y"            => text_y,
        "style"        => "font-size:" + objs_font_size.to_s() + "pt;font-weight:bold" }
        t1.text = "Objects:"

        text_y = text_y + objs_font_size + opts['text_line_spacing']
        objs_lines = SVGUtilities::break_text_lines(@objects, num_chars_per_line)
        text_x, text_y = svg_draw_interactive_objects( g, opts, text_x, text_y, objs_font_size, objs_lines)
        text_y = text_y + objs_font_size + opts['text_line_spacing']
      end

      if @tasks and not @tasks == ''
        t2 = g.add_element "text", {
        "x"            => text_x,
        "y"            => text_y,
        "style"        => "font-size:" + objs_font_size.to_s() + "pt;font-weight:bold" }
        t2.text = "Tasks:"

        text_y = text_y + objs_font_size + opts['text_line_spacing']
        tasks_lines = SVGUtilities::break_text_lines(@tasks, num_chars_per_line)
        text_x, text_y = svg_draw_interactive_objects( g, opts, text_x, text_y, objs_font_size, tasks_lines)
        text_y = text_y + objs_font_size + opts['text_line_spacing']
      end

      if @comment and not @comment == ''
        t2 = g.add_element "text", {
        "x"     => text_x,
        "y"     => text_y,
        "style"   => "font-size:" + objs_font_size.to_s() + "pt;font-weight:bold" }
        t2.text = "Comments:"

        text_y = text_y + objs_font_size + opts['text_line_spacing']
        comments_lines = SVGUtilities::break_text_lines(@comment, num_chars_per_line)
        text_x, text_y = svg_draw_interactive_objects( g, opts, text_x, text_y, objs_font_size, comments_lines)
        text_y = text_y + objs_font_size + opts['text_line_spacing']
      end
    end
  end


  def svg_draw_interactive_objects( group, opts, x, y, font_size, lines)
    if DEBUG_OUTPUT; printf("svg::FXRoom::svg_draw_interactive_objects\r\n") end

    t = group.add_element "text", {
        "x"            => x,
        "y"            => y,
        "style"        => "font-size:" + font_size.to_s() + "pt"}

    dy = 0
    ypos = 0

    lines.each { |obj|

      ypos = ypos + font_size + opts['text_line_spacing']
      tspan = t.add_element "tspan", {
          "x"        => x,
          "dy"    => dy }
      tspan.text = obj
      if dy == 0
        dy = font_size + opts['text_line_spacing']
      end
    }

    return [x, y+ypos]
  end

  def svg_draw( svg, opts, idx, x, y )
    if DEBUG_OUTPUT; puts "svg::FXRoom::svg_draw" end

    if (!((opts['draw_connections'] == false) && (@name =~ /Shortcut to.*/i)))
      svg_draw_box( svg, opts, idx, x, y )

      if ((opts['draw_roomnames'] == true) || (@name =~ /Shortcut to.*/i) || (idx == 0))

        # Even if we're not printing location names, print the "Shortcut to"
        # part of any locations which start with that text.  This convention of
        # a room named "Shortcut to <another location>" is for the sole purpose
        # of allowing additional connections to be collected which are then fwd'd
        # to the named location, because currently IFMapper can only provide
        # support for up to eight cardinal / ordinal directions which can be a
        # problem for large locations.
        if ((opts['draw_roomnames'] == false) && (@name =~ /(Shortcut to).*/i))
          @name = $1
        end

        x, y = svg_draw_name( svg, opts, x, y )
      end
    end
  end

end



class FXSection

  def svg_draw_grid(pdf, opts, w, h )
    if DEBUG_OUTPUT; puts "svg::FXSection::svg_draw_grid" end
    (0...w).each { |xx|
      (0...h).each { |yy|
        x = xx * opts['ww'] + opts['ws_2'] + opts['margin_2']
        y = yy * opts['hh'] + opts['hs_2'] + opts['margin_2']
      }
    }
  end


  def svg_draw_section_name( svg, opts, x, y )
    return [x,y] if not @name or @name == ''
    
    font_size = opts['name_font_size']

    if opts['print_section_names'] == true
      svg, x, y = SVGUtilities::add_text( svg, x, y, font_size, @name, opts, '2F4F4F' )
      y = y + opts['name_line_spacing']
    end

    if opts['draw_sectioncomments'] == true

      if not @comments or @comments == ''
        if DEBUG_OUTPUT; puts "svg::FXSection::svg_draw_section_name:section comments is empty, not printing" end
      else
        num_chars_per_line = svg.root.attributes["width"].to_i() / (font_size*0.75)
        
        brokenlines = @comments.split(/\r?\n/);
        
        brokenlines.each {|brokenline|
          
          lines = SVGUtilities::break_text_lines(brokenline, num_chars_per_line);
          lines.each {|line|
            svg, x, y = SVGUtilities::add_text( svg, x, y, font_size*0.75, line, opts, '000000' )
            y = y + (opts['name_line_spacing'])
          }
          
          y = y + (opts['name_line_spacing'])
        }
  
      end
      
    end

    y = y + (opts['name_line_spacing'] * 8)

    return [x,y]
  end

  def svg_width( opts )
    minmaxxy = min_max_rooms
    maxx = minmaxxy[1][0]

    sect_width = (maxx+4) * opts['ww']
    return sect_width
  end
  
  def svg_height( opts )
    minmaxxy = min_max_rooms
    maxy = minmaxxy[1][1]
    
    sect_height = (maxy+2) * opts['hh']
    return sect_height
  end

  def svg_draw(svg, opts, x, y, mapname, section_idx )
    if DEBUG_OUTPUT; puts "svg::FXSection::svg_draw" end

    x, y = svg_draw_section_name( svg, opts, x, y )

    origx = x
    origy = y

    @connections.each { |c|
      a = c.roomA
      b = c.roomB
      next if a.y < 0 and b and b.y < 0
      c.svg_draw( svg, opts, x, y )
    }

    @rooms.each_with_index { |r, idx|
      next if r.y < 0
      r.svg_draw( svg, opts, idx, x, y)
    }
    
    
    # Add the compass displaying code in here so that it 
    # is displayed beneath the interactive display items when
    # they are switched on.
    
    compass_scale_factor = opts['compass_size'];
      
    if(compass_scale_factor > 0)

      compassx = (x + opts['margin'] + (opts['w'] / 2))/compass_scale_factor
      compassy = ((y + svg_height(opts)) - opts['h'])/compass_scale_factor
       
      svg.root.add_element "use", {
      "x"           => compassx,
      "y"           => compassy,
      "xlink:href"  => "#compass",
      "transform"   => "scale(" + compass_scale_factor.to_s() + ")"
      }
      
      y = y + (64 * compass_scale_factor)
      
    end

    #
    # Iterate through the list of rooms a second time to
    # add the interactive elements (list of objects/tasks).
    # We do this as a second pass so that these objects a displayed
    # on top of the basic room objects.
    #

    if opts['draw_interactive'] == true
      if DEBUG_OUTPUT; puts "svg::FXSection::svg_draw::draw_interactive == true" end
      @rooms.each_with_index { |r, idx|
      if (!((opts['draw_connections'] == false) && (r.name =~ /Shortcut to.*/i)))

        r.svg_draw_interactive( svg, opts, idx, origx, origy, section_idx)
      end
    }
    end
    
    y = y + svg_height( opts )
    
    return [x,y]

  end
  
  def svg_draw_separate(opts, svgfile, section_idx, mapname, mapcreator)
    if DEBUG_OUTPUT; puts "svg::FXSection::svg_draw_separate" end
        
    svg = SVGUtilities::new_svg_doc(svg_width(opts), svg_height(opts))
    svg = SVGUtilities::add_compass(svg)
    
    if DEBUG_OUTPUT; printf("svg_draw_separate: section_idx = %s\r\n", section_idx.to_s()) end
    
    if opts['draw_interactive'] == true
      svg = SVGUtilities::svg_add_script(svg, opts)
    end
        
    x = opts['name_x'] + opts['margin']
    y = opts['name_y'] + opts['margin']
    font_size = opts['name_font_size']
    
    svg, x, y = SVGUtilities::add_titles(svg, opts, x, y, font_size, mapname, mapcreator)
    
    x, y = svg_draw(svg, opts, x, y, svgfile, section_idx)
        
    svg.root.attributes["height"] = y
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true

    file = File.open(svgfile, "w")
      file.puts formatter.write(svg, "") 
    file.close

    if DEBUG_OUTPUT; printf("\r\n") end
    
  end
end


class FXMap

  def svg_draw_sections_separate( opts, svgfile )

    @sections.each_with_index { |sect, idx|

      svgfilename = String::new(str=svgfile)

      @section = idx
      create_pathmap
      
      if DEBUG_OUTPUT; printf("svg_draw_sections_separate: filename = %s\r\n", svgfilename.to_s()) end
      
      # Remove .svg from end of filename if it is there.
      if svgfilename =~ /\.svg$/
        svgfilename = svgfilename[0..-5];
      end
      
      # Append the section number.
      svgfilename << "-section" << (idx + 1).to_s()
      
      if DEBUG_OUTPUT; printf("svg_draw_separate: filename = %s\r\n", svgfilename.to_s()) end
      
      # Add .svg back onto the end of the filename.
      svgfilename << ".svg"
          
      if DEBUG_OUTPUT; printf("svg_draw_separate: filename = %s\r\n", svgfilename.to_s()) end

      status "Exporting SVG file '#{svgfilename}'"

      sect.svg_draw_separate( opts, svgfilename, idx, @name, @creator)
    }
    
    status "Exporting SVG Completed"
  end

  def svg_draw_sections( opts, svgfile )
    if DEBUG_OUTPUT; puts "svg::FXMap::svg_draw_sections" end
    if DEBUG_OUTPUT; printf("svg::FXMap::svg_draw_sections:@section=%s\r\n", @section) end
      
    x = opts['name_x'] + opts['margin']
    y = opts['name_y'] + opts['margin']
    font_size = opts['name_font_size']
    
    svg = SVGUtilities::new_svg_doc(max_width(opts), total_height(opts))
    svg = SVGUtilities::add_compass(svg)    
    
    if opts['draw_interactive'] == true
      svg = SVGUtilities::svg_add_script(svg, opts)
    end
    
    svg, x, y = SVGUtilities::add_titles(svg, opts, x, y, font_size, @name, @creator)

    @sections.each_with_index { |sect, idx|

      @section = idx
      # For each page, we need to regenerate the pathmap so that complex
      # paths will come out ok.
      create_pathmap
      # Now, we draw it
      
      x, y = sect.svg_draw(svg, opts, x, y, @name, idx)
    
      y = y + (opts['hh'] * 2)

    }

    create_pathmap
    svg.root.attributes["height"] = y
    
    if svgfile !~ /\.svg$/
      svgfile << ".svg"
    end
    
    status "Exporting SVG file '#{svgfile}'"
    
    formatter = REXML::Formatters::Pretty.new(2)
    formatter.compact = true
    
    file = File.open(svgfile, "w")
      file.puts formatter.write(svg, "") 
    file.close
    
    status "Exporting SVG Completed"

  end

  def max_width(opts)
    max_width=0
    @sections.each_with_index{ |sect, idx|
      maxx = sect.svg_width(opts)
      if(maxx > max_width)
        max_width = maxx
      end
      if DEBUG_OUTPUT; puts("section=" + idx.to_s + ":maxx=" + maxx.to_s) end
    }
    return max_width
  end

  def total_height(opts)
    total_height=0
    @sections.each_with_index{ |sect, idx|
      maxy = sect.svg_height(opts)
      total_height = total_height + maxy
    }
    return total_height
  end

  def num_sections()
    return @sections.length
  end

  def svg_export(svgfile, printer = nil)
    
    if DEBUG_OUTPUT; puts "svg::FXMap::svg_export" end

    map_options = @options.dup

    ww = SVG_ROOM_WIDTH  + SVG_ROOM_WS
    hh = SVG_ROOM_HEIGHT + SVG_ROOM_HS

    svg_options = { 
    'ww'                   => ww,
    'hh'                   => hh,
    'w'                    => SVG_ROOM_WIDTH,
    'h'                    => SVG_ROOM_HEIGHT,
    'ws'                   => SVG_ROOM_WS,
    'hs'                   => SVG_ROOM_HS,
    'ws_2'                 => SVG_ROOM_WS / 2.0,
    'hs_2'                 => SVG_ROOM_HS / 2.0,
    'margin'               => 10,
    'margin_2'             => 5,
#    'width'                => map_width,
#    'height'               => map_height,
    'text_max_chars'       => 20,
    'text_line_spacing'    => 2,
    'text_margin'          => 5,
    'room_line_width'      => 2,
    'room_line_colour'     => "black",
    'room_font_size'       => 8,
    'objects_font_size'    => 6,
    'objects_width'        => 140,
    'room_num_font_size'   => 6,
    'print_room_nums'      => true,
    'num_line_width'       => 1,
    'num_line_colour'      => "black",
    'num_fill_colour'      => "lightgreen",
    'conn_line_width'      => 2,
    'conn_line_colour'     => "black",
    'door_line_width'      => 2,
    'door_line_colour'     => "forestgreen",
    'arrow_line_width'     => 1,
    'arrow_line_colour'    => "black",
    'arrow_fill_colour'    => "black",
    'name_font_size'       => 18,
    'name_x'               => 0,
    'name_y'               => 0,
    'name_line_spacing'    => 4,
    'print_title'          => true,
    'print_creator'        => true,
    'print_date'           => true,
    'creator_prefix'       => "Creator: ",
    'date_prefix'          => "Date: ",
    'draw_interactive'     => true,
    'draw_roomnames'       => true,
    'draw_connections'     => true,
    'corner_size'          => 15,
    'corner_line_colour'   => "black",
    'corner_line_width'    => 1,
    'corner_fill_colour'   => "lightgreen",
    'objs_line_colour'     => "black",
    'objs_line_width'      => 1,
    'objs_fill_colour'     => "lightgreen",
    'print_section_names'  => true,
    'section_name_prefix'  => "Section: ",
    'split_sections'       => false,
    'draw_sectioncomments' => true,
    'compass_size'         => 3
    }

    svg_options.merge!(map_options)

    begin
      
      if svg_options['split_sections'] == false
        svg_draw_sections(svg_options, svgfile)
      else
        svg_draw_sections_separate(svg_options, svgfile)
      end
      
      rescue => e
      p e
      p e.backtrace
      raise e
    end
  end
end
