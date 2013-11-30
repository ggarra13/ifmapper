

#
# Class used to do Postscript printing.  This class has only the basic
# functionality needed for doing so and replaces the still somewhat buggy 
# version of Fox's 1.2 FXDCPrint
#
class FXDCPostscript < FXDC
  @@printcmd = 'lpr -P%s -o l -' # -#%d'

  def setContentRange(xmin, ymin, xmax, ymax)
    @pxmin = xmin.to_f
    @pymin = ymin.to_f
    @pxmax = xmax.to_f
    @pymax = ymax.to_f
  end

  # Transform point
  def tfm(xi, yi)
    pxrange = @pxmax - @pxmin
    pyrange = @pymax - @pymin

    if @flags & PRINT_LANDSCAPE != 0
      mxmin = @ymin.to_f
      mxmax = @ymax.to_f
      mymin = @width - @xmax
      mymax = @width - @xmin
      mxrange = mxmax - mxmin
      myrange = mymax - mymin
    else
      mxmin = @xmin
      mxmax = @xmax
      mymin = @ymin
      mymax = @ymax
      mxrange = mxmax-mxmin
      myrange = mymax-mymin
    end

    if pyrange/pxrange <= myrange/mxrange
      # short/wide
      xo = mxmin + ((xi.to_f-@pxmin)/pxrange) * mxrange;
      yo = mymin + 0.5 * (myrange-pyrange * (mxrange/pxrange)) + 
	  (pyrange-yi.to_f) * (mxrange/pxrange)
    else
      # tall/thin
      xo = mxmin + 0.5 * (mxrange-pxrange * (myrange/pyrange)) + 
	xi * (myrange/pyrange)
      yo = mymin + ((pyrange-yi.to_f)/pyrange) * myrange
    end
    return [xo, yo]
  end





  def _header
    @f.puts <<'HEADER'
%%!PS-Adobe-3.0
%%%%Title: Print Job
%%%%Creator: IFMapper
HEADER

  end

  def beginPrint(printer, &block)
    @flags = printer.flags
    if @flags & PRINT_DEST_FILE != 0
      @f = File.open( printer.name, 'w' )
    else
      buffer = @@printcmd % [ printer.name, printer.numcopies ]
      puts buffer
      @f = File.popen( buffer, 'w')
    end


    @width  = printer.mediawidth.to_f
    @height = printer.mediaheight.to_f

    @xmin   = printer.leftmargin.to_f
    @xmax   = @width - printer.rightmargin 

    @ymin   = printer.bottommargin.to_f
    @ymax   = @height - printer.topmargin 


    _header
    if @flags & PRINT_NOBOUNDS != 0
      xmin = 10000000.0
      xmax = -xmin
      ymin = 10000000.0
      ymax = -ymin
      @f.puts "%%%%BoundingBox: (atend)"
    else
      @f.puts "%%%%BoundingBox: %d %d %d %d" %
	[ @xmin, @ymin, @xmax, @ymax ]
    end

    @numpages = 1 + printer.firstpage - printer.lastpage
    if    @flags & PRINT_PAGES_ODD
      @numpages = 1 + (printer.topage - printer.frompage) / 2  
    elsif @flags & PRINT_PAGES_EVEN
      @numpages = 1 + (printer.topage - printer.frompage) / 2  
    elsif @pages & PRINT_PAGES_RANGE
      @numpages = 1 + printer.topage - printer.frompage
    end

    if @numpages == 0
      @f.puts "%%%%Pages: (atend)"
    else
      @f.puts "%%%%Pages: #{@numpages}"
    end

    @f.puts "%%%%DocumentFonts:"
    @f.puts "%%%%EndComments"
    @f.puts "%%%%BeginProlog\n\n"

    # Various definitions
    @f.puts "%% h w x y drawRect\n"
    @f.puts "/drawRect {\n\tnewpath moveto dup 0 rlineto exch dup 0 exch\n\trlineto exch neg 0 rlineto neg 0 exch rlineto\n\tclosepath stroke\n} def\n"
    @f.puts "%% h w x y fillRect\n"
    @f.puts "/fillRect {\n\tnewpath moveto dup 0 rlineto exch dup 0 exch\n\trlineto exch neg 0 rlineto neg 0 exch rlineto\n\tclosepath fill stroke\n} def\n"
    @f.puts "%% x y a b drawLine\n"
    @f.puts "/drawLine {\n\tnewpath moveto lineto stroke\n} def\n"
    @f.puts "%% x y ..... npoints drawLines\n"
    @f.puts "/drawLines {\n\t3 1 roll newpath moveto {lineto} repeat stroke\n} def\n"
    @f.puts "%% x y a b ..... nsegments drawSegmt\n"
    @f.puts "/drawSegmt {\n\tnewpath {\n\t\tmoveto lineto\n\t} repeat stroke\n} def\n"
    @f.puts "%% x y drawPoint\n"
    @f.puts "/drawPoint {\n\ttranslate 1 1 scale 8 8 1 [ 8 0 0 8 0 0 ] {<0000>} image\n} def\n"
    @f.puts "%% centerx centery  startAngle endAngle radiusX radiusY drawArc\n"
    @f.puts "/drawArc {\n\tgsave dup 3 1 roll div dup 1 scale 6 -1 roll\n\texch div 5 1 roll  3 -2 roll arc stroke grestore\n} def\n"
    @f.puts "/fillChord {\n\tgsave dup 3 1 roll div dup 1 scale 6 -1 roll\n\texch div 5 1 roll  3 -2 roll arc fill grestore\n} def\n"
    @f.puts "%% (string) x y height drawText\n"
    @f.puts "/drawText {\n\tgsave findfont exch scalefont setfont moveto\n\tshow grestore\n} def\n"


    @f.puts "%%%%EndProlog"

    @f.puts "%%%%BeginSetup"
    @f.puts "/#copies #{printer.numcopies} def"
    @f.puts "%%%%EndSetup"

    @page = 0

    if block_given?
      yield self
      endPrint()
    end
  end


  def endPrint
    @f.puts "%%%%Trailer\n"

    # We now know the bounding box
    if @flags & PRINT_NOBOUNDS != 0
      if @xmin < @xmax and @ymin < @ymax
	@f.puts "%%%%BoundingBox: %d %d %d %d" %
	  [ @xmin, @ymin, @xmax, @ymax ]
      else
	@f.puts "%%%%BoundingBox: 0 0 100 100"
      end
    end

    # We now know the page count
    if not (@flags & PRINT_PAGES_ODD|PRINT_PAGES_EVEN|PRINT_PAGES_RANGE)
      @f.puts "%%%%Pages: #{page}"
    end

    @f.puts "%%%%EOF"
    @f.close
  end


  def beginPage(num = 1, &block)
    # Output page number
    @f.puts "%%%%Page: #{@page} #{@page}" # Ghostscript requests this, I do not know if it is right

    # Reset page bounding box
    if @flags & PRINT_NOBOUNDS != 0
      @xmin= 1000000;
      @xmax=-1000000;
      @ymin= 1000000;
      @ymax=-1000000;
      @f.puts "%%%%PageBoundingBox: (atend)"
    else
      # Use the doc bounding box
      @f.puts "%%%%PageBoundingBox: %d %d %d %d" % [@xmin, @ymin, @xmax, @ymax]
    end

    # Page setup
    @f.puts "%%%%BeginPageSetup"
    @f.puts "%%%%EndPageSetup"
    @f.puts "gsave"

    # Maybe in landscape?
    if @flags & PRINT_LANDSCAPE != 0
      @f.puts "#{@width} 0.0 translate"
      @f.puts "90 rotate"
    end

    if block_given?
      yield self
      endPage()
    end
  end

  def endPage
    @f.puts "%%%%PageTrailer"

    # We now know the bounding box
    if @flags & PRINT_NOBOUNDS != 0
      if @xmin < @xmax and @ymin < @ymax
	@f.puts "%%%%BoundingBox: %d %d %d %d" [@xmin, @ymin, @xmax, @ymax]
      else
	@f.puts "%%%%BoundingBox: 0 0 100 100" # Gotta come up with something...
      end
    end
    @f.puts "showpage"
    @f.puts "grestore"
    @page += 1
  end

  # Extends bounding box with point x,y
  def bbox(x, y)
    @xmin = x if x < @xmin
    @ymin = y if y < @ymin
    @xmax = x if x > @xmax
    @ymax = y if y > @ymax
  end

  def _rect(x, y, w, h)
      xl, yt = tfm(x, y)
      xr, yb = tfm(x + w - 1, y + h - 1)
      bbox(xl,yt)
      bbox(xr,yb)
      @f.print "newpath %g %g moveto %g %g lineto %g %g lineto %g %g lineto %g %g lineto " % 
	[xl,yt,xr,yt,xr,yb,xl,yb,xl,yt]
  end

  def drawRectangle(x, y, w, h)
    _rect(x, y, w, h)
    @f.puts "stroke"
  end


  def drawLine(x1, y1, x2, y2)
    xx1, yy1 = tfm(x1, y1)
    xx2, yy2 = tfm(x2, y2)
    bbox(xx1,yy1)
    bbox(xx2,yy2)
    @f.puts "newpath %g %g moveto %g %g lineto stroke" % [xx1, yy1, xx2, yy2]
  end

  def drawLines(points)
    return if points.size < 2
    xx, yy = tfm(points[0].x, points[0].y)
    bbox(xx,yy)
    @f.print "newpath %g %g moveto" % [xx, yy]
    1.upto(points.size-1) { |i|
      xx, yy = tfm(points[i].x, points[i].y)
      bbox(xx,yy)
      @f.print " %g %g lineto" % [xx, yy]
    }
    @f.puts " stroke"
  end

  def drawText(x, y, text)
    # Draw string (only foreground bits)
    # Contributed by S. Ancelot <sancelot@online.fr>
    xx, yy = tfm( x, y )

    pxrange = @pxmax - @pxmin
    pyrange = @pymax - @pymin

    if @flags & PRINT_LANDSCAPE != 0
      mxmin = @ymin
      mxmax = @ymax
      mymin = @width - @xmax
      mymax = @width - @xmin
      mxrange = mxmax - mxmin
      myrange = mymax - mymin
    else
      mxmin = @xmin
      mxmax = @xmax
      mymin = @ymin
      mymax = @ymax
      mxrange = mxmax - mxmin
      myrange = mymax - mymin
    end

    fsize = 0.1 * @font.getSize

    # Hack...
    # Account for dpi and scale up or down with graph...
    # Perhaps override screen resolution via registry
    # FXint screenres=getApp()->reg().readUnsignedEntry("SETTINGS","screenres",100);
    # Validate
    screenres = 100
#     if(screenres<50) screenres=50;
#       if(screenres>200) screenres=200;

    if pyrange / pxrange <= myrange / mxrange
      # short/wide
      fsize *= (mxrange/pxrange)*(screenres/72.0)
    else
      # tall/thin
      fsize *= (myrange/pyrange)*(screenres/72.0)
    end

    fname = @font.name
    if fname =~ /times/i
      fname = 'Times-Roman'
    elsif fname =~ /(helvetica|verdana|tahoma|arial)/i
      fname = 'Helvetica'
    else
      fname = 'Courier'
    end

    if @font.getWeight == FXFont::FONTWEIGHT_BOLD
      fname << '-Bold'
      if @font.getSlant == FXFont::FONTSLANT_ITALIC
	fname << 'Italic'
      elsif @font.getSlant == FXFont::FONTSLANT_OBLIQUE
	fname << 'Oblique'
      end
    else
      if @font.getSlant == FXFont::FONTSLANT_ITALIC
	fname << '-Italic'
      elsif @font.getSlant == FXFont::FONTSLANT_OBLIQUE
	fname << '-Oblique'
      end
    end

    @f.puts "(%s) %g %g %d /%s drawText" % [text, xx, yy, fsize, fname]
  end

  def fillRectangle(x, y, w, h)
    _rect(x, y, w, h)
    @f.puts "fill"
  end

  def fillPolygon(points)
    return if points.size < 3
    xx, yy = tfm(points[0].x, points[0].y)
    bbox(xx,yy)
    @f.print "newpath %g %g moveto" % [ xx, yy ]
    1.upto(points.size-1) { |i|
      xx, yy = tfm(points[i].x, points[i].y)
      bbox(xx,yy)
      @f.print " %g %g lineto" % [ xx, yy ]
    }
    @f.puts " fill"
  end

  def lineStyle=(x)
    if x == LINE_SOLID
      @f.puts "[ ] 0 setdash"
    elsif x == LINE_ONOFF_DASH
      @f.puts "[2 2] 0 setdash"
    end
  end

  def foreground=(c)
    if c.kind_of?(String)
      clr = fxcolorfromname(c)
    else
      clr = c
    end
    @f.puts "%g %g %g setrgbcolor" % [FXREDVAL(clr)/255.0,FXGREENVAL(clr)/255.0,FXBLUEVAL(clr)/255.0]
  end

  def lineJoin=(x)
  end

  def lineCap=(x)
    ncap = 0
    ncap = 1 if CAP_ROUND == x
    ncap = 3 if CAP_PROJECTING == x
    @f.puts "#{ncap} setlinecap"
  end

  def lineWidth
    return @lineWidth
  end

  def lineWidth=(x)
    @lineWidth = x
    @f.puts "%f setlinewidth" % [x * 0.5]
  end

  def initialize(app)
    @font = app.getNormalFont()
  end

  def font=(x)
    @font = x
  end

  def font
    return @font
  end
end
