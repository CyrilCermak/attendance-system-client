require_relative 'JablotronController'

class LockerObserver

  def initialize
    @state = :unlocked
    @jblcontroller = JablotronController.new
  end

  def notify_lock
    return if @state == :locked
    #lock building
    @jblcontroller.pgon("1", "2")
    @jblcontroller.set("1")
    @state = :locked
  end

  def notify_unlock
    return if @state == :unlocked
    @jblcontroller.pgoff("1", "2")
    @jblcontroller.unset("1")
    @state = :unlocked
  end

end