module Creatures
# A creature is a tree of nodes, each defining an angle from the previous to the next. 
# It also has a center of mass coordinate and an overall angle of rotation. 

# This module defines functions to
# - generate creatures randomly. 
# - transform a creature tree into a set of cartesian coordinates

export generate_random, get_coordinates, to_inertial_frame, update_coordinates!

const o=0.0
const empty = Array(Float64,0,0)

abstract CreatureNode
type Nil <: CreatureNode
end

type Part <: CreatureNode
  left    :: CreatureNode
  right   :: CreatureNode
  θ       :: Float64
end

type NodeState
  r          :: Array{Float64,1}
  d          :: Array{Float64,1}
  θ          :: Float64
end

type CreatureState
  r          :: Array{Float64,2}
  d          :: Array{Float64,2}
  θ          :: Array{Float64,1}
end

type Creature
  root       :: CreatureNode
  r          :: Array{Float64,1}
  θ          :: Float64
  ṙ         :: Array{Float64,1}
  θ̇         :: Float64
  state      :: CreatureState
  old_state  :: CreatureState

  Creature(root) = new(root,[o,o],o,[o,o],o,get_state(root),get_state(root))
end


function generate_random(depth,p_split)
  root = generate_random_node_tree(depth,p_split)
  return Creature(root)
end

function generate_random_node_tree(depth,p_split)
  if depth>1
    if rand()>p_split
      return Part(generate_random_node_tree(depth-1,p_split),Nil(),0.0)
    else
      return Part(generate_random_node_tree(depth-1,p_split),generate_random_node_tree(depth-1,p_split),(0.5-rand())*2*pi)
    end
  end
  return Part(Nil(),Nil(),0.0)
end

function update_state!(creature::Creature)
  creature.old_state = creature.state
  creature.state = get_state(creature.root)
end

function get_state(creature::CreatureNode)
  node_states = get_node_states(creature)
  r = apply(hcat, [ns.r for ns in node_states])
  d = apply(hcat, [ns.d for ns in node_states])
  θ = [ns.θ for ns in node_states]
  to_inertial_frame(CreatureState(r,d,θ))
end

function get_node_states(creature::CreatureNode)
  function up(c,parent_state)
    θ_old = parent_state.θ
    r_old = parent_state.r
    d_old = parent_state.d
    θ = θ_old+c.θ
    r = r_old+[cos(θ),sin(θ)]
    d = r - r_old
    NodeState(r,d,θ)
  end
  function down(c,cur_state,left,right)
    [cur_state,left,right]
  end
  walk(creature,up,down,NodeState([o,o],[o,o],o))
end

noop(args...)=nothing

function walk(creature::CreatureNode, up=noop, down=noop, acc=nothing)
  c = creature
  res_left=[]
  res_right=[]
  if typeof(c.left)==Part
    res_left = walk(c.left,up,down,up(c.left,acc))
  end
  if typeof(c.right)==Part
    res_right = walk(c.right,up,down,up(c.right,acc))
  end
  down(c,acc,res_left,res_right)
end

function to_inertial_frame(state :: CreatureState)
  cm = mean(state.r,2)
  angle = atan2(cm[2],cm[1])
  M = [cos(angle) -sin(angle); sin(angle) cos(angle)]
  r = M*(state.r .- cm)
  d = M*state.d
  θ = state.θ - angle
  return CreatureState(r,d,θ)
end

end