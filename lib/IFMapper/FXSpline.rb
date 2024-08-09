

#
# Class used to evaluate a bspline.
#
class FXSpline
  OS = 1.0 / 6.0
  FS = 4.0 / 6.0
  def self.bspline_solve( r, p, num )
    ax = -OS  * p[0][0] + 0.5 *   p[1][0] - 0.5 * p[2][0] + OS * p[3][0]
    bx =  0.5 * p[0][0] -         p[1][0] + 0.5 * p[2][0]
    cx = -0.5 * p[0][0]                   + 0.5 * p[2][0]
    dx =  OS  * p[0][0] + FS * p[1][0]    + OS  * p[2][0]

    ay = -OS  * p[0][1] + 0.5 *   p[1][1] - 0.5 * p[2][1] + OS * p[3][1]
    by =  0.5 * p[0][1] -         p[1][1] + 0.5 * p[2][1]
    cy = -0.5 * p[0][1]                   + 0.5 * p[2][1]
    dy =  OS  * p[0][1] + FS * p[1][1] + OS * p[2][1]

    t    = 0.0
    tinc = 1.0 / num
    0.upto(num) {
      x = t * (t * (t * ax + bx) + cx) + dx
      y = t * (t * (t * ay + by) + cy) + dy
      r << [ x, y ]
      t += tinc
    }
  end

  def self.bspline(p)
    pts = []
    0.upto(p.size-4) { |x|
      x2 = p[x+2][0] - p[x+1][0]
      x2 = x2 * x2
      y2 = p[x+2][1] - p[x+1][1]
      y2 = y2 * y2
      num = Math.sqrt( x2 + y2 ).to_i / 16
      bspline_solve(pts, p[x..x+3], num)
    }
    return pts
  end
end

# Draw a bspline curve of any number of segments
def drawBSpline(dc, p)
  tmp = FXSpline::bspline(p)
  pts = tmp.collect { |x| FXPoint.new( x[0].to_i, x[1].to_i) }
  dc.drawLines(pts)
  return pts
end
