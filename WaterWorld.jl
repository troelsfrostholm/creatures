module WaterWorld
# This module implements a water world for a creature
#
# The world contains a creature embedded in some kind of water
# that it can swim in. 
# As the creature moves, a drag force acts from the water on it's
# parts. 
#
# The module consists of the following:
# - A function that calculates the total force and torque on a creature, 
#   given its previous and current coordinates
# - A function that updates the creatures position, velocity, angle and
#   angular velocity given the force
# - A function that performs one physics step (dt)
# - A rendering loop that performs a physics step followed by a rendering
#   loop
# - And a creture!

import Creatures: generate_random, get_coordinates, to_inertial_frame, update_coordinates!
import AnimatedScatter: play

export run, step

function forces(creature, Δcoords, Δt)
  v = Δcoords/Δt .+ creature.ṙ
  σ=1.0
  v_lim=1.
  abs_v = sqrt(sum(v.^2,1))
  square_if = (v_lim .> abs_v)
  return -abs((int(square_if).*v.+int(!square_if)).*v.*σ).*sign(v)
end

function update!(creature, F_tot, Δt)
  creature.ṙ+=F_tot*Δt
  creature.r += creature.ṙ*Δt
end

function step(creature, Δt)
    Δcoords = creature.coords - creature.old_coords
    F = forces(creature, Δcoords, Δt)
    # τ = torques(c, new_coords, F)
    update!(creature, sum(F), Δt)
end

function run(depth,p_split)
  c = generate_random(depth,p_split)
  function coord_generator(x)
    θ=0.05sin(x*0.1)
    update_coordinates!(c,θ)
    WaterWorld.step(c,0.001)
    return (c.old_coords .+ c.r)'
  end
  plot_range=40
  p = plot_range
  play(coord_generator,p,-p,p,-p,1000)
end

function reload()
  Base.reload("Creatures")
  Base.reload("AnimatedScatter")
end

end