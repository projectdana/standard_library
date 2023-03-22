## Chart Package

This package has a set of components for drawing different kinds of chart to visualise data.

Here we show how we can draw some simple charts using this library (but many more are available).

Create a new file `Main.dn` and open it in a text editor. We're going to use the same dependencies as a simple GUI application, plus a chart (we'll start with a bar chart). We start with this code in our new file:

    component provides App requires ui.IOLayer coreui, ui.Window,
    				stats.chart.Category:bar {
    
    }

The `App` interface has one function called main. Any executable component will implement App, indicating it has a main method that Dana can launch.

We now need to implement our App interface, which we'll do like this:

```
component provides App requires ui.IOLayer coreui, ui.Window,
				stats.chart.Category:bar {

Window window

eventsink AppEvents(EventData ed)
	{
	if (ed.source === coreui && ed.type == IOLayer.[ready])
	   {
	   startApp()
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
	window.setSize(250, 150)
	window.setVisible(true)
	
	Category chart = new Category:bar()
	chart.setSize(250, 150)
	
	chart.addSample("Gnomes", new dec[](1.0, 5.0, 10.4, 4.3))
	chart.addSample("Elves", new dec[](1.5, 2.79, 9.91))
	
	chart.setYMarkerInterval(1.0)
	chart.setYGridInterval(1.0)
	chart.setYLabelInterval(2.0)
	
	chart.showErrorBars(true)
	
	window.addObject(chart)
	
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
```

Most of this code is the same a basic GUI example: we prepare the GUI subsystem, wait for a ready event, then create our window. We then instantiate a new `Category:bar` instance, add some categories, and configure the chart's axis behaviour.

We can now compile the program using the Dana compiler. Open a command-prompt in the directory containing your source code file and type:

`dnc Main.dn`

And pressing enter. This will compile your component.

We run the program using Dana's interpreter by typing:

`dana Main`

And pressing enter. You should see your simple bar graph drawn on the screen.

If you like, you can change the requires interface `stats.chart.Category:bar` to be `stats.chart.Category:box` for a box plot instead, and also change the corresponding chart instantiation line to be `Category chart = new Category:box()`.

In this example we used the APIs:

- [ui.IOLayer](../../../files/ui.IOLayer_IOLayer.html)
- [ui.Window](../../../files/ui.Window_Window.html)
- [stats.chart.Category](../../../files/stats.chart.Category_Category.html)

You might also like to explore alternative charts using the APIs:

- [stats.chart.CategoryMulti](../../../files/stats.chart.CategoryMulti_CategoryMulti.html)
- [stats.chart.Series](../../../files/stats.chart.Series_Series.html)
- [stats.chart.SeriesMulti](../../../files/stats.chart.SeriesMulti_SeriesMulti.html)
