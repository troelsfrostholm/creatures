module AnimatedScatter
import PyCall
PyCall.@pyimport matplotlib.pyplot as plt
PyCall.@pyimport matplotlib.animation as animation

export play

x = [0.0 for i in [1:100]]
y = [0.0 for i in [1:100]]

function update(num, s, data_gen)
  data = data_gen(num)
  s[:set_offsets](data)
  (s,)
end

function random_generator(num)
  global x,y
  shift!(x)
  push!(x,rand())
  shift!(y)
  push!(y,rand())
  [x y]
end

function play(data_generator, xlow=0.0,xhigh=1.0,ylow=0.0,yhigh=1.0, iterations=100)
  data_gen = data_generator

  fig1 = plt.figure()
  initial_data = data_gen(0)
  s = plt.scatter(initial_data[:,1], initial_data[:,2])
  plt.xlim(xlow,xhigh)
  plt.ylim(ylow,yhigh)
  scat_ani = animation.FuncAnimation(fig1, update, iterations, fargs=(s,data_gen), interval=25, blit=false)

  plt.show()
end
end