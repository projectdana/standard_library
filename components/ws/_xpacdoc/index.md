## Web Application Framework

This package contains a simple framework for hosting web-based applications, with support for dynamic server pages, forms, and SSL.

This guide shows how we can write a simple web page hosted on the web application framework.

Start by creating a new directory for your web application, with two sub-directories: `ws` and `swc`.

Inside the `ws` folder create a new file called `Web.dn`, starting with the code:

```
component provides ws.Web {
	
   bool Web:get(char path[], DocStream s)
      {
      if (path == "/")
         {
         s.write("&lt;HTML&gt;")
         s.write("Hello!")
         s.write("&lt;/HTML&gt;")
			
         s.sendResponse()
			
         return true
         }
		
      return false
      }
	
   }
```

Here we've provided an implementation of the `get` function from the `ws.Web` interface, in which we check if the page request is for the root path.

If it is, we send some content back to the client by using the `DocStream` object. We then return `true` to indicate that the given path was served by our web application code (otherwise the web framework will provide its own response to the client, such as a 404 page).

The `DocStream` object also allows us to set/get state in cookies for each request, set response headers, and send raw content in our response.

To compile and run the system, open a command prompt in your project directory, and compile as normal with:

```
dnc .
```

We then run the system using the web framework, with the command:

```
dana ws.core
```

You can now open a web browser, point it at the address `http://localhost:8080`, and you should see your message printed. You can configure the port on which the web framework is listening using the `-p` parameter, e.g. to listen on the HTTP default port 80:

```
dana ws.core -p 80
```

## Static content

By default, the web framework will send *all* URL requests to our web application code, *except* for those which start with `/swc/` (short for "static web content").

If we wanted to return an image as part of our response page, for example, we might use:

```
         s.write("&lt;HTML&gt;")
         s.write("Hello!")
         s.write("&lt;img src = \"/swc/my_pic.png\"/&gt;")
         s.write("&lt;/HTML&gt;")
			
         s.sendResponse()
```

If we then place our image into the `swc/` folder of our project, when the browser requests this image the request will be automatically handled by the web framework without interacting with our web application code. We can do the same for CSS files, JavaScript files, and any other statically-served content.

## Handling forms / POST requests

If you'd like to offer forms for the user to fill in, you can additionally implement the `post()` function of the `ws.Web` interface and use a form parser to decode the form:

```
component provides ws.Web requires ws.forms.Parser:urlencoded formParser {

   bool Web:get(char path[], DocStream s)
      {
      if (path == "/")
         {
         s.write("&lt;HTML&gt;")
         s.write("Hello!")
         s.write("&lt;/HTML&gt;")
			
         s.sendResponse()
			
         return true
         }
         else if (path == "/myform")
         {
         s.write("&lt;form action = \"submit_go\" method = \"post\"&gt; &lt;input type = \"text\" name = \"name\" id = \"forminput\" style = \"width: 30em;\"/&gt; &lt;b&gt;write your name&lt;/b&gt; &lt;p>&lt;input type = \"submit\" value = \"send\" id = \"formbutton\"/&gt;&lt;/p&gt; &lt;/form&gt;")
			
         s.sendResponse()
			
         return true
         }
		
      return false
      }

   bool Web:post(char path[], char contentType[], byte payload[], DocStream s)
      {
      if (path == "/submit_go")
         {
         FormData form = formParser.parse(contentType, payload)
			
         FormField field
			
         field = form.fields.findFirst(FormField.[key], new FormField("name"))
         char name[] = field.value
			
         s.write("Thank you $name!")
         s.sendResponse()
         }
		
      return false
      }
	
   }
```

Here we've provided another page `/myform`, served by our `get()` function, which you can access via `http://localhost:8080/myform`. The HTML for the form includes a directive for the browser to submit the form via a POST request, and to direct that request to the URL `/submit_go`.

When you click "submit" on the form, a HTTP POST request is sent by the browser which is directed to our `post()` function shown above. The `post()` function works in a very similar way to `get()`, except that it has two additional parameters for the content that was uploaded from the form.

We check if the `post()` function is for the path `/submit_go`, as expected for our form, then use a form parser to extract the data from the given content, and respond with a web page that includes the submitted form data.

The above example assumes url-encoded forms, which are typically used when simple name/value pairs are included in the form. For forms which include file upload options you'll need to specify the `enctype=\"multipart/form-data\"` tag on the form's HTML, and then use the `ws.forms.Parser:multipart` form parser instead to parse the details (including any file contents).

## Working with cookies

Some web sites need to maintain state across multiple page requests from the same user, such as the contents of a shopping cart, or a user's signed-in status. One way to maintain this state is by using cookies. When a web application responds to any page request, the application can send a key/value pair as a *cookie* in a response header along with the page content that was requested. When the web browser makes a subsequent request to the same web server, the browser must send this key/value pair back to the server as one of its request headers.

The `DocStream` object allows us to set and get these key/value pairs and so pass state between subsequent requests from the same user. The `setSessionKey()` function is used to set the value of a given key, which is returned to the web browser along with the page response, while the `getSessionKey()` function retrieves the value of a given key that was sent by the browser in a request.

## Using SSL certificates

Finally, you may wish to offer a secure HTTPS version of your web page by using an SSL certificate. To do this, first acquire an SSL certificate from a suitable certificate authority. This will come as (at least) two parts: a certificate (usually a .crt file), and a private key, which you can store as a .txt file. The certificate is assumed to be encoded in base64 PEM format, and the private key in RSA-encoded PKCS1 format.

Place both of these files into your project folder, perhaps in a directory `ssl/`. You can then start the web framework with the additional parameters:

```
dana ws.core -cert ssl/certificate.crt -key ssl/private_key.txt
```

You should now be able to access your site from a web browser using the `https://` prefix as well as `http://`.

You have full access to all of the usual Dana standard library in your web application code, and can also develop other components in your project folder in the usual way (e.g. by creating a `resources/` directory for interfaces and additional corresponding components).

In this example we used the APIs:

- [ws.Web](../../files/ws.Web_Web.html)
- [ws.DocStream](../../files/ws.DocStream_DocStream.html)
- [ws.Forms.Parser](../../files/ws.forms.Parser_Parser.html)
- [data.query.Search](../../files/data.query.Search_Search.html)
