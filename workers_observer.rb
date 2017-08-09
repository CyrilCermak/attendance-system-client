require 'httparty'
require 'twilio-ruby'

class WorkersObserver
  ACCOUNT_SID = 'AC397376d1c8bcadae2083cb6d0594ad3f'
  AUTH_TOKEN = 'f32b73dd3c5809c87dfd938ed6ff7905'
  attr_accessor :sent_before

  def initialize(server)
    @server = server
    @sent_before = false
  end

  def notify(changed_workers)
    puts "changed workers => #{changed_workers}#"
    changed_workers.each do |w|
      # result = HTTParty.patch("http://unicorns2.eu-gb.mybluemix.net/api/workers/#{w.id}", body: {:ip => w.ip, :mac => w.mac, state: w.state})
      begin
        result = HTTParty.patch("http://#{@server}/api/workers/#{w.id}", body: {:ip => w.ip, :mac => w.mac, state: w.state})
      rescue
        puts "Server is down!"
        exit 1
      end
    end
  end

  def notify_by_sms(active_users)
    if active_users.empty? && !@sent_before
      puts "SMS SENT----------------------------->"
      # @client = Twilio::REST::Client.new ACCOUNT_SID, AUTH_TOKEN
      # @client.account.sms.messages.create(
      #     :from => "+15102963357}",
      #     :to => "+420776208919",
      #     :body => "Test Message from testing"
      # )
      @sent_before = true
    end
  end

end
