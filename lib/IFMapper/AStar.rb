


#
# A class used for path finding.
# This is largely based on C++ code by Justin Heyes-Jones, albeit simplified
#
class AStar

  attr :start, :goal
  attr_reader :state
  attr        :successors
  attr_writer :open_list
  attr_writer :closed_list

  SEARCH_STATE_NOT_INITIALIZED = 0
  SEARCH_STATE_SEARCHING = 1
  SEARCH_STATE_SUCCEEDED = 2
  SEARCH_STATE_FAILED    = 3

  def open_list
    puts "Open List:"
    @open_list.each { |n|
      p n
    }
    puts "Closed List # of nodes: #{@open_list.size}"
  end

  def closed_list
    puts "Closed List:"
    @closed_list.each { |n|
      p n
    }
    puts "Closed List # of nodes: #{@closed_list.size}"
  end


  class Node
    attr_accessor :parent, :child
    attr_accessor :h, :g, :f
    
    attr_reader :info

    def <=>(b)
      return -1 if @f > b.f
      return  0 if @f == b.f
      return  1
    end

    def inspect
      "AStarNode: #{@f} = #{@g} + #{@h} #{@info.inspect}"
    end

    def initialize( info = nil )
      @h = @g = @f = 0.0
      @info = info
    end
  end

  # sets start and end goals and initializes A* search
  def goals( start, goal )
    @start = Node.new( start )
    @start.g    = 0.0
    @start.h    = start.distance_estimate( goal )
    @start.f    = @start.h

    @open_list  = []
    @open_list.push( @start )
    @closed_list = []

    @goal  = Node.new( goal )
    
    @state = SEARCH_STATE_SEARCHING
  end

  # Advances one search step
  def search_step
    if @open_list.empty?
      @state = SEARCH_STATE_FAILED
      return @state
    end

    # Pop the best node (the one with the lowest f)
    n = @open_list.pop

    # Check for the goal.  Once we pop that, we are done
    if n.info.is_goal?( @goal.info )
      # The user is going to use the Goal Node he passed in 
      # so copy the parent pointer of n 
      @goal.parent = n.parent
      # Special case is that the goal was passed in as the start state
      # so handle that here
      if n != @start
	child  = @goal
	parent = @goal.parent

	while child != @start
	  parent.child = child
	  child = parent
	  parent = parent.parent
	end
      end
      @state = SEARCH_STATE_SUCCEEDED
      return @state
    else
      # Not goal, get successors
      n.info.successors( self, n.parent )
      @successors.each do |s|
	newg = n.g + n.info.cost( s.info )

	# Now, we need to find out if this node is on the open or close lists
	# If it is, but the node that is already on them is better (lower g)
	# then we can forget about this successor
	open = @open_list.find { |e| e.info.is_same?( s.info ) }
	# State in open list is cheaper than this successor
	next if open and open.g <= newg

	closed = @closed_list.find { |e| e.info.is_same?( s.info ) }
	# We found a cheaper state in closed list
	next if closed and closed.g <= newg
	
	# This node is the best node so far so let's keep it and set up
	# its A* specific data
	s.parent = n
	s.g = newg
	s.h = s.info.distance_estimate( @goal.info )
	s.f = s.g + s.h

	# Remove succesor from closed list if it was on it
	@closed_list.delete(closed) if closed
	# Change succesor from open list if it was on it
	if open
	  open.parent = s.parent
	  open.g = s.g
	  open.h = s.h
	  open.f = s.f
	else
	  @open_list.push(s)
	end
      end
      # Make sure open list stays sorted based on f
      @open_list.sort!

      @closed_list.push(n)
      @successors.clear
    end
    return @state
  end

  def add_successor( info )
    @successors << Node.new(info)
  end

  # return solution as an path (ie. an array of [x,y] coordinates)
  def path
    p = []
    curr = @start
    while curr
      p << [curr.info.x, curr.info.y]
      curr = curr.child
    end
    return p
  end

  def initialize
    @state = SEARCH_STATE_NOT_INITIALIZED
    @successors = []
  end
end


#
# Simple class used as an adapter for our FXMap<->AStar
#
class MapNode
  attr_reader :x, :y
  @@pmap = nil

  def self.map(pmap)
    @@pmap = pmap
  end

  def initialize(x, y)
    @x = x
    @y = y
  end

  def is_same?(node)
    return true  if node and @x == node.x and @y == node.y
    return false
  end

  def is_goal?( goal )
    return true  if @x == goal.x and @y == goal.y
    return false
  end

  def distance_estimate( goal )
    dx = @x - goal.x
    dy = @y - goal.y
    return dx*dx + dy*dy
  end

  MAX_SCALE = 9

  def get_map(x, y)
    if x < 0 or y < 0 or x >= @@pmap.size or y >= @@pmap[0].size
      return MAX_SCALE
    else
      t = @@pmap.at(x).at(y)
      return MAX_SCALE   if t.kind_of?(Room)
      return MAX_SCALE-1 if t.kind_of?(Connection)
      return 1
    end
  end

  def successors( astar, parent = nil )
    info = nil
    info = parent.info if parent
    Room::DIR_TO_VECTOR.each_value { |x, y|
      new_node = MapNode.new(@x + x, @y + y)
      if get_map( new_node.x, new_node.y ) < MAX_SCALE and 
	  not new_node.is_same?(info)
	astar.add_successor(new_node)
      end
    }
  end

  def inspect
    "pos: #{@x}, #{@y}"
  end

  def to_s
    inspect
  end

  def cost( successor )
    g  = get_map(@x,@y)

    dx = (@x - successor.x).abs
    dy = (@y - successor.y).abs
    if dx + dy == 1
       g += 10  # straight move
     else
       g += 14  # diagonal move
    end
    return g
  end

end
