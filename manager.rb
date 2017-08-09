require 'httparty'
require_relative 'mikrotik_communicator'
require_relative 'workers_observer'
require_relative 'locker_observer'
require_relative 'add_worker_server'

class Manager

  def initialize(production_server,add_worker_ip)
    @production_server = production_server
    @add_worker_ip = add_worker_ip
    @worker_observer = WorkersObserver.new(production_server)
    @locker_observer = LockerObserver.new
    @mc = MikrotikCommunicator.new(load_workers_server)
    @locked = false
  end

  def get_active
    @mc.active
  end

  def reload_workers
    @mc = MikrotikCommunicator.new(load_workers_server)
  end

  def run
    #notifying objects about current state every 60 seconds
    start_add_worker_server
    while true
      notify_worker_observers(get_changes) #gets workers that came or leave the place.
      if @mc.active == {}
        notify_locker_observer_lock
      else
        notify_locker_observer_unlock
      end
      sleep 10
    end
  end

  private

  def start_add_worker_server
    Thread.new do
      server = AddWorkerServer.new(@add_worker_ip, 8080, self,)
      server.serve
      loop do
        p server.queue.pop
      end
    end
  end

  def get_changes
    #fetch connected devices from router
    @mc.connect
  end

  def load_workers_server
    #loading workers from server
    puts "Loading workers from server."
    begin
      puts @production_server
      workers = {}
      loaded_workers = HTTParty.get("http://#{@production_server}/api/workers/")
      puts workers
      loaded_workers.parsed_response["workers"].each do |w|
        workers[w["mac"]] = Worker.new(w["mac"].upcase, w["ip"], w["host_name"], w["state"], w["id"])
      end
    rescue
      ping = system("ping -c 1 www.google.com >/dev/null")
      if $? == 0
        puts "Cannot connect to server, check if the server is setup properly."
      else
        puts "Your internet seems to be down."
      end
      exit(1)
    end
    workers
  end

  def notify_worker_observers(changed_users)
    @worker_observer.notify(changed_users)
    @worker_observer.sent_before = false if @mc.active != {}
    @worker_observer.notify_by_sms(@mc.active)
  end

  def notify_locker_observer_lock
  #  @locker_observer.notify_lock
  end

  def notify_locker_observer_unlock
  #   @locker_observer.notify_unlock
  end

end
