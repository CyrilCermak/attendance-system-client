require 'test/unit'
require '../mikrotik_communicator'

class MikrotikTesting < Test::Unit::TestCase

  def setup
    @mc = MikrotikCommunicator.new(load_workers)
    @workers = load_workers.map { |mac, w| w }
  end

  def load_workers
    workers = {}
    file = "/Users/cyril/Programming/RubymineProjects/PiServer/workers.txt"
    if File.exist?(file)
      File.open(file, "r") do |file|
        while (line = file.gets) != nil
          l = line.strip.split(",")
          workers[l[1]] = Worker.new(l[1], l[0], l[2], 0, l[3])
        end
      end
      workers
    else
      puts "Missing workers.txt file."
      exit(1)
    end
  end

  def test_worker_comparison
    w1 = Worker.new("20:c9:d0:b7:28:b5", "192.168.1.2", "Cyrils-MacBook-Pro", 0, 1)
    w2 = Worker.new("20:c9:d0:b7:28:b5", "192.168.1.2", "Cyrils-MacBook-Pro", 0, 2)
    w3 = Worker.new("20:c9:d0:b7:28:b9", "192.168.1.3", "Cyrils-MacBook-Pro", 0, 3)
    assert_equal(w1 == w2, true)
    assert_equal(w1==w3, false)
  end

  def test_new_online
    now_active_workers = [
        Worker.new("20:c9:d0:b7:28:b5", "192.168.1.2", "Cyrils-MacBook-Pro", 0, 1),
        Worker.new("34:C0:59:93:8C:9A", "192.168.1.4", "Cyril's iPad", 0, 2)]
    @mc.active[now_active_workers[0].mac] = now_active_workers[0]
    assert_equal(now_active_workers[1], @mc.workers_to_sets(now_active_workers).first)
    assert_equal(now_active_workers.length, @mc.active.size)
    assert_equal((@workers.length - @mc.active.length), @mc.not_active.length)
  end

  def test_new_offline
    @workers[0].state = 1
    @workers[1].state = 1
    @mc.active[@workers[0].mac] = @workers[0]
    @mc.active[@workers[1].mac] = @workers[1]
    now_active_workers = [@workers[0]]
    assert_equal(@workers[1], @mc.workers_to_sets(now_active_workers).first)
    assert_equal(now_active_workers.first, @mc.active[@workers[0].mac])
    assert_equal((@workers.length - now_active_workers.length), @mc.not_active.length)
  end

  def test_new_workers_online
    @workers[0].state = 1
    @workers[1].state = 1
    @mc.active[@workers[0].mac] = @workers[0]
    @mc.active[@workers[1].mac] = @workers[1]
    active = @mc.active.map { |mac, w| w }
    new_online = @workers - active
    assert_equal(@workers.sort!, @mc.workers_to_sets(new_online).sort!)
    assert_equal(new_online.length, @mc.active.size)
  end

  def test_all_out
    @workers[0].state = 1
    @workers[1].state = 1
    @mc.active[@workers[0].mac] = @workers[0]
    @mc.active[@workers[1].mac] = @workers[1]
    new_online = []
    @mc.workers_to_sets(new_online)
    assert_equal({}, @mc.active)
    assert_equal(@workers.size, @mc.not_active.size)
  end

  def test_all_in
    new_online = @workers
    assert_equal(@workers, @mc.workers_to_sets(@workers))
    assert_equal(@mc.active.length, @workers.length)
    assert_equal({}, @mc.not_active)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    @mc.active = {}
  end

end