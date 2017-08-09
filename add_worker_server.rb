require 'socket'
require "uri"
require_relative 'mikrotik_communicator'
require 'httparty'
# require "queue"

class AddWorkerServer
  attr_accessor :queue

  def initialize(ip, port, worker_loader, production_server)
    @production_server = production_server
    @server_address = "#{ip}:#{port}"
    @loader = worker_loader
    @server = TCPServer.new(ip, port)
    @queue = Queue.new
  end

  def serve
    loop do
      headers = []
      socket = @server.accept
      peer_info = socket.peeraddr
      request = socket.gets
      while request != "" do
        headers << request
        request = socket.gets.strip
      end
      if !headers[0].include?("firstName")
        response_text = get_connection_html
      else
        splitted = headers[0].split(/=|&| /)
        p splitted
        first_name = splitted[2]
        last_name = splitted[4]
        response_text = show_response_html
        puts first_name
        puts last_name
        p peer_info
        create_worker(first_name, last_name, peer_info[3])
      end
      response_headers = "HTTP/1.1 200 OK\r\n" +
          "Content-Type: text/html\r\n" +
          "Content-Length: #{response_text.bytesize}\r\n" +
          "Connection: close\r\n"
      socket.print(response_headers)
      socket.print("\r\n")
      socket.print(response_text)
      @queue.push([first_name, last_name, peer_info[3]]) unless first_name == nil
    end
  end

  def create_worker(first_name, last_name, ipaddr)
    mac_addr = MikrotikCommunicator.getMac(ipaddr)
    puts "#{first_name} #{last_name} #{ipaddr}"
    puts "sednding to #{@production_server}"
    HTTParty.post("http://#{@production_server}/api/workers", body: {
                                                         :name => "#{first_name} #{last_name}",
                                                         :mac => mac_addr,
                                                     })
    @loader.reload_workers
  end

  def show_response_html
    ' <!DOCTYPE html>
              <html lang=\'en\'>
    <head>
    <meta charset="UTF-8" />
    <title>
        HTML Document Structure
    </title>
    <link rel="stylesheet" type="text/css" href="style.css" />
</head>
<body>

<form>
  <h1>Employer Log in</h1>
  <div class="inset">
  <p>
    <label for="firstName">First Name</label>
    <input type="text" name="firstName" id="firstName">
  </p>
  <p>
    <label for="lastName">Last Name</label>
    <input type="text" name="lastName" id="lastName">
  </p>
  </div>
  <p class="p-container">
    <input type="submit" name="go" id="go" value="Log in">
  </p>
<p>
  <h3>Device successfully added.</h3>
</p>
</form>

</body>
<style type="text/css">
* { box-sizing: border-box; padding:0; margin: 0; }

body {
	font-family: "HelveticaNeue-Light","Helvetica Neue Light","Helvetica Neue",Helvetica,Arial,"Lucida Grande",sans-serif;
  color:white;
  font-size:12px;
  background:#333 ;
}

form {
 	background:#111;
  width:300px;
  margin:30px auto;
  border-radius:0.4em;
  border:1px solid #191919;
  overflow:hidden;
  position:relative;
  box-shadow: 0 5px 10px 5px rgba(0,0,0,0.2);
}

form:after {
  content:"";
  display:block;
  position:absolute;
  height:1px;
  width:100px;
  left:20%;
  background:linear-gradient(left, #111, #444, #b6b6b8, #444, #111);
  top:0;
}

form:before {
 	content:"";
  display:block;
  position:absolute;
  width:8px;
  height:5px;
  border-radius:50%;
  left:34%;
  top:-7px;
  box-shadow: 0 0 6px 4px #fff;
}

.inset {
 	padding:20px;
  border-top:1px solid #19191a;
}

form h1 {
  font-size:18px;
  text-shadow:0 1px 0 black;
  text-align:center;
  padding:15px 0;
  border-bottom:1px solid rgba(0,0,0,1);
  position:relative;
}

form h1:after {
 	content:"";
  display:block;
  width:250px;
  height:100px;
  position:absolute;
  top:0;
  left:50px;
  pointer-events:none;
  transform:rotate(70deg);
  -webkit-transform: rotate(70deg);
  background:linear-gradient(50deg, rgba(255,255,255,0.15), rgba(0,0,0,0));
   background-image: -webkit-linear-gradient(50deg, rgba(255,255,255,0.05), rgba(0,0,0,0)); /* For Safari */

}

label {
 	color:#666;
  display:block;
  padding-bottom:9px;
}

input[type=text],
input[type=password] {
 	width:100%;
  padding:8px 5px;

  border:1px solid #222;
  box-shadow:
    0 1px 0 rgba(255,255,255,0.1);
  border-radius:0.3em;
  margin-bottom:20px;
}

label[for=remember]{
 	color:white;
  display:inline-block;
  padding-bottom:0;
  padding-top:5px;
}

input[type=checkbox] {
 	display:inline-block;
  vertical-align:top;
}

.p-container {
 	padding:0 20px 20px 20px;
}

.p-container:after {
 	clear:both;
  display:table;
  content:"";
}

.p-container span {
  display:block;
  float:left;
  color:#0d93ff;
  padding-top:8px;
}

input[type=submit] {
 	padding:5px 20px;
  border:1px solid rgba(0,0,0,0.4);
  text-shadow:0 -1px 0 rgba(0,0,0,0.4);
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.3),
    inset 0 10px 10px rgba(255,255,255,0.1);
  border-radius:0.3em;
  background:#0184ff;
  color:white;
  float:right;
  font-weight:bold;
  cursor:pointer;
  font-size:13px;
}

input[type=submit]:hover {
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.3),
    inset 0 -10px 10px rgba(255,255,255,0.1);
}

input[type=text]:hover,
input[type=password]:hover,
label:hover ~ input[type=text],
label:hover ~ input[type=password] {

}
</style>

</html>
'
  end

  def get_connection_html
    ' <!DOCTYPE html>
              <html lang=\'en\'>
    <head>
    <meta charset="UTF-8" />
    <title>
        HTML Document Structure
    </title>
    <link rel="stylesheet" type="text/css" href="style.css" />
</head>
<body>

<form>
  <h1>Employer Log in</h1>
  <div class="inset">
  <p>
    <label for="firstName">First Name</label>
    <input type="text" name="firstName" id="firstName">
  </p>
  <p>
    <label for="lastName">Last Name</label>
    <input type="text" name="lastName" id="lastName">
  </p>
  </div>
  <p class="p-container">
    <input type="submit" name="go" id="go" value="Log in">
  </p>
</form>

</body>
<style type="text/css">
* { box-sizing: border-box; padding:0; margin: 0; }

body {
	font-family: "HelveticaNeue-Light","Helvetica Neue Light","Helvetica Neue",Helvetica,Arial,"Lucida Grande",sans-serif;
  color:white;
  font-size:12px;
  background:#333 ;
}

form {
 	background:#111;
  width:300px;
  margin:30px auto;
  border-radius:0.4em;
  border:1px solid #191919;
  overflow:hidden;
  position:relative;
  box-shadow: 0 5px 10px 5px rgba(0,0,0,0.2);
}

form:after {
  content:"";
  display:block;
  position:absolute;
  height:1px;
  width:100px;
  left:20%;
  background:linear-gradient(left, #111, #444, #b6b6b8, #444, #111);
  top:0;
}

form:before {
 	content:"";
  display:block;
  position:absolute;
  width:8px;
  height:5px;
  border-radius:50%;
  left:34%;
  top:-7px;
  box-shadow: 0 0 6px 4px #fff;
}

.inset {
 	padding:20px;
  border-top:1px solid #19191a;
}

form h1 {
  font-size:18px;
  text-shadow:0 1px 0 black;
  text-align:center;
  padding:15px 0;
  border-bottom:1px solid rgba(0,0,0,1);
  position:relative;
}

form h1:after {
 	content:"";
  display:block;
  width:250px;
  height:100px;
  position:absolute;
  top:0;
  left:50px;
  pointer-events:none;
  transform:rotate(70deg);
  -webkit-transform: rotate(70deg);
  background:linear-gradient(50deg, rgba(255,255,255,0.15), rgba(0,0,0,0));
   background-image: -webkit-linear-gradient(50deg, rgba(255,255,255,0.05), rgba(0,0,0,0)); /* For Safari */

}

label {
 	color:#666;
  display:block;
  padding-bottom:9px;
}

input[type=text],
input[type=password] {
 	width:100%;
  padding:8px 5px;
  border:1px solid #222;
  box-shadow:
    0 1px 0 rgba(255,255,255,0.1);
  border-radius:0.3em;
  margin-bottom:20px;
}

label[for=remember]{
 	color:white;
  display:inline-block;
  padding-bottom:0;
  padding-top:5px;
}

input[type=checkbox] {
 	display:inline-block;
  vertical-align:top;
}

.p-container {
 	padding:0 20px 20px 20px;
}

.p-container:after {
 	clear:both;
  display:table;
  content:"";
}

.p-container span {
  display:block;
  float:left;
  color:#0d93ff;
  padding-top:8px;
}

input[type=submit] {
 	padding:5px 20px;
  border:1px solid rgba(0,0,0,0.4);
  text-shadow:0 -1px 0 rgba(0,0,0,0.4);
  box-shadow:
    inset 0 1px 0 rgba(255,255,255,0.3),
    inset 0 10px 10px rgba(255,255,255,0.1);
  border-radius:0.3em;
  background:#0184ff;
  color:white;
  float:right;
  font-weight:bold;
  cursor:pointer;
  font-size:13px;
}

input[type=text]:hover,
input[type=password]:hover,
label:hover ~ input[type=text],
label:hover ~ input[type=password] {

}
</style>

</html>
'
  end

end

#
# server = AddWorkerServer.new("10.0.0.196",8080, nil, "10.0.0.196:3000")
# server.serve
# loop do
#   p server.queue.pop
# end