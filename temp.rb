require 'socket'
require "uri"
require_relative 'mikrotik_communicator'
require 'httparty'
# require "queue"

class AddWorkerServer
  attr_accessor :queue

  def initialize(port, worker_loader)
    @loader = worker_loader
    @server = TCPServer.new("192.168.1.102", port)
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
        response_text = '

       form class="form-container">
        <div class="form-title"><h2>Sign up</h2></div>
        <div class="form-title">Name</div>
        <input class="form-field" type="text" name="firstname" /><br />
        <div class="form-title">Email</div>
        <input class="form-field" type="text" name="email" /><br />
        <div class="submit-container">
        <input class="submit-button" type="submit" value="Submit" />
        </div>
       </form>'
      else
        splitted = headers[0].split(/=|&| /)
        first_name = URI.unescape(splitted[splitted.length() - 4])
        last_name = URI.unescape(splitted[splitted.length() - 2])
        response_text = '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>title</title></head><body>Zařízení bylo úspěšně přidáno</body></html>'
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
    HTTParty.post("http://localhost:3000/api/workers", body: {
                                                         :name => "#{first_name} #{last_name}",
                                                         :mac => mac_addr,
                                                     })
    @loader.reload_workers
  end

end

#
server = AddWorkerServer.new(8080, nil)
server.serve
loop do
  p server.queue.pop
end