## Dana API

This is the Dana API documentation, which provides information about how to use every interface in the standard library.

There are two different ways to view this documentation: as a flat list of all interfaces, or as a package hierarchy. You can select which view you prefer on the left panel.

Some packages also have package-level documentation which includes examples and tutorials of how to use the APIs in that package; this package-level documentation is most easily accessed in the package hierarchy view.

This documentation is automatically generated from the Dana source code. You can generate a local copy on your own computer by opening a terminal window in your `(dana home)/components` directory and typing `dana docgen`. This command generates the documentation in a directory called `_docs`.

## Base package / a simple example program

The base Dana package contains a small number of core language interfaces. The most frequently used one is the `App` interface, which is the entry point for any program, from web servers to graphical window-based applications.

To write a simple application, we create a new file with a `.dn` extension (the `.dn` extension is used to represent a Dana source code file). Let's imagine we create a file called `Main.dn` and write the following source code inside that file:

```
component provides App requires io.Output out, io.Input in, io.File {
    
    int App:main(AppParam params[])
        {
        out.print("Enter some text: ")
        char input[] = in.readln()
        
        File f = new File("out.txt", File.CREATE)
        f.write(input)
        f.close()
        
        return 0
        }
    }
```

Assuming that Dana is correctly installed, we can save this file and compile it using the command:

`dnc Main.dn`

We can then run the program with the command:

`dana Main.o`