## Introduction
This lab will be in 2 phases :

- The implementation of a `PixelSolver` component which is able to calculate the mandelbrot value of a given XY coordinate
- The implementation of the same functionality but by a multicore manner by using the precedent phase implementation and some arbitration.
- The implementation of an alternative `PixelSolver` which do the calculation by an pipelined and hyper-threaded way.

This lab will introduce :
- Fixed point usage (SFix/UFix)
- Some additional hand-shake arbitration pattern
- The parameterization by using an configuration class
- Pipelining

## Mandelbrot fractal
Mandelbrot pictures are generated by the following way :

- For each pixel of the screen there is an coordinate in the mandelbrot space
- A mandelbrot function will return the number of iteration used to "resolve" each coordinate
- This number of iteration is translated into a color for each pixel of the screen

The mandelbrot function in scala could be the following :

```scala
val maxIterations = 255
def mandelbrot(x0 : Double,y0 : Double) : Int = {
  var x = 0.0
  var y = 0.0
  var iteration = 0

  while (x*x + y*y < 4 && iteration < maxIterations) {
    val xNext = x*x - y*y + x0
    val yNext = 2*x*y + y0
    x = xNext
    y = yNext
    iteration = iteration + 1
  }
  return iteration
}
```

So, The first phase of this lab will be to implement this function in hardware by using SpinalHDL.

You can find more information on the [wikipedia](https://en.wikipedia.org/wiki/Mandelbrot_set)

## Part 1 : PixelSolver

The component will receive one stream of pixel tasks (which contain the XY coordinates in the mandelbrot space) and will produce one stream of pixel results (which contain the number of iteration done for the corresponding task)

Following constructions parameters are given to the PixelSolver :

| Name | Type | Description |
| ------- | ---- |  --- | 
| fixAmplitude | Int | 2^fixAmplitude represent the fixed point maximal value |
| fixResolution | Int | 2^fixResolution represent the fixed point resolution |
| iterationLimit | Int | Maximal number of iteration allowed per XY coordinates |

Let's specify the IO of our component :

| IO Name | Direction | Type | Description |
| ------- | ---- |  --- | --- |
| cmd | slave | Stream(PixelTask)  | Provide XY coordinates to process |
| rsp | master | Stream(PixelResult)  | Return iteration count needed for the corresponding cmd transaction |

Let's specify the PixelTask bundle :

| Element Name | Type | Description |
| ------- | ---- |  --- |
| x | SFix | Coordinate in the mandelbrot space |
| y | SFix | Coordinate in the mandelbrot space |


Let's specify the PixelResult bundle :

| Element Name | Type | Description |
| ------- | ---- |  --- |
| iteration | UInt | Number of iteration required to solve the mandelbrot coordinates |

There is the reference picture that you should get when you run the test :

![](assets/ref.png)

Important : The PixelSolver implementation should not be complicated. It can fit in 40 lines. Also, do not take time to implement things by an pipelined way for the moment, it will come with the part 3.


## Part 2 : PixelSolverMultiCore
The interface of the PixelSolverMultiCore is exactly the same than the PixelSolver. There is just an additional construction parameter named `coreCount` which specify how many PixelSolver you want to instantiate in parallel.

To run input tasks in parallel, there is a very simple strategy :
- Take input tasks and dispatch them on PixelSolvers in the same order that they come. First task go to PixelSolver 0, second task go to PixelSolver 1 and so on.
- Arbitrate the outputs of all PixelSolver by the same way. First take the PixelSolver 0 output, then take the PixelSolver 1 output and so on.

There is a PixelSolverMultiCore diagram :

![](assets/PixelSolverMultiCore.svg)

So, you will have to implement the Dispatcher and the Arbiter and then the PixelSolverMultiCore in order to get maximum performance ;).

## Part 3 (optional) : Pipelining and hyper-threading
With the part 1 implementation, we have one real world issue, it's the fact that the design will not be able to run with a high clock frequency because of the long combinatorial path of multiplications and additions.

To solve this issue we can pipeline operations over multiple cycle. For example, two cycle for multiplications, one cycle for addition.

But, if we apply the pipelining concept to our design, another issue come,
it's the fact that the throughput of our design will be divided by the number of cycle required to do each iteration (A little bit like very old fashion micro processor).
 To solve that, we have to introduce the fact that each stage of our pipeline at a given time, should be abble to work on a given "thread",
  a little bit like Intel hyper-threading.

There is one implementation proposal :<br>
![](assets/PipelinedAndHyperThreaded.svg)

So, new tasks are inserted by the inserter in the loop. Tasks in the loop will go through the MUL and ADD stages and then the router will route task which are done to the `rsp` port, else tasks will be looped again. Also, each tasks should be tagged with an order ID to allow the router to route them in the right order on `rsp`.

The inserter should always give the priority to tasks already in the loop.

Then the loop could be a Stream one, or a Flow one. My proposal is to implement the loop as a fully Flow one, and then, if a task which is done arrive on the router, but the `rsp` is not ready to take it, the task is looped again (but without states changes).

Note : You can find a implementation template [there](assets/PixelSolver.basePipelinedHyperthread)