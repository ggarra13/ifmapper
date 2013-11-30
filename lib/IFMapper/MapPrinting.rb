
# Common printing add-ons
class FXSection
  attr_accessor :xoff, :yoff, :page, :pxlen, :pylen, :rotate
end

class Page
  attr_accessor :xlen, :ylen, :sections, :rotate
  def initialize(xlen = 0, ylen = 0)
    @xlen     = xlen
    @ylen     = ylen
    @rotate   = false
    @sections = []
  end
end

class Map  
  #
  # This code section is largely a copy of similar code used in
  # IFM's C code.
  # It tries to pack multiple map sections into a single page.
  #
  def pack_sections(xmax, ymax)
    spacing = 0.0

    # initialize -- one section per page
    pages = []
    @sections.each { |sect|
      xlen, ylen = sect.rooms_width_height
      sect.xoff = 0.0
      sect.yoff = 0.0

      page = Page.new(xlen+2, ylen+2)
      pages.push page
      page.sections << sect
    }

    ratio   = xmax.to_f / ymax

    packed  = 1
    while packed > 0
      newpages = []
      pos = packed = 0
      while pos < pages.size
	p1 = pages[pos]
	x1 = p1.xlen
	y1 = p1.ylen

	# Check if it's better off rotated
	p1.rotate = ((x1 < y1 and xmax > ymax) or
		     (x1 > y1 and xmax < ymax))

	# Check if this is the last page
	if pos + 1 == pages.size
	  newpages.push p1
	  break
	end
	
	# Get following page
	p2 = pages[pos+1]
	x2 = p2.xlen
	y2 = p2.ylen
	
	# Try combining pages in X direction
	xc1 = x1 + x2 + spacing
	yc1 = [y1, y2].max
	v1  = (xc1 <= xmax and yc1 <= ymax)
	r1  = xc1.to_f / yc1
	
	# Try combining pages in Y direction
	xc2 = [x1, x2].max
	yc2 = y1 + y2 + spacing
	v2  = (xc2 <= xmax and yc2 <= ymax)
	r2  = xc2.to_f / yc2

	# See which is best
	if v1 and v2
	  if (ratio - r1).abs < (ratio - r2).abs
	    v2 = false
	  else
	    v1 = false
	  end
	end
	
	# Just copy page if nothing can be done
	if not v1 and not v2
	  newpages.push(p1)
	  pos += 1
	  next
	end
	
	# Create merged page
	page = Page.new
	xo1 = yo1 = xo2 = yo2 = 0
	
	if v1
	  page.xlen = xc1
	  page.ylen = yc1
	  xo2 = x1 + spacing
	  
	  if y1 < y2
	    yo1 = (yc1 - y1) / 2
	  else
	    yo2 = (yc1 - y2) / 2
	  end
	end
	
	if v2
	  page.xlen = xc2
	  page.ylen = yc2
	  yo1 = y2 + spacing
	  
	  if x1 < x2
	    xo1 = (xc2 - x1) / 2
	  else
	    xo2 = (xc2 - x2) / 2
	  end
	end
	
	# Copy sections to new page, updating offsets
	opsects = p1.sections
	opsects.each { |sect|
	  page.sections.push sect
	  sect.xoff += xo1
	  sect.yoff += yo1
	}
	
	opsects = p2.sections
	opsects.each { |sect|
	  page.sections.push sect
	  sect.xoff += xo2
	  sect.yoff += yo2
	}
	
	# Add merged page to list and go to next page pair
	newpages.push page
	pos += 2
	packed += 1
      end
      pages = newpages
    end

    # Give each section its page info and clean up
    num = 0
    pages.each { |page|
      psects = page.sections
      xlen  = page.xlen
      ylen  = page.ylen
      rflag = page.rotate

      num += 1
      psects.each { |sect|
	sect.page   = num
	sect.pxlen  = xlen
	sect.pylen  = ylen
	sect.rotate = rflag
      }
    }
    return num
  end
end

