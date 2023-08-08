## Network Package

This package contains interfaces to support low-level networking operations, including TCP, UDP, and TLS(SSL). This guide demonstrates how to write simple client and server programs using each of these protocols.

### TCP Server and Client

This example shows a simple client and server, using blocking TCP sockets. The server program is shown first:

```
component provides App requires net.TCPServerSocket, net.TCPSocket, io.Output out, data.IntUtil iu {
		
	int App:main(AppParam params[])
		{
		TCPServerSocket server = new TCPServerSocket()
		
		if (!server.bind(TCPServerSocket.ANY_ADDRESS, 3000))
			throw new Exception("failed to bind server socket")
		
		while (true)
			{
			TCPSocket socket = new TCPSocket()
			
			if (socket.accept(server))
				{
				byte buf[] = socket.recv(8)
				out.println("received: $buf")
				buf = socket.recv(8)
				out.println("received: $buf")
				socket.send("ABCD")
				socket.disconnect()
				}
			}
		return 0
		}

}
```
Here we bind our server socket to a particular port, on any available network interface, and wait for clients to connect. When a client connects we assume we're going to receive two 8-byte chunks of data, and then send a 4-byte chunk of data back to the client in response.

Our corresponding client program is shown next:

```
component provides App requires io.Output out, net.TCPSocket, time.Timer timer {

	int App:main(AppParam params[])
		{
		TCPSocket socket = new TCPSocket()

		socket.connect("127.0.0.1", 3000)

		socket.send("hello...")

		timer.sleep(1000)

		socket.send(" person!")

		byte buf[] = socket.recv(4)

		socket.disconnect()

		out.println("buf: $buf")

		return 0
		}
}
```

Our client connects to the server on the advertised port, then sends two 8-byte chunks of data with a pause in between, then expects a 4-byte chunk of data in response.

If we assume that our server code is in a file `TCPServer.dn`, and our client is in a file `TCPClient.dn`, we would compile an run this system as follows:

`dnc TCPServer.dn`

`dnc TCPClient.dn`

`dana TCPServer.o`

`dana TCPClient.o`

Note that you will need two different terminals to run the server (first) and then the client (second).

### Non-blocking TCP Server

The above example shows a TCP server that uses blocking sockets; this means that calls to `recv()` will block until the requested amount of data has actually been received (or the socket has been closed by the client, whichever happens first). In systems designed to handle many clients, this blocking approach can sometimes be undesirable: let's imagine we have a pool of 8 threads assigned to handle all client connections, and for each new connection that arrives we add that client socket to the end of a queue in one of our threads. In this design, each thread must receive at least something from the client at the front of its queue before it can consider receiving anything from any other client in the queue. In some cases this can cause poor overall server performance, because the server is to some extent rate-limited by the slowest client.

One solution to this is for the server to use non-blocking sockets, in which `recv()` always returns immediately with whatever data is available (even if that's no data at all). To make this approach viable, we also really need to know *when* data is available to receive from a given socket, to prevent busy-waiting loops that constantly try to receive something from every client. A non-blocking socket is typically therefore used together with a monitor which provides notifications on when different socket states are available.

A TCP server that uses non-blocking servers, and is otherwise identical in functionality to the above blocking TCP server, is shown below.

```
component provides App requires net.TCPServerSocket, net.TCPSocket, net.TCPMonitor, io.Output out, data.IntUtil iu, time.Timer timer {
	
	TCPMonitor monitor

	eventsink NetEvents(EventData ed)
		{
		TCPSocket source = ed.source
		monitor.armSendNotify(source)
		}
	
	void dataThread()
		{
		while (true)
			{
			MonitorEvent events[] = monitor.wait()

			if (events.arrayLength == 0)
				{
				timer.sleep(1)
				}
				else
				{
				for (int i = 0; i < events.arrayLength; i++)
					{
					out.println("$(events.arrayLength) socket ready")
					if (events[i].recvReady)
						{
						char msg[] = null
						while (true)
							{
							char buf[] = events[i].socket.recv(10)
							msg = new char[](msg, buf)

							if (msg.arrayLength != 0 && msg[msg.arrayLength-1] == "!")
								{
								events[i].socket.send("ABCD")
								}

							if (buf == null)
								{
								if (!events[i].socket.connected())
									{
									out.println("[disconnect]")
									monitor.remSocket(events[i].socket)
									events[i].socket.disconnect()
									}
								break
								}
							}
							
						out.println("msg: $msg")
						}
						
					if (events[i].sendReady)
						{
						//do something
						events[i].socket.sendBuffer()
						}
						
					if (events[i].close)
						{
						out.println("[close]")
						monitor.remSocket(events[i].socket)
						events[i].socket.disconnect()
						}
					}
				}
			}
		}
		
	int App:main(AppParam params[])
		{
		TCPServerSocket server = new TCPServerSocket()
			
		if (!server.bind(TCPServerSocket.ANY_ADDRESS, 3000))
			throw new Exception("failed to bind server socket")
			
		monitor = new TCPMonitor()

		asynch::dataThread()

		while (true)
			{
			TCPSocket socket = new TCPSocket()
			
			if (socket.accept(server))
				{
				socket.setNonBlocking()
				monitor.addSocket(socket)
				monitor.armSendNotify(socket)
				}
			}

		return 0
		}

}

```

This program again starts by binding a server socket to a particular port and waiting for new client connections. Is also creates a `TCPMonitor` instance and starts a new thread to service that instance. When a new client connects, the client socket is set to non-blocking mode, and the socket is added to the monitor.

The monitor thread calls `wait()`, which blocks until some activity occurs on *any* socket that the monitor is watching. The `wait()` function returns an array of all sockets that have some activity, and the monitoring thread then checks which kind of activity it is (receive-available, send-available, or connection closed).

To compile and run this program, assuming it's in a file called `TCPServerNB.dn`, we do:

`dnc TCPServerNB.dn`

`dana TCPServerNB.o`

The same client program from the blocking TCP server/client can be used.

Note that we have not included the complete *send* elements of the non-blocking socket state machine in this example. In practice, the underlying `send()` function can also block if a given TCP socket is not ready to send anything (e.g. the OS buffer is full because the client hasn't acknowledged enough packets). It's therefore possible that `send()` returns fewer bytes as actually being sent than were intended; in this case the TCPSocket instance will issue a `sendWait()` event, upon which the server should arm send-available notifications on that socket. Once a send-available notification arrives from the monitor, the server should use `sendBuffer()` on the TCP socket to attempt to send any un-sent bytes.

### UDP Server and Client

Unlike TCP, UDP does not have the notion of a "connection" and instead deals in individual packets, each of which has no delivery guarantees. A UDP server still listens on a given port, and clients send single packets to that port.

This example shows a simple client and server, using blocking UDP semantics. The server program is shown first:

```
component provides App requires io.Output out, data.IntUtil iu, net.UDPServer {

	int App:main(AppParam params[])
		{
		UDPServer socket = new UDPServer()
		socket.bind("127.0.0.1", 3000)

		Datagram packet = socket.recv()

		out.println("received: '$(packet.content)', from $(packet.address):$(packet.port)")

		return 0
		}
}
```

This program binds to a local address and port, then waits for a packet to arrive.

A corresponding client program may look like this:

```
component provides App requires io.Output out, net.UDPClient {

	int App:main(AppParam params[])
		{
		UDPClient socket = new UDPClient()
		socket.send("127.0.0.1", 3000, "hello...")
		return 0
		}
}
```

This program simple sends some data to the above server address and port.

If we assume that our server code is in a file `UDPServer.dn`, and our client is in a file `UDPClient.dn`, we would compile an run this system as follows:

`dnc UDPServer.dn`

`dnc UDPClient.dn`

`dana UDPServer.o`

`dana UDPClient.o`

Note that you will need two different terminals to run the server (first) and then the client (second).

### Non-blocking UDP Server

The above example shows a UDP server that uses a blocking socket; this means that calls to `recv()` will block until some has actually been received.

We can write a non-blocking UDP server by using a `UDPMonitor` instance as follows:

```
component provides App requires io.Output out, data.IntUtil iu, net.UDPServer, net.UDPMonitor {

	int App:main(AppParam params[])
		{
		UDPMonitor monitor = new UDPMonitor()

		UDPServer socket = new UDPServer()
		socket.bind("127.0.0.1", 3000)
		socket.setNonBlocking()

		monitor.addSocket(socket)

		while (true)
			{
			MonitorEvent events[] = monitor.wait()
			
			for (int i = 0; i < events.arrayLength; i++)
				{
				Datagram packet = events[i].socket.recv()
				out.println("received: '$(packet.content)', from $(packet.address):$(packet.port)")
				}
			}

		return 0
		}
}
```

Here we still bind to a local address and port, but we then set the socket as non-blocking, add it to a `UDPMonitor` instance, and wait for activity on that monitor.

To compile and run this program, assuming it's in a file called `UDPServerNB.dn`, we do:

`dnc UDPServerNB.dn`

`dana UDPServerNB.o`

The same client program from the blocking UDP server/client can be used.

### TLS (SSL) Server and Client

The Transport Layer Security protocol TLS, often known as SSL, is one of the standard ways to establish secure communications over the Internet. It is layered on top of the TCP protocol and has the same connection-oriented semantics.

To run this example you will need an SSL (X509) certificate, and an associated private key. In this section we show an example based on blocking TCP sockets, with the server program shown first:

```
component provides App requires net.TCPServerSocket, net.TCPSocket, net.TLS, net.TLSContext, io.File, io.Output out, data.IntUtil iu, time.Timer timer {
	
	TLSContext tlsContext

	bool loadSSLContext(char certificatePath[], byte keyPath[])
		{
		File fd = new File(certificatePath, File.READ)
		byte certificate[] = fd.read(fd.getSize())
		fd.close()
		
		fd = new File(keyPath, File.READ)
		byte privateKey[] = fd.read(fd.getSize())
		fd.close()
		
		tlsContext = new TLSContext(TLSContext.SERVER)
		//tlsContext.setCipherSet(TLSContext.CIPHER_ALL)
		
		if (!tlsContext.setCertificate(certificate, privateKey)) throw new Exception("certificate or private key is invalid")
		
		return true
		}
	
	void processStream(TCPSocket client, TLS ssl)
		{
		if (ssl.accept(client) == TLS.OK)
			{
			byte buf[] = ssl.recv(8)

			out.println("buf: '$buf'")

			buf = ssl.recv(8)

			out.println("buf: '$buf'")

			ssl.send("ABCD")

			ssl.close()

			client.disconnect()
			}
		}

	int App:main(AppParam params[])
		{
		if (!loadSSLContext("mycertificate.crt", "private_key.txt"))
			return 1
		
		TCPServerSocket server = new TCPServerSocket()
		
		if (!server.bind(TCPServerSocket.ANY_ADDRESS, 3000))
			throw new Exception("failed to bind server socket")
		
		while (true)
			{
			TCPSocket client = new TCPSocket()
			
			if (client.accept(server))
				{
				TLS ssl = new TLS(tlsContext)
				
				processStream(client, ssl)
				}
			}

		return 0
		}

}
```

Much like our TCP example, we bind our TCP server socket to a particular port, on any available network interface, and wait for clients to connect. When a client connects we upgrade that connection to a TLS one, and then assume we're going to receive two 8-byte chunks of data, and then send a 4-byte chunk of data back to the client in response.

The corresponding client program looks like this:

```
component provides App requires io.Output out, net.TCPSocket, net.TLS, net.TLSContext, net.TLSCertStore, time.Timer timer {

	int App:main(AppParam params[])
		{
		TLSCertStore certStore = new TLSCertStore()
		//certStore.addCertificate("aappl")
		
		TCPSocket socket = new TCPSocket()
		socket.connect("127.0.0.1", 3000)

		TLSContext context = new TLSContext(TLSContext.CLIENT)
		TLS ssl = new TLS(context)

		ssl.connect(socket)
		
		//char cert[] = ssl.getPeerCertificate()
		//if (ssl.verifyCertificate(certStore, cert, null).status == VerifyStatus.FAIL) return 1

		ssl.send("hello...")

		timer.sleep(1000)

		ssl.send(" person!")

		byte buf[] = ssl.recv(4)
			
		ssl.close()
		socket.disconnect()

		out.println("buf: '$buf'")

		return 0
		}
}

```

Our client connects to the server on the advertised port, upgrades the connection to TLS, then sends two 8-byte chunks of data with a pause in between, then expects a 4-byte chunk of data in response.

**Note that our client code does not perform certificate verification, which should occur before the client chooses to send any data to the server; this element has been commented out to make it easier to run the example without a trusted certificate store.**

If we assume that our server code is in a file `SSLServer.dn`, and our client is in a file `SSLClient.dn`, we would compile an run this system as follows:

`dnc SSLServer.dn`

`dnc SSLClient.dn`

`dana SSLServer.o`

`dana SSLClient.o`

Note that you will need two different terminals to run the server (first) and then the client (second).

### TLS (SSL) Non-blocking Server

With the same rationale as a non-blocking TCP server, it is sometimes useful to have non-blocking TLS sockets. Here we provide an example non-blocking TLS server which builds on our TCP example:

```
data TLSInfo
	{
	const byte S_PRE_ACCEPT = 1
	const byte S_ACCEPT_WAIT_READ = 2
	const byte S_ACCEPT_WAIT_WRITE = 3
	const byte S_CONNECTED = 4
	const byte S_FAIL = 5

	const byte S_STREAM_WAIT_READ = 6
	const byte S_STREAM_WAIT_WRITE = 7

	byte state

	TLS ssl
	}

component provides App requires net.TCPServerSocket, net.TCPSocket, net.TCPMonitor, net.TLS, net.TLSContext, io.File, io.Output out, data.IntUtil iu, time.Timer timer {
	
	TCPMonitor monitor

	TLSContext tlsContext

	bool loadSSLContext(char certificatePath[], byte keyPath[])
		{
		File fd = new File(certificatePath, File.READ)
		byte certificate[] = fd.read(fd.getSize())
		fd.close()
		
		fd = new File(keyPath, File.READ)
		byte privateKey[] = fd.read(fd.getSize())
		fd.close()
		
		tlsContext = new TLSContext(TLSContext.SERVER)
		//tlsContext.setCipherSet(TLSContext.CIPHER_ALL)
		
		if (!tlsContext.setCertificate(certificate, privateKey)) throw new Exception("certificate or private key is invalid")
		
		return true
		}
	
	eventsink TLSNetEvents(EventData ed)
		{
		TLS source = ed.source
		TCPSocket socket = source.getSocket()
		monitor.armSendNotify(socket)
		}
	
	void dataThread()
		{
		while (true)
			{
			MonitorEvent events[] = monitor.wait()

			if (events.arrayLength == 0)
				{
				timer.sleep(1)
				}
				else
				{
				out.println("-- $(events.arrayLength) sockets ready --")
				for (int i = 0; i < events.arrayLength; i++)
					{
					if (events[i].recvReady)
						{
						out.println("[recv ready]")

						TLSInfo ti = events[i].userData

						if (ti.state == TLSInfo.S_PRE_ACCEPT || ti.state == TLSInfo.S_ACCEPT_WAIT_READ || ti.state == TLSInfo.S_ACCEPT_WAIT_WRITE)
							{
							out.println(" -- calling accept in state $(ti.state)")

							int status = ti.ssl.accept(events[i].socket)

							if (status == TLS.WAIT_READ)
								ti.state = TLSInfo.S_ACCEPT_WAIT_READ
								else if (status == TLS.WAIT_WRITE)
								ti.state = TLSInfo.S_ACCEPT_WAIT_WRITE
								else if (status == TLS.OK)
								ti.state = TLSInfo.S_CONNECTED
								else if (status == TLS.FAIL)
								ti.state = TLSInfo.S_FAIL
								
							out.println(" -- state now $(ti.state); status was $status")

							if (ti.state == TLSInfo.S_ACCEPT_WAIT_WRITE)
								monitor.armSendNotify(events[i].socket)

							if (ti.state == TLSInfo.S_FAIL)
								{
								monitor.remSocket(events[i].socket)
								ti.ssl.close()
								events[i].socket.disconnect()
								out.println("(socket closed after accept-fail)")
								}
							}
							else if (ti.state == TLSInfo.S_CONNECTED)
							{
							char msg[] = null
							while (true)
								{
								char buf[] = ti.ssl.recv(10)
								msg = new char[](msg, buf)

								if (msg.arrayLength != 0 && msg[msg.arrayLength-1] == "!")
									{
									ti.ssl.send("ABCD")
									}

								if (buf == null)
									{
									if (!events[i].socket.connected())
										{
										monitor.remSocket(events[i].socket)
										ti.ssl.close()
										events[i].socket.disconnect()
										out.println("(socket closed after read)")
										break
										}
										else
										{
										out.println("(zero-read; checking TLS status)")

										int s = ti.ssl.getStatus()

										if (s == TLS.WAIT_READ)
											{
											out.println("(tls has status WAIT_READ)")
											break
											}
											else if (s == TLS.WAIT_WRITE)
											{
											out.println("(tls has status WAIT_WRITE)")
											monitor.armSendNotify(events[i].socket)
											break
											}
										}
									}
								}
							
							out.println("msg: $msg")
							}
						}
					
					if (events[i].sendReady)
						{
						out.println("[send ready]")

						TLSInfo ti = events[i].userData

						if (ti.state == TLSInfo.S_PRE_ACCEPT || ti.state == TLSInfo.S_ACCEPT_WAIT_READ || ti.state == TLSInfo.S_ACCEPT_WAIT_WRITE)
							{
							out.println(" -- calling accept in state $(ti.state)")

							int status = ti.ssl.accept(events[i].socket)

							if (status == TLS.WAIT_READ)
								ti.state = TLSInfo.S_ACCEPT_WAIT_READ
								else if (status == TLS.WAIT_WRITE)
								ti.state = TLSInfo.S_ACCEPT_WAIT_WRITE
								else if (status == TLS.OK)
								ti.state = TLSInfo.S_CONNECTED
								else if (status == TLS.FAIL)
								ti.state = TLSInfo.S_FAIL
							
							out.println(" -- state now $(ti.state)")

							if (ti.state == TLSInfo.S_ACCEPT_WAIT_WRITE)
								monitor.armSendNotify(events[i].socket)
							
							if (ti.state == TLSInfo.S_FAIL)
								{
								monitor.remSocket(events[i].socket)
								ti.ssl.close()
								events[i].socket.disconnect()
								out.println("(socket closed after accept-fail)")
								}
							}
							else if (ti.state == TLSInfo.S_CONNECTED)
							{
							ti.ssl.sendBuffer()
							}
						}
					
					if (events[i].close)
						{
						out.println("[close ready]")

						monitor.remSocket(events[i].socket)
						events[i].socket.disconnect()
						out.println("(socket closed)")
						}
					}
				}
			}
		}

	int App:main(AppParam params[])
		{
		if (!loadSSLContext("www_projectdana_com.crt", "private_key.txt"))
			return 1
		
		TCPServerSocket server = new TCPServerSocket()
		
		if (!server.bind(TCPServerSocket.ANY_ADDRESS, 3000))
			throw new Exception("failed to bind server socket")
		
		monitor = new TCPMonitor()
		asynch::dataThread()
		
		while (true)
			{
			TCPSocket client = new TCPSocket()
			
			if (client.accept(server))
				{
				TLS ssl = new TLS(tlsContext)
				
				TLSInfo ti = new TLSInfo(TLSInfo.S_PRE_ACCEPT, ssl)

				client.setNonBlocking(ti)
				sinkevent TLSNetEvents(ssl)
				monitor.addSocket(client, ti)
				}
			}

		return 0
		}

}
```

The above example generally follows that of our non-blocking TCP server, but must also track the state machine of the TLS connection. For example, when we call `accept(s)` to upgrade to a TLS connection, this TLS `accept()` call may result in a temporary failure because the underlying TCP socket has no data available to receive. We must then wait for receive-ability on this underlying TCP socket, then call the TLS `accept()` function again.

To compile and run this program, assuming it's in a file called `SSLServerNB.dn`, we do:

`dnc SSLServerNB.dn`

`dana SSLServerNB.o`

The same client program from the blocking TLS (SSL) server/client can be used.

### Data serialisation

Data instances can be directly serialised to a byte array for network transport, as long as the data type only contains primitive types, including fixed-length arrays of primitive types (i.e., the data type has no fields of reference type).

Let's imagine that we define following the data type:

```
data Header {
	const int2 MAGIC = 1234
	int2 magic
	const int4 T_TXT_MSG = 1
	int4 type
	int4 payload
	}
```

Here we've used specific-size integer types so that the source code has maximum cross-platform compatibility.

Our example data type has a "magic" field which we might use to identify that this is a packet from our protocol; a "type" field which we might use to decide which packet type this is; and a "payload" field which we can use to indicate the size of the data payload which follows the header.

On the client side we might then do this (assuming our server is running on local host):

```
TCPSocket s = new TCPSocket()
s.connect("127.0.0.1", 8090)

char payload[] = "hello!"

Header header = new Header(Header.MAGIC, Header.T_TXT_MSG, payload.arrayLength)

byte stream[] = dana.serial(header)

s.send(stream)
s.send(payload)
```

In the above code, the `dana.serial()` operation returns a byte array which is a shallow-copy of the actual data instance (i.e., writing to the byte array `stream` will actually change the values in the daa instance `header`).

On the server-side, we might then do this, assuming we've already accepted the client connection as the socket `s`:

```
byte buf[] = s.recv(stream.arrayLegth)
stream =[] buf
	
//check we actually received enough bytes for a valid header, and heck the protocol magic matches
if (buf.arrayLength == stream.arrayLength && header.magic == Header.MAGIC)
   {
   //now receive the payload, according the number of payload bytes indicated in the header
   buf = s.recv(header.payload)
		
   //check we received the expected number of payload bytes, then dispatch to a handler function
   if (buf.arrayLength == header.payload)
      {
      if (header.type == Header.T_TXT_MSG)
         {
         handleTextMessage(buf)
         }
         else if (header.type == Header.T_SOME_OTHER_TYPE})
         {
         handleOtherMessage(buf)
         }
         //etc...
      }
   s.disconnect()
```

Here we receive a header and check it's valid, then receive as many payload bytes as the header indicated. We might then write a separate function to handle each message type.

The `=[]` used in the server-side is fairly uncommon syntax, and means "copy the cells of array B into array A". In this case it copies the received header bytes into the `header` instance directly, because the serial `stream` array is a shallow reference to the memory of the `header` instance; we can then use the header's fields directly instead of querying the received bytes.