# Dana Compute Package

The Dana Compute package allows you to interact with compute devices on your system.

There are three main levels of abstraction in this package to interact with compute devices. Depending on your intended application one may be better than the others.

# Apps Interfaces

The first of these is the easiest way to interact with external compute devices on your system. These are a set of apps whose functions are commonly associated with using hardware acceleration to process large datasets. For example the RNG app can be used to generate large amounts of pseudo-random numbers in parallel, and the LinearOperations app implements tasks such as matrix multiplication on an external compute device to leverage high levels of parallelisation.

Accessing these apps interfaces is done in the usual Dana way of requiring them in any component you're building and calling their functions:

```
component provides App requires compute.apps.LinearOperations {

	int App:main(AppParam params[])
    	{
    	LinearOperations linear = new LinearOperations()
   			  dec matrixOne[][] = new dec[500][500]
   			  dec matrixTwo[][] = new dec[500][500]

   			  // populate the matrices

   			  dec matrixThree[][] = linear.matrixMultiply(matrixOne, matrixTwo)

   			  return 0
    	}
	}
```

# LogicalCompute Interface

The second of the abstraction levels is the LogicalCompute (link to interface page) interface. This is an easy way to get up and running transferring data and executing instructions on an external compute device. It gives the user a space to declare, read and write variables along with loading programs that operate on the variables that have been declared. Users of this interface need not be concerned with exactly which external devices are being used, and if more than one is being used the user of the LogicalCompute won't need to decide which physical device to write data to or execute programs on.

The utility functions discussed above typically use this interface to implement their behavior. The general workflow is as follows:

1. Declare a set of variable
2. Write some data to the variables
3. Load a program
4. Run the program on a set of the declared variables
5. Reading the result of the executed program
6. Cleaning up the variables


```
component provides dataprocessing.Normalisation requires gpu.LogicalCompute, data.DecUtil du {
	LogicalCompute myDev

	Normalisation:Normalisation() {
    	myDev = new LogicalCompute()
   	 /// Loading the program
    	myDev.loadProgram("./resources-ext/opencl_kernels/dataprocessing/floatDiv.cl", "floatDiv")
	}

	dec[][] Normalisation:matrixDivision(dec matrix[][], dec divider) {
   	 /// Declaring the variables needed
    	myDev.createDecMatrix("mat", matrix.arrayLength, matrix[0].arrayLength)
    	myDev.createDecMatrix("out", matrix.arrayLength, matrix[0].arrayLength)
    	myDev.createDecArray("divider", 1)

   	 ///Writing data to variables that need it
    	myDev.writeDecArray("divider", new dec[](divider))
   			  myDev.writeDecMatrix("mat", matrix)

   	 ///Collecting together the variables as parameters
    	String params[] = new String[](new String("divider"), new String("mat"), new String("out"))
   	 ///Running the Program
    	myDev.runProgram("floatDiv", params)

   	 ///Reading the result
    	dec m[][] = myDev.readDecMatrix("out")

   	 ///Cleaning up
    	myDev.destroyMemoryArea("mat")
    	myDev.destroyMemoryArea("out")
    	myDev.destroyMemoryArea("divider")

    	return m
	}
}
```

## Parameter and Name parity
When constructing the parameter array, the parameters need to be in the same order they appear in the loaded program, therefore it's expected that users at this level wrote or are familiar with the programs being loaded. The parameters can be named differently in Dana than in the external program code, however the name of the program in Dana <b> must match exactly </b> the name of the entry point function of the external device program. The program that was loaded in the above example can be seen below:

```
__constant sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_NONE | CLK_FILTER_NEAREST;

__kernel void floatDiv(__global float* divider, read_only image2d_t matrix, write_only image2d_t matrix_write) {
	int gidx = get_global_id(0);
	int gidy = get_global_id(1);

	float4 fromDevice = read_imagef(matrix, sampler, (int2)(gidx, gidy));
	float ourNumber = fromDevice[0];
	float divided = ourNumber / divider[0];

	write_imagef(matrix_write, (int2)(gidx, gidy), (float4)(divided, 0 ,0 ,0));
}
```

# Compute Interfaces
Lastly is the set of interfaces that make up the Compute component. At this level, the user can select precisely which physical devices they want to use. Cluster them together in a ComputeArray, decide which programs are built for which devices etc. Getting this setup requires a few steps which will typically follow this pattern:

1. Get external compute devices available to the system
```
***HardwareInfo Interface Required
//Query the system for all available compute devices by name
HardwareInfo info = new HardwareInfo()
String devices[] = info.getDevices()
```

2. Choose the devices you want to pool together, one or more
```
String devicesToUse = new String[](devices[x].string, devices[y].string)
```

3. Bind these devices together in a ComputeArray
```
***ComputeArray Interface Required
ComputeArray deviceBinder = new ComputeArray(devicesToUse)
```

4. At this point, Compute objects can be instantiated which the user can actually use for computation <br> Any Compute instance that is created using an identical ComputeArray and device name will refer to the exact same binding in the underlying native library.
```
***Compute Interface Required
Compute liveDevice = new Compute(devicesToUse[x], deviceBinder)
```

5. Allocate memory on a Compute instance. This is done by creating an instance of either ArrayInt, ArrayDec, MatrixInt, MatrixDec. The Compute instance you wish to allocate this memory is passed as a parameter along with the requested size of the memory area you want.
```
***MatrixDec, ArrayInt Interface Required
int length = 10
int width = 10
int height = 10
ArrayInt array = new ArrayInt(liveDevice, length)
MatrixDec mat = new MatrixDec(liveDevice, height, width)
```

6. Build a program for a Compute instance by providing the kernel code entry point function name and the kernel source code. For now only .cl kernels are supported.
```
***Program Interface Required
Program p = new Program(liveDevice, fname, source)
```

7. Run a program on a Compute instance. To do this, collect together all the ArrayInt, MatrixDec etc instances a Program instance requires as parameters. All ArrayX and MatrixX types are extensions of ExtMemory so can be stored together in a ExtMemroy array.
```
*** ExtMemory Interface Required
ExtMemory params[] = new ExtMemory[programParamCount]
params[0] = mat
params[1] = array

p.setParameters(params)

liveDevice.runProgram(p)
```

8. Read result of program execution. All extensions of the ExtMemory type have read() and write() functions, one of the parameters of the Program that has just been executed on a Compute instance will been were the output of the program was stored (usually the last parameter). Use that ExtMemory instance's read function to get the result of the computation back into Dana.
```
int computeOutput = array.read()
```

# External Dependencies

The `io.compute` package includes a pre-built OpenCL ICD loader. Depending on your platform, you may also need to separately install an OpenCL implementation for your hardware device(s); the `io.compute` framework will fail to operate without one. On Windows and Mac devices there is usually an OpenCL implementation installed with the OS and its associated hardware drivers. On Linux platforms you may need to manually install an OpenCL implementation.

For integrated Intel GPUs on Ubuntu, for example, you might use the command:

```
sudo apt-get install intel-opencl-icd
```

To use OpenCL on server-based Linux installations (rather than desktop-based ones), you may need to add your user to the "render" group:

```
sudo usermod -a -G render $LOGNAME
```

For other devices and platforms you may consult your hardware and platform vendor support for help on installing an OpenCL implementation.
