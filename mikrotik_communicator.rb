require 'mtik'
require 'set'

class MikrotikCommunicator
  attr_accessor :active, :not_active, :to_change

  def initialize(loaded_workers)
    @loaded_workers = {}
    loaded_workers.each { |mac, w| @loaded_workers[mac] = w }
    @not_active = loaded_workers
    @active = {}
    @to_change = []
    begin
      @connection = MTik::Connection.new(:host => "10.0.0.1",
                                         :user => "admin",
                                         :pass => "master4mac",
                                         :conn_timeout => 10)
    rescue
      puts "Connection to Mikrotik timed out! Program will exit."
      exit 1
    end
  end

  def connect
    begin
      return workers_to_sets(get_response(@connection))
    rescue Errno::ETIMEDOUT
      puts "Cannot connect to the router."
    end
  end

  def get_response(connection)
    reply_count = 0
    reply_limit = 10
    active_workers = []
    connection.get_reply_each("/ip/dhcp-server/lease/print") do |request_object, reply_sentence|
      if reply_sentence.key?('!re') # Pay attention to reply sentences
        p reply_sentence
        name = reply_sentence["host-name"]
        ip = reply_sentence["address"]
        mac = reply_sentence["mac-address"].upcase
        if @loaded_workers.has_key?(mac)
          w = @loaded_workers[mac]
          w.state = 1
          w.ip = ip
          w.host_name = name
          active_workers << w
        end
        # Increment the reply counter:
        reply_count += 1
        # If we've reached our reply goal, cancel:
        if reply_count >= reply_limit
          # Cancel this command request:
          request_object.cancel
        end
      end
    end
    active_workers
  end

  def workers_to_sets(active_workers)
    @to_change = []
    puts "active_workers #{active_workers}"
    puts "active #{@active}"
    @active.map { |mac, w| w.state = 0 }
    active_workers.each do |worker|
      if @active.has_key?(worker.mac)
        @active[worker.mac].state = 1
      else
        worker.state = 1
        @active[worker.mac] = worker
        @to_change << worker
      end
    end
    @active.each do |mac, worker|
      if worker.state == 0
        @to_change << worker
        @not_active[mac] = worker
      end
    end
    @active.delete_if { |mac, w| w.state == 0 }
    @not_active.delete_if { |mac, w| @active.has_key?(mac) }
    @to_change
  end

  #Get Mac address from Mikrotik
  def MikrotikCommunicator.getMac(ip_address)
    connection = MTik::Connection.new(:host => "10.0.0.1",
                                      :user => "admin",
                                      :pass => "master4mac",
                                      :conn_timeout => 10)
    mac = nil
    connection.get_reply_each("/ip/dhcp-server/lease/print") do |object, sentecnce|
      if sentecnce.has_key?("!re") && sentecnce["address"] == ip_address
        mac = sentecnce["mac-address"]
      end
    end
    puts "New Worker MAC => " + mac
    return mac
  end

end

class Worker
  attr_accessor :mac, :ip, :host_name, :state, :id
  include Comparable

  def initialize(mac, ip, host_name, state, id)
    @mac, @ip, @host_name, @state, @id = mac, ip, host_name, state, id
  end

  def <=>(other)
    result = self.mac <=> other.mac
    return result if result != 0
    result = self.ip <=> other.ip
  end

end

