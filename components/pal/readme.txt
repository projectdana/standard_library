This is a meta-control framework for Dana programs called PAL (Perception, Assembly and Learning).

This system is the result of ideas, code and contributions from Roberto Rodrigues Filho and Barry Porter.

For the most recent research version of this framework, see http://rex.projectdana.com

We use RESTful web services to define an API for the Perception/Assembly part of the framework.

The learning module uses this API to learn about and control the running system.

To run a program in the PAL framework, use:

dana pal.rest <mainComponent.o>

This starts the RESTful web services API for perception and assembly.

You then need to write a learning algorithm. See the "control" subdirectory for a base example of this,
which simply cycles through every available configuration of the system.

To run this very simple controller, use:

dana pal.control.cycle

This will connect to the RESTful web services API of pal.rest and will start adapting the system.

The RESTful web services API of the Perception/Assembly system is defined as follows:

GET /meta/get_all_configs HTTP/1.0

purpose: get a list of all available configurations
return mime type: text/json
return value: JSON array of configuration strings
example return value:

{"configs" : ["../web_server_simple/WebServer.o,../web_server_simple/http/HTTPHandler.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/http/Utils.o,C:/ProgramFiles/Dana/components/data/StringUtil.o,C:/ProgramFiles/Dana/components/data/adt/List.o,C:/ProgramFiles/Dana/components/io/File.o,./Perception.o,C:/ProgramFiles/Dana/components/net/TCP.o,C:/ProgramFiles/Dana/components/net/TCP.o|FileSystem:1:2,File:1:3,Utils:1:4,List:5:6,StringUtil:4:5,FileSystem:4:7,Perception:1:8,HTTPHandler:0:1,TCPServerSocket:0:9,TCPSocket:0:10", "../web_server_simple/WebServer.o,../web_server_simple/http/HTTPHandlerCache.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/http/Utils.o,C:/ProgramFiles/Dana/components/data/StringUtil.o,C:/ProgramFiles/Dana/components/data/adt/List.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/cache/Cache.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,./Perception.o,C:/ProgramFiles/Dana/components/net/TCP.o,C:/ProgramFiles/Dana/components/net/TCP.o|FileSystem:1:2,File:1:3,Utils:1:4,List:5:6,StringUtil:4:5,FileSystem:4:7,Cache:1:8,File:8:9,FileSystem:8:10,Perception:1:11,HTTPHandler:0:1,TCPServerSocket:0:12,TCPSocket:0:13", "../web_server_simple/WebServer.o,../web_server_simple/http/HTTPHandlerComCache.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/http/Utils.o,C:/ProgramFiles/Dana/components/data/StringUtil.o,C:/ProgramFiles/Dana/components/data/adt/List.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/cache/Cache.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/compression/gzip.o,C:/ProgramFiles/Dana/components/os/Run.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/time/DateUtil.o,./Perception.o,C:/ProgramFiles/Dana/components/net/TCP.o,C:/ProgramFiles/Dana/components/net/TCP.o|FileSystem:1:2,File:1:3,Utils:1:4,List:5:6,StringUtil:4:5,FileSystem:4:7,Cache:1:8,File:8:9,FileSystem:8:10,Compressor:1:11,Run:11:12,FileSystem:11:13,DateUtil:11:14,Perception:1:15,HTTPHandler:0:1,TCPServerSocket:0:16,TCPSocket:0:17"]}

GET /meta/get_config HTTP/1.0

purpose: report the current configuration of the system
return mime type: text/json
return value: a configuration string
example return value:

{"config" : "../web_server_simple/WebServer.o,../web_server_simple/http/HTTPHandler.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/http/Utils.o,C:/ProgramFiles/Dana/components/data/StringUtil.o,C:/ProgramFiles/Dana/components/data/adt/List.o,C:/ProgramFiles/Dana/components/io/File.o,./Perception.o,C:/ProgramFiles/Dana/components/net/TCP.o,C:/ProgramFiles/Dana/components/net/TCP.o|FileSystem:1:2,File:1:3,Utils:1:4,List:5:6,StringUtil:4:5,FileSystem:4:7,Perception:1:8,HTTPHandler:0:1,TCPServerSocket:0:9,TCPSocket:0:10"}

GET /meta/get_perception HTTP/1.0

purpose: report all perception data collected since this function was last called, or since set_config was called (whichever was more recent)
notes: "value" fields are a total; you should divide this by "count" to get the average value
return mime type: text/json
return value: perception data, formatted as a JSON object
example return value:

{"metrics" : [ {"name" : "response_time", "source" : "../web_server_simple/http/HTTPHandler.o", "value" : 6.0, "count" : 3, "preferHigh" : false, "startTime" : "0000-00-00 00:00:00", "endTime" : "0000-00-00 00:00:00"}], "events" : [{"name" : "text", "source" : "../web_server_simple/http/HTTPHandler.o", "value" : 3871.0, "count" : 3, "startTime" : "0000-00-00 00:00:00", "endTime" : "0000-00-00 00:00:00"}]}

POST /meta/set_config HTTP/1.0
Content-Type: text/json

purpose: adapt the system to a selected configuration, passed in as a plain string (must be one of the configurations from the JSON array returned by get_configs); no perception data collected before this point will be returned by get_perception
notes: this is a synchronous call, so the return of a status code indicates that the adaptation procedure has completed
return mime type: text (status code only, potentially with an explanatory message in plain text)
return value: HTTP status code only
example return value: N/A
example input value:

{"config" : "../web_server_simple/WebServer.o,../web_server_simple/http/HTTPHandler.o,C:/ProgramFiles/Dana/components/io/File.o,C:/ProgramFiles/Dana/components/io/File.o,../web_server_simple/http/Utils.o,C:/ProgramFiles/Dana/components/data/StringUtil.o,C:/ProgramFiles/Dana/components/data/adt/List.o,C:/ProgramFiles/Dana/components/io/File.o,./Perception.o,C:/ProgramFiles/Dana/components/net/TCP.o,C:/ProgramFiles/Dana/components/net/TCP.o|FileSystem:1:2,File:1:3,Utils:1:4,List:5:6,StringUtil:4:5,FileSystem:4:7,Perception:1:8,HTTPHandler:0:1,TCPServerSocket:0:9,TCPSocket:0:10"}