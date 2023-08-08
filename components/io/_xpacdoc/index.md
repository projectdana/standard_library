## Input/Output Package

This package contains interfaces for reading and writing to the command line (or console), and for reading and writing files. It also contains a sub-package `audio` which provides support for audio output / playback.

### Command-line output

We use the interface `io.Output` to write characters to the command-line, as in the following example:

```
component provides App requires io.Output out {

	int App:main(AppParam params[])
		{
		out.println("hello")

		return 0
		}
}
```

If we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o`

We can use `out.print()` to avoid a newline character at the end of each output; this can be used for example when printing a percentage completeness value:

```
component provides App requires io.Output out, data.IntUtil iu, time.Timer timer {

	int App:main(AppParam params[])
		{
		for (int i = 0; i < 100; i++)
			{
			out.print("\r$i%")
			timer.sleep(32)
			}
		
		out.println("\r100%")

		return 0
		}
}
```

Again, if we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o`

### Command-line input

We use the interface `io.Input` to read characters on the command-line that are typed by the user, as in the following example:

```
component provides App requires io.Output out, io.Input in, data.IntUtil iu {

	int App:main(AppParam params[])
		{
		out.print("name: ")
		
		char name[] = in.readln()
		
		out.print("password: ")
		
		char pw[] = in.readlnSecret()
		
		out.println("Your name was $name and your password is secret but was $(pw.arrayLength) characters long")

		return 0
		}
}
```

Here we read one input that is shown to the user as it is typed, and one input that does not show the characters as they are typed.

If we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o`

### Reading data from a file

The interface `io.File` allows us to read data from files. To read all data from a file specified as a command-line parameter, we would do:

```
component provides App requires io.Output out, io.File, data.IntUtil iu {

	int App:main(AppParam params[])
		{
		File fd = new File(params[0].string, File.READ)
		byte content[] = fd.read(fd.getSize())
		fd.close()
		
		out.println("all data read from file ($(content.arrayLength) bytes)")
		
		return 0
		}
}
```

If we save the above source code in a file `Main.dn`, and some other file `some_file.txt` exists in the same directory, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o some_file.txt`

We can also read file data incrementally until we reach the end of the file, as shown in the below example:

```
component provides App requires io.Output out, io.File, data.IntUtil iu {

	int App:main(AppParam params[])
		{
		int total = 0
		File fd = new File(params[0].string, File.READ)
		while (!fd.eof())
			{
			byte content[] = fd.read(8)
			total += content.arrayLength
			}
		fd.close()
		
		out.println("all data read from file ($total bytes)")
		
		return 0
		}
}
```

Again we compile and run this example using:

`dnc Main.dn`

`dana Main.o some_file.txt`

### Reading lines from a text file

When reading data from text files, it's sometimes useful to read that data one line at a time. We can do this using the `io.TextFile` interface, for example:

```
component provides App requires io.Output out, data.IntUtil iu, io.TextFile {

	int App:main(AppParam params[])
		{
		TextFile fd = new TextFile(params[0].string, File.READ)
		while (!fd.eof())
			{
			char content[] = fd.readLine()
			
			out.println("line: $content")
			}
		fd.close()
		
		return 0
		}
}
```

This example reads every line of a text file, printing each one to the command-line output, until the end of the file is reached.

If we save the above source code in a file `Main.dn`, and some other text file `some_file.txt` exists in the same directory, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o some_file.txt`

### Writing data to a file

We can write data to a file by opening that file in a write-based mode. In the below example we use the `File.CREATE` mode, which creates the file if doesn't exist, or erases any content of the specified file if it does exist:

```
component provides App requires io.Output out, io.File, data.IntUtil iu {

	int App:main(AppParam params[])
		{
		File fd = new File(params[0].string, File.CREATE)
		fd.write("hello!")
		fd.close()
		
		return 0
		}
}
```

If we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o myfile.txt`

### Appending data to a file

We can append data to the end of a file by opening that file in a write-based mode `File.WRITE`. This creates the file if doesn't exist, or opens the file in write-mode if it does exist:

```
component provides App requires io.Output out, io.File, data.IntUtil iu {

	int App:main(AppParam params[])
		{
		File fd = new File(params[0].string, File.WRITE)
		fd.setPos(fd.getSize())
		fd.write("another line, after the file was $(fd.getSize()) bytes long\n")
		fd.close()
		
		return 0
		}
}
```

We use the `setPos()` function to seek to the end of the file after opening it, then write more data at that position.

If we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o myfile.txt`

Issuing the second command here multiple times will repeatedly expand the file.

### Creating an in-memory file

It is sometimes useful to create an in-memory file, for example to pass memory-resident data to an interface that expects a File object as a parameter. We can do this using the semantic variant `io.File:mem`, as in the below example:

```
component provides App requires io.Output out, io.File:mem, data.IntUtil iu {

	int App:main(AppParam params[])
		{
		File fd = new File:mem("tmp", File.WRITE)
		fd.write("hello!")
		
		out.println("memory file has $(fd.getSize()) bytes")
		
		return 0
		}
}
```

We might then use `fd.setPos(0)` before passing `fd` to another interface that expects a `File` object.

If we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o myfile.txt`

### Getting the files in a directory

We can inspect files and directories using the interface `io.FileSystem`. To examine the files and folders present in a given directory, we could do:

```
component provides App requires io.Output out, data.IntUtil iu, io.FileSystem fileSystem {

	int App:main(AppParam params[])
		{
		char dir[] = "."
		FileEntry files[] = fileSystem.getDirectoryContents(".")
		
		for (int i = 0; i < files.arrayLength; i++)
			{
			FileInfo info = fileSystem.getInfo("$dir/$(files[i].name)")
			if (info.type == FileInfo.TYPE_DIR)
				out.println("DIR: $(files[i].name)")
				else
				out.println("FILE: $(files[i].name)")
			}
		
		return 0
		}
}
```

Here we use the function `getDirectoryContents()` to get the list of entities in the directory, and then the function `getInfo()` on each entity to get their details.

If we save the above source code in a file `Main.dn`, we would compile and run this system with the commands:

`dnc Main.dn`

`dana Main.o myfile.txt`