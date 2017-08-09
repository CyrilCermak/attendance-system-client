require 'rubygems' # not necessary with ruby 1.9 but included for completeness 
require 'twilio-ruby'

# put your own credentials here 
account_sid = 'AC397376d1c8bcadae2083cb6d0594ad3f'
auth_token = 'f32b73dd3c5809c87dfd938ed6ff7905'

# set up a client to talk to the Twilio REST API 
@client = Twilio::REST::Client.new account_sid, auth_token

@client.account.sms.messages.create(
    :from => "+15102963357}",
    :to => "+420776208919",
    :body => "Test Message from testing"
)

