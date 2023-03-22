## UI Framework

The UI package contains a rich set of user interface controls to create desktop applications.

This program shows how we can write a simple graphical user interface application.

Create a new file `Main.dn` and open it in a text editor. We're going to use the IOLayer interface for the GUI toolkit, the Window interface, the Button interface, and the command-line output interface. We'll start with this code in our new file:

    component provides App requires ui.IOLayer coreui, ui.Window,
    				ui.Button, io.Output out {
    
    }

The `App` interface has one function called main. Any executable component will implement App, indicating it has a main method that Dana can launch.

We now need to implement our App interface, which we'll do like this:

    component provides App requires ui.IOLayer coreui, ui.Window,
    				ui.Button, io.Output out {
    
    Window window
    Button b1
    Button b2
    
    eventsink AppEvents(EventData ed)
    	{
    	if (ed.source === coreui && ed.type == IOLayer.[ready])
    	   {
    	   startApp()
    	   }
    	   else if (ed.type == Button.[click] && ed.source === b1)
    	   {
    	   out.println("A BUTTON CLICK!")
    	   }
    	   else if (ed.type == Button.[click] && ed.source === b2)
    	   {
    	   out.println("A BUTTON CLICK TOO!")
    	   }
    	   else if (ed.source === window && ed.type == Window.[close])
    	   {
    	   window.close()
    	   coreui.shutdown()
    	   }
    	}
    
    void startApp()
    	{
    	window = new Window("MyWindow")
    	window.setSize(250, 250)
    	window.setVisible(true)
    	
    	b1 = new Button("One")
    	b2 = new Button("Two")
    	
    	b1.setPosition(10, 30)
    	b2.setPosition(70, 30)
    	
    	window.addObject(b1)
    	window.addObject(b2)
    	
    	sinkevent AppEvents(b1)
    	sinkevent AppEvents(b2)
    	
    	sinkevent AppEvents(window)
    	}
    
    int App:main(AppParam params[])
    	{
    	//initialise the system-level UI framework
    	coreui.init()
    	
    	//listen for startup events from the system
    	sinkevent AppEvents(coreui)
    	
    	//run UI system loop, which blocks until last window closed
    	coreui.run()
    	
    	return 0
    	}
    
    }

There's quite a lot going on here, so we'll walk through each part. The main() method starts up the IOLayer framework, which prepares the GUI subsystem to do some work. It then listens for events from the IOLayer framework itself, which will tell us when the framework is ready to go. We then run the main IOLayer system loop, which dispatches an OS-level event loop.

To receive events from both the IOLayer framework, and from our own window, we declare an event sink. We give our event sink the name AppEvents, and provide it with the standard parameter for event sinks. Our event sink method will be triggered whenever we receive an event from an object which we have connected to that sink. Event sinks use a queue of events that they have received, and so only a single AppEvents thread is ever running at a time. Within our event sink we check the source of the event, and then check the type of the event.

When we first receive the `ready` event from the IOLayer framework, we call a function which sets up our application window, and adds two buttons to the window. Each button object can emit events, and we connect those objects to our AppEvents sink. Whenever a button is clicked on, we then get a click event to our AppEvents sink, and we print out some text to the command line.

We can now compile the program using the Dana compiler. Open a command-prompt in the directory containing your source code file and type:

`dnc Main.dn`

And pressing enter. This will compile your component.

We run the program using Dana's interpreter by typing:

`dana Main`

And pressing enter. You should see a window with two buttons that you can click on.

In this example we used the APIs:

- [io.Output](../../files/io.Output_Output.html)
- [ui.IOLayer](../../files/ui.IOLayer_IOLayer.html)
- [ui.Window](../../files/ui.Window_Window.html)
- [ui.Button](../../files/ui.Button_Button.html)
