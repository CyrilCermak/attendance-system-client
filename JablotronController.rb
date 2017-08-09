require 'rubyserial'
class JablotronController

#Uncomment for using Jablotron device
#  SERIALPORT = Serial.new '/dev/ttyUSB0', 9600

  def initialize

  end

  def set(command1, command2='')
    SERIALPORT.write("1*1234 SET #{command1} #{command2}")
  end

  def unset(command, command2='')
    SERIALPORT.write("1*1234 UNSET #{command} #{command2}")
  end

  def pgon(command, command2='')
    SERIALPORT.write("1*1234 PGON #{command} #{command2}")
  end

  def pgoff(command, command2='')
    SERIALPORT.write("1*1234 PGOFF #{command} #{command2}")
  end
end

j = JablotronController.new