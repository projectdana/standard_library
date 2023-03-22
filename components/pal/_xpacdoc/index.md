## Perception, Assembly, and Learning (PAL)

PAL is a fully autonomous meta-system: one program that controls the assembly of another program. You can read more about the technical design of PAL in one of the research papers on the system. Here we focus on how to use PAL and how to write programs that are controlled by it.

PAL (Perception, Assembly and Learning) is designed to discover all possible ways in which a system can be assembled (finding all component variants that implement every interface that is used). PAL then enables that system to be easily re-assembled into any of its available configurations while it is running, and to deliver perception data from the components of that system. A learning algorithm uses this information to explore different configurations and to understand how each such configuration behaves or performs across different contexts.

## Running a program with PAL

PAL can run any normal Dana program. To do this, instead of using the command `dana myprogram.o`, you simply use the command:

    dana pal.rest myprogram.o

This starts the assembly and perception parts of PAL, discovers all possible ways in which the given program can be assembled, and assembles that program in the first one of those options. In addition to this, a RESTful web services API is started. A control system (for example a learning algorithm) can then connect to this API to issue commands to the assembly and perception modules.

We do not currently provide any learning algorithms for PAL as part of Dana's standard library. Instead we provide a simple example controller which cycles through every possible configuration of the system being constructed by PAL. This simple controller can be used as a base to write your own learning algorithms (or of course you can alternatively write your own learning algorithms in a different programming language and interact via the RESTful API).

To run the simple example controller, use the command:

    dana pal.control.cycle

This will begin cycling through all possible assemblies.

You can also issue commands to the RESTful web services API from a web browser.

## Writing a program to be controlled by PAL

PAL can run any Dana program; but to be really useful, that program needs to provide behavioural variation and perception data to PAL.

Behavioural variation is offered by implementing multiple different components that provide the same interface. Imagine you have an interface type data.Clustering, so that your component providing this interface is in a folder called "data". You can then decide on a different way to implement the data.Clustering interface which performs the same basic task but does so in a different way. Save this component in the "data" folder too, but with a different name to the default component providing this interface.

When PAL is discovering the components that can form the system, it will automatically locate all components that provide each given interface, and will determine all of the possible ways that the system can be composed by mixing all of the available components together in different ways.

Once you have behavioural variation, perception data is used to help understand which mixtures of components (i.e., which behaviours) work best under (potentially) different conditions. Perception data is provided very simply using the built-in pal.Perception interface.

A component wishing to provide perception data declares itself to require this interface and uses it to report metrics or events, for example:

```
    component provides MyInterface requires pal.Perception perception {
        void MyInterface:function()
            {
            //... do something interesting
            perception.addMetric("speed", functionExecutionTime, false)
            }
        }
```

Metrics are typically used to describe how a component is performing (such as its average response time, or perhaps the user's satisfaction level). Events are used to describe some factor of how the world in which the component is operating "looks" (such as the request types that it is seeing).

And that's all! Assuming that the components used to build your system are all compliant with runtime adaptation (for example with appropriate transfer state where necessary), this is all you need.

A learning algorithm will experiment with the various possible ways of composing a piece of software (using available behavioural variants) and will observe how they make the system feel as it is subjected to different operating environment conditions.
