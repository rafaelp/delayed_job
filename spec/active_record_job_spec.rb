require 'spec_helper'
require 'delayed/backend/active_record'

describe Delayed::Backend::ActiveRecord::Job do
  after do
    Time.zone = nil
  end

  it_should_behave_like 'a delayed_job backend'

  context "db_time_now" do
    it "should return time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      %w(EST EDT).should include(Delayed::Job.db_time_now.zone)
    end

    it "should return UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      Delayed::Backend::ActiveRecord::Job.db_time_now.zone.should == 'UTC'
    end

    it "should return local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      %w(CST CDT).should include(Delayed::Backend::ActiveRecord::Job.db_time_now.zone)
    end
  end

  describe "after_fork" do
    it "should call reconnect on the connection" do
      ActiveRecord::Base.should_receive(:establish_connection)
      Delayed::Backend::ActiveRecord::Job.after_fork
    end
  end

  context "auto scaling, it" do
    before do
      Delayed::Job.stub!(:auto_scale).and_return(true)
      @manager = mock('sample manager', :qty => 0)
      Delayed::Manager.stub!(:instance).and_return(@manager)
    end

    it "doesn't spin a worker if auto_scale = false" do
      Delayed::Job.stub!(:auto_scale).and_return(false)
      @manager.should_not_receive(:scale_up)
      Delayed::Job.create(:payload_object => SimpleJob.new)
    end

    it "doesn't spin a worker if there's one or more working already" do
      @manager.stub!(:qty).and_return(2)
      @manager.should_not_receive(:scale_up)
      Delayed::Job.create(:payload_object => SimpleJob.new)
    end

    it "spins a worker otherwise" do
      @manager.should_receive(:scale_up)
      Delayed::Job.create(:payload_object => SimpleJob.new)
    end
  end

end
