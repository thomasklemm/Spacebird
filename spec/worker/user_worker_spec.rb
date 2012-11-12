# UserWorker Specs
require 'spec_helper'

describe UserWorker do
  let(:worker) { @worker ||= UserWorker.new }

  describe '.perform' do
    it 'updates records with a valid screen name' do
    end
  end

  describe ".normalize_ids" do
    it "handles single integers" do
      worker.normalize_ids(267884096).should eq([267884096])
    end

    it "handles integers in array" do
      worker.normalize_ids([267884096, 123]).should eq([267884096, 123])
      worker.normalize_ids(267884096, 123).should eq([267884096, 123])
    end

    it "removes duplicates from array" do
      worker.normalize_ids([267884096, 267884096, 123]).should eq([267884096, 123])
    end

    it "handles single string" do
      worker.normalize_ids('thomasjklemm').should eq(['thomasjklemm'])
    end

    it "handles strings in array" do
      worker.normalize_ids('thomasjklemm', 'dhh').should eq(['thomasjklemm', 'dhh'])
      worker.normalize_ids(['thomasjklemm', 'dhh']).should eq(['thomasjklemm', 'dhh'])
    end
  end

  describe ".retrieve_twitter_users" do
    context "for single user" do
      it "retrieves user instance for valid screen_name" do
        twitter_users = worker.retrieve_twitter_users(['thomasjklemm'])
        twitter_users.length.should eq(1)
        twitter_users.first.id.should eq(267884096)
      end

      it "retrieves user instance for valid twitter_id" do
        twitter_users = worker.retrieve_twitter_users([267884096])
        twitter_users.length.should eq(1)
        twitter_users.first.screen_name.should eq('thomasjklemm')
      end

      it "returns nil for invalid user" do
        twitter_users = worker.retrieve_twitter_users([267884096232])
        twitter_users.should be_nil
      end
    end

    context "for multiple users" do
      it "retrieves user instances for valid screen_names" do
        twitter_users = worker.retrieve_twitter_users(['thomasjklemm', 'dhh'])
        twitter_users.length.should eq(2)
        twitter_users.map(&:id).should include(267884096) # thomasjklemm
        twitter_users.map(&:id).should include(14561327)  # dhh
      end

      it "retrieves user instances for valid twitter_ids" do
        twitter_users = worker.retrieve_twitter_users([267884096, 14561327])
        twitter_users.length.should eq(2)
        twitter_users.map(&:screen_name).should include('thomasjklemm') # thomasjklemm
        twitter_users.map(&:screen_name).should include('dhh')  # dhh
      end

      it "retrieves user instances for valid twitter_ids and skips invalid users" do
        twitter_users = worker.retrieve_twitter_users([267884096, 14561327, 8922234212])
        twitter_users.length.should eq(2)
      end

      it "returns nil for faulty twitter_ids" do
        twitter_users = worker.retrieve_twitter_users([8922234212, 981729873])
        twitter_users.should be_nil
      end

    end
  end

end

