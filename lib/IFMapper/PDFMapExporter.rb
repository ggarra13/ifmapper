
require 'tmpdir'

begin
  require 'pdf/writer'
rescue LoadError => e
  err = "PDF-Writer library not found.  Please install it.\n"
  if $rubygems
    err += "You can usually do so if you do 'gem install pdf-writer'."
  else
    err += "You can download it from www.rubyforge.net."
  end
  raise LoadError, err
end

require 'IFMapper/MapPrinting'

PDF_ZOOM        = 0.5
PDF_ROOM_WIDTH  = W  * PDF_ZOOM 
PDF_ROOM_HEIGHT = H  * PDF_ZOOM 
PDF_ROOM_WS     = WS * PDF_ZOOM
PDF_ROOM_HS     = HS * PDF_ZOOM
PDF_MARGIN      = 20.0

#
# Open all the map class and add all pdf methods there
# Gotta love Ruby's flexibility to just inject in new methods.
#
class FXConnection
  def _cvt_pt(p, opts)
    x = (p[0] - WW / 2.0) / WW.to_f
    y = (p[1] - HH / 2.0) / HH.to_f
    x = x * opts['ww'] + opts['ws_2'] + opts['margin_2'] + opts['w'] / 2.0
    y = (opts['height'] - y) * opts['hh'] + opts['hs_2'] + opts['margin_2'] + opts['hs']
    return [x, y]
  end

  def pdf_draw_arrow(pdf, opts, x1, y1, x2, y2)
    return if @dir == BOTH
    
    pt1, d = _arrow_info( x1, y1, x2, y2, 0.5 )

    p = []
    p << PDF::Writer::PolygonPoint.new( pt1[0], pt1[1] )
    p << PDF::Writer::PolygonPoint.new( pt1[0] + d[0], pt1[1] - d[1] )
    p << PDF::Writer::PolygonPoint.new( pt1[0] + d[1], pt1[1] + d[0] )
    pdf.fill_color    Color::RGB::Black
    pdf.polygon(p).fill
  end

  def pdf_draw_complex_as_bspline( pdf, opts )
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

  # PRE: If it's a loop exit that comes back to the same place, let's move 
  #      it up and right
  def pdf_draw_complex_as_lines( pdf, opts )
    p = []
    maxy = opts['height'] * opts['hh'] + opts['hs_2'] + opts['margin_2'] 
    @pts.each { |pt|
      if loop? == true
        p << [ pt[0] * PDF_ZOOM + 10, maxy - pt[1] * PDF_ZOOM + 48 ]
      else
        p << [ pt[0] * PDF_ZOOM, maxy - pt[1] * PDF_ZOOM ]
      end      
    }
    return p
  end

  def pdf_draw_door( pdf, x1, y1, x2, y2 )
      v = [ (x2-x1), (y2-y1) ]
      t = 10 / Math.sqrt(v[0]*v[0]+v[1]*v[1])
      v = [ v[0]*t, v[1]*t ]
      m = [ (x2+x1)/2, (y2+y1)/2 ]
      x1, y1 = [m[0] + v[1], m[1] - v[0]]
      x2, y2 = [m[0] - v[1], m[1] + v[0]]
    if @type == LOCKED_DOOR
      pdf.move_to(x1, y1)
      pdf.line_to(x2, y2).stroke
    else
      s = PDF::Writer::StrokeStyle.new(1,
				       :cap => :butt, 
				       :join => :miter, 
				       :dash => PDF::Writer::StrokeStyle::SOLID_LINE )
      pdf.stroke_style(s)
      v = [ v[0] / 3, v[1] / 3]
      pdf.move_to(x1 - v[0], y1 - v[1])
      pdf.line_to(x1 + v[0], y1 + v[1])
      pdf.line_to(x2 + v[0], y2 + v[1])
      pdf.line_to(x2 - v[0], y2 - v[1])
      pdf.line_to(x1 - v[0], y1 - v[1])
      pdf.stroke
      s = PDF::Writer::StrokeStyle.new(2,
				       :cap => :butt, 
				       :join => :miter, 
				       :dash => PDF::Writer::StrokeStyle::SOLID_LINE )
      pdf.stroke_style(s)
    end
  end

  def pdf_draw_complex( pdf, opts )
    if opts['Paths as Curves']
      if @room[0] == @room[1]
	dirA, dirB = dirs
	if dirA == dirB
	  p = pdf_draw_complex_as_lines( pdf, opts )
	else
	  p = pdf_draw_complex_as_bspline( pdf, opts )
	end
      else
	p = pdf_draw_complex_as_bspline( pdf, opts )
      end
    else
      p = pdf_draw_complex_as_lines( pdf, opts )
    end
    pdf.move_to( p[0][0], p[0][1] )
    p.each { |pt| pdf.line_to( pt[0], pt[1] ) }
    pdf.stroke

    x1, y1 = [p[0][0], p[0][1]]
    x2, y2 = [p[-1][0], p[-1][1]]
    pdf_draw_arrow(pdf, opts, x1, y1, x2, y2)

    if @type == LOCKED_DOOR or @type == CLOSED_DOOR
      t = p.size / 2
      x1, y1 = [ p[t][0], p[t][1] ]
      x2, y2 = [ p[t-2][0], p[t-2][1] ]
      pdf_draw_door(pdf, x1, y1, x2, y2)
    end
  end

  def pdf_draw_simple(pdf, opts)
    return if not @room[1] # PDF does not print unfinished complex connections

    dir    = @room[0].exits.index(self)
    x1, y1 = @room[0].pdf_corner(opts, self, dir)
    x2, y2 = @room[1].pdf_corner(opts, self)
    pdf.move_to(x1, y1)
    pdf.line_to(x2, y2).stroke
    pdf_draw_arrow(pdf, opts, x1, y1, x2, y2)
    if @type == LOCKED_DOOR or @type == CLOSED_DOOR
      pdf_draw_door(pdf, x1, y1, x2, y2)
    end
  end

  #
  # Draw the connection text next to the arrow ('I', 'O', etc)
  #
  def pdf_draw_text(pdf, x, y, dir, text, arrow)
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
	y += 5
      end
      y += 2.5
    elsif dir == 4 or dir == 5
      y -= 7.5
    end
    
    font_size = 8
    pdf.add_text(x, y, text, font_size)
  end

  def pdf_draw_exit_text(pdf, opts)

    if @exitText[0] != 0
      dir  = @room[0].exits.index(self)
      x, y = @room[0].pdf_corner(opts, self, dir)
      pdf_draw_text( pdf, x, y, dir, 
		   EXIT_TEXT[@exitText[0]], @dir == BtoA)
    end

    if @exitText[1] != 0
      dir  = @room[1].exits.rindex(self)
      x, y = @room[1].pdf_corner(opts, self, dir)
      pdf_draw_text( pdf, x, y, dir, 
		    EXIT_TEXT[@exitText[1]], @dir == AtoB)
    end
  end

  def pdf_draw(pdf, opts)
    pdf_draw_exit_text(pdf, opts)
    if @type == SPECIAL
      s = PDF::Writer::StrokeStyle.new(2, :dash => { 
					 :pattern => [2],
					 :phase => [1]
				       } ) 
    else
      s = PDF::Writer::StrokeStyle.new(2,
				       :cap => :butt, 
				       :join => :miter, 
				       :dash => PDF::Writer::StrokeStyle::SOLID_LINE )
    end
    pdf.stroke_style( s )
    pdf.stroke_color  Color::RGB::Black
    pdf.fill_color    Color::RGB::Black
    if @pts.size > 0
      pdf_draw_complex(pdf, opts)
    else
      pdf_draw_simple(pdf, opts)
    end
  end
end


class FXRoom
  def pdf_corner( opts, c, idx = nil )
    x, y = _corner(c, idx)
    y = -y

    ww = opts['ww']
    hh = opts['hh']
    w = opts['w']
    h = opts['h']

    ry = opts['height'] - @y
    x = @x * ww + opts['ws_2'] + opts['margin_2'] + x * w
    y = ry * hh + opts['hs_2'] + h + opts['margin_2'] + y * h
    return [x, y]
  end


  def pdf_draw_box( pdf, opts, idx, pdflocationnos )
    x = @x * opts['ww'] + opts['ws_2'] + opts['margin_2']
    y = (opts['height'] - @y) * opts['hh'] + opts['hs_2'] + opts['margin_2']

    s = PDF::Writer::StrokeStyle::DEFAULT
    pdf.stroke_style( s )

    if @darkness
      pdf.fill_color( Color::RGB::Gray )
    else
      pdf.fill_color( Color::RGB::White )
    end

    pdf.rectangle(x, y, opts['w'], opts['h']).fill_stroke

    if pdflocationnos == 1
      # PRE: Draw a rectangle for the location number
      pdf.rectangle((x+opts['w']-opts['w']/4), y, opts['w']/4, opts['h']/4).fill_stroke
    
      # PRE: Pad out the number so it is three chars long
      locationno = (idx+1).to_s
      if (idx+1) < 10
        locationno = '  '+locationno
      elsif (idx+1) < 100
        locationno = ' '+locationno
      end

      # PRE: Write the location number
      pdf.fill_color(Color::RGB::Black)
      pdf.add_text((x+((opts['w']/4)*3)+2), y+2, locationno, 8)
    end
    
  end

  def pdf_draw_text( pdf, opts, x, y, text, font_size, pdflocationnos )
    miny  = (opts['height'] - @y) * opts['hh'] + opts['hs_2'] + 
      opts['margin_2']
    while text != ''
      # PRE: Wrap the text to avoid the location number box
      if (y >= miny) and (y <= (miny+font_size)) and (pdflocationnos == 1)
        wrapwidthmodifier = 15
      else
        wrapwidthmodifier = 2
      end
      text = pdf.add_text_wrap(x, y, opts['w'] - wrapwidthmodifier, text, font_size)
      y -= font_size
      break if y <= miny
    end
    return [x, y]
  end

  def pdf_draw_objects(pdf, opts, x, y, pdflocationnos)
    font_size = 6
    objs = @objects.split("\n")
    objs = objs.join(', ')
    return pdf_draw_text( pdf, opts, x, y, objs, font_size, pdflocationnos )
  end

  def pdf_draw_name(pdf, opts, pdflocationnos)
    # We could also use pdf_corner(7) here
    x = @x * opts['ww'] + opts['margin_2'] + opts['ws_2'] + 2
    y = opts['height'] - @y
    font_size = 8
    y = y * opts['hh'] + opts['margin_2'] + opts['hs_2'] + opts['h'] - 
      (font_size + 2)
    pdf.stroke_color(Color::RGB::Black)
    pdf.fill_color(Color::RGB::Black)
    return pdf_draw_text( pdf, opts, x, y, @name, font_size, pdflocationnos )
  end

  # PRE: Send through the index so we can print the location number
  #      along with boolean value indicating whether the user wants them
  def pdf_draw( pdf, opts, idx, pdflocationnos )
    pdf_draw_box( pdf, opts, idx, pdflocationnos )
    x, y = pdf_draw_name( pdf, opts, pdflocationnos )
    pdf_draw_objects(pdf, opts, x, y, pdflocationnos)
  end
end



class FXSection

  def pdf_draw_grid(pdf, opts, w, h )
    (0...w).each { |xx|
      (0...h).each { |yy|
	x = xx * opts['ww'] + opts['ws_2'] + opts['margin_2']
	y = yy * opts['hh'] + opts['hs_2'] + opts['margin_2']
	pdf.rectangle(x, y, opts['w'], opts['h']).stroke
      }
    }
  end


  def pdf_draw_section_name( pdf, opts, px, py )
    return if not @name or @name == ''
    xymin, xymax = min_max_rooms
    text = @name
    text += " (#{px}, #{py})" if px > 0 or py > 0
    y = (opts['height']) * opts['hh'] + 16
    w = xymax[0]
    w = opts['width'] if w > opts['width']
    x = (w + 2) * opts['ww'] / 2 - text.size / 2 * 16
    x = 0 if x < 0
    pdf.add_text( x, y, text, 16 )
  end


  def pdf_draw(pdf, opts, mapname, pdflocationnos )


    w, h = rooms_width_height
    x, y = [0, 0]

    loop do

      if rotate
	pdf.rotate_axis(90.0)
	pdf.translate_axis( 0, -pdf.page_height )
      end

      # Move section to its position in page
      tx1, ty1 = [@xoff * opts['ww'], @yoff * -opts['hh']]
      pdf.translate_axis( tx1, ty1 )

      # Use times-roman as font
      pdf.select_font 'Times-Roman'
      pdf.stroke_color(Color::RGB::Black)
      pdf.fill_color(Color::RGB::Black)

      pdf_draw_section_name( pdf, opts, x, y )

      xymin,  = min_max_rooms

      # Move rooms, so that we don't print empty areas
      tx2 = -(xymin[0]) * opts['ww'] - x * opts['ww']
      ty2 =  (xymin[1]) * opts['hh'] - 60 + (y - (y > 0? 1 : 0)) * opts['hh']
      pdf.translate_axis( tx2, ty2 )
      
      
      # For testing purposes only, draw grid of boxes
      # pdf_draw_grid( pdf, opts, w, h )
      @connections.each { |c| 
	a = c.roomA
	b = c.roomB
	next if a.y < y and b and b.y < y
	c.pdf_draw( pdf, opts )
      }
      @rooms.each_with_index { |r, idx| 
	next if r.y < y
	r.pdf_draw( pdf, opts, idx, pdflocationnos)
      }
      
      # Reset axis
      pdf.translate_axis(-tx2, -ty2)
      pdf.translate_axis(-tx1, -ty1)
      
      xi = opts['width']
      yi = opts['height']
      if rotate
	xi = (pdf.page_height / opts['ww']).to_i - 1
	yi = (pdf.page_width  / opts['hh']).to_i - 1
      end

      x += xi
      if x >= w
	x = 0
	y += yi
	break if y >= h
      end

      if rotate
	pdf.rotate_axis(-90.0)
	pdf.translate_axis( 0, pdf.page_height )
      end

      # We could not fit all rooms in page.  Start new page
      pdf.start_new_page
    end
  end
end


class FXMap

  attr_accessor :pdfpapersize
  # boolean value indicating whether the user wants to see location nos
  attr_accessor :pdflocationnos
  
  def pdf_draw_mapname( pdf, opts )
    return if not @name or @name == ''
    pdf.text( @name,
	     :font_size => 24,
	     :justification => :center
	     )
  end

  def pdf_draw_sections( pdf, opts )
    old_section = @section
    page        = -1
    @sections.each_with_index { |sect, idx|
      if page != sect.page
	page = sect.page
	pdf.start_new_page if page > 1
	pdf_draw_mapname( pdf, opts )
      end
      @section = idx
      # For each page, we need to regenerate the pathmap so that complex
      # paths will come out ok.
      create_pathmap
      # Now, we draw it
      sect.pdf_draw(pdf, opts, @name, pdflocationnos)
    }

    # Restore original viewing page
    @section = old_section
    create_pathmap
  end


  def pdf_export(pdffile = Dir::tmpdir + "/ifmap.pdf", printer = nil)
    
    # PRE: Let's set the PDF paper size to user's choice
    paper = BOX_PDF_PAGE_SIZE_TEXT[pdfpapersize]
    if printer
      case printer.mediasize
      when FXPrinter::MEDIA_LETTER
	paper = 'LETTER'
      when FXPrinter::MEDIA_LEGAL
	paper = 'LEGAL'
      when FXPrinter::MEDIA_A4
	paper = 'A4'
      when FXPrinter::MEDIA_ENVELOPE
	paper = 'ENVELOPE'
      when FXPrinter::MEDIA_CUSTOM
	raise "Sorry, custom paper not supported"
      end
    end

    # Open a new PDF writer with paper selected
    # PRE: Let's also set the paper orientation based on user selection
    pdf = PDF::Writer.new :paper => paper

    pdf.margins_pt 0

    pdf_options = @options.dup

    ww = PDF_ROOM_WIDTH  + PDF_ROOM_WS
    hh = PDF_ROOM_HEIGHT + PDF_ROOM_HS

    pdf_options.merge!( 
		       { 
			 'ww'       => ww,
			 'hh'       => hh,
			 'w'        => PDF_ROOM_WIDTH,
			 'h'        => PDF_ROOM_HEIGHT,
			 'ws'       => PDF_ROOM_WS,
			 'hs'       => PDF_ROOM_HS,
			 'ws_2'     => PDF_ROOM_WS / 2.0,
			 'hs_2'     => PDF_ROOM_HS / 2.0,
			 'margin'   => PDF_MARGIN,
			 'margin_2' => PDF_MARGIN / 2.0,
			 'width'    => (pdf.page_width / ww).to_i  - 1,
			 'height'   => (pdf.page_height / hh).to_i - 1,
		       }
		       )


    begin
      # See if it is possible to pack several map sections (sections) into
      # a single print page.
      num = pack_sections( pdf_options['width'] + 2, 
                           pdf_options['height'] + 2 )
      pdf_draw_sections(pdf, pdf_options)
      if pdffile !~ /\.pdf$/
	pdffile << ".pdf"
      end
      status "Exporting PDF file '#{pdffile}'"
      pdf.save_as(pdffile)
    rescue => e
      p e
      p e.backtrace
      raise e
    end
  end
end
