require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GitolitePublicKey do

  SSH_KEY = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpqFJzsx3wTi3t3X/eOizU6rdtNQoqg5uSjL89F+Ojjm2/sah3ouzx+3E461FDYaoJL58Qs9eRhL+ev0BY7khYXph8nIVDzNEjhLqjevX+YhpaW9Ll7V807CwAyvMNm08aup/NrrlI/jO+At348/ivJrfO7ClcPhq4+Id9RZfvbrKaitGOURD7q6Bd7xjUjELUN8wmYxu5zvx/2n/5woVdBUMXamTPxOY5y6DxTNJ+EYzrCr+bNb7459rWUvBHUQGI2fXDGmFpGiv6ShKRhRtwob1JHI8QC9OtxonrIUesa2dW6RFneUaM7tfRfffC704Uo7yuSswb7YK+p1A9QIt5 nicolas@tchoum'

  before(:all) do
    users = FactoryGirl.create_list(:user, 2)
    @user1 = users[0]
    @user2 = users[1]

    @ssh_key = FactoryGirl.create(:gitolite_public_key, :user_id => @user1.id)
  end

  subject { @ssh_key }

  it { should be_valid }

  it { should respond_to(:user) }
  it { should respond_to(:key_type) }
  it { should respond_to(:title) }
  it { should respond_to(:identifier) }
  it { should respond_to(:fingerprint) }
  it { should respond_to(:key) }
  it { should respond_to(:delete_when_unused) }

  it "can render as string" do
    expect(@ssh_key.to_s).to eq "test-key"
  end

  it "has a title" do
    expect(@ssh_key.title).to eq "test-key"
  end

  it "has an identifier" do
    expect(@ssh_key.identifier).to eq "redmine_user1_1@redmine_test_key"
  end

  it "has a fingerprint" do
    expect(@ssh_key.fingerprint).to eq "af:af:da:41:5f:7e:6b:dd:e3:d9:bc:78:a6:8a:fc:be"
  end

  it "is a user key" do
    expect(@ssh_key.user_key?).to be true
  end

  it "is not a deploy key" do
    expect(@ssh_key.deploy_key?).to be false
  end

  it "must be deleted when unused" do
    expect(@ssh_key.delete_when_unused?).to be true
  end

  # Test data integrity
  it "should not truncate key" do
    expect(@ssh_key.key.length).to be == SSH_KEY.length
  end


  ## Test presence validation
  describe "when user_id is not present" do
    before { @ssh_key.user_id = "" }
    it { should_not be_valid }
  end

  describe "when title is not present" do
    before { @ssh_key.title = " " }
    it { should_not be_valid }
  end

  describe "when key is not present" do
    before { @ssh_key.key = " " }
    it { should_not be_valid }
  end

  describe "when identifier is not present" do
    before { @ssh_key.identifier = " " }
    it { should_not be_valid }
  end

  describe "when fingerprint is not present" do
    before { @ssh_key.fingerprint = " " }
    it { should_not be_valid }
  end

  describe "when key_type is not present" do
    before { @ssh_key.key_type = " " }
    it { should_not be_valid }
  end

  describe "when key_type is out of range" do
    before { @ssh_key.key_type = 2 }
    it { should_not be_valid }
  end


  ## Test length validation
  describe "when title is too long" do
    before { @ssh_key.title = "a" * 256 }
    it { should_not be_valid }
  end


  ## Test format validation
  describe "when title format is invalid" do
    invalid_format = [
      'toto@toto',
      'ma_clé'
    ]
    invalid_format.each do |format|
      before { @ssh_key.title = format }
      it { should_not be_valid }
    end
  end


  ## Test change validation
  describe "test change validation" do

    describe "when delete_when_unused is false" do
      before { @ssh_key.delete_when_unused = false }
      it "should not be deleted when unused" do
        expect(@ssh_key.delete_when_unused?).to be false
      end
    end

    describe "when identifier is changed" do
      before do
        @ssh_key.identifier = " "
      end

      it { should_not be_valid }
    end

    describe "when key is changed" do
      before do
        @ssh_key.key = " "
      end

      it { should_not be_valid }
    end

    describe "when user_id is changed" do
      before do
        @ssh_key.user_id = @user2.id
      end

      it { should_not be_valid }
    end

    describe "when key_type is changed" do
      before do
        @ssh_key.key_type = 1
      end

      it { should_not be_valid }
    end
  end


  ## Test uniqueness validation
  describe "when title is already taken" do
    before do
      @ssh_key_with_same_title = FactoryGirl.build(:gitolite_public_key, :user_id => @user1.id)
      @ssh_key_with_same_title.save
    end

    subject { @ssh_key_with_same_title }

    it { should_not be_valid }
  end


  describe "when key is already taken" do
    before do
      @ssh_key_with_same_key = FactoryGirl.build(:gitolite_public_key, :user_id => @user1.id, :title => 'foo', :key => SSH_KEY)
      @ssh_key_with_same_key.save
    end

    subject { @ssh_key_with_same_key }

    it { should_not be_valid }
  end


  describe "when key is already taken by current user" do
    before do
      User.current = @user1
      @ssh_key_with_same_key = FactoryGirl.build(:gitolite_public_key, :user_id => @user1.id, :title => 'foo', :key => SSH_KEY)
      @ssh_key_with_same_key.save
    end

    subject { @ssh_key_with_same_key }

    it { should_not be_valid }
  end


  describe "when key is already taken by other user" do
    before do
      @user2.admin = true
      User.current = @user2
      @ssh_key_with_same_key = FactoryGirl.build(:gitolite_public_key, :user_id => @user1.id, :title => 'foo', :key => SSH_KEY)
      @ssh_key_with_same_key.save
    end

    subject { @ssh_key_with_same_key }

    it { should_not be_valid }
  end


  describe "when many keys are saved" do
    ACTIVE_SSH_KEY_1 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCz0pLXcQWS4gLUimUSLwDOvEmQF8l8EKoj0LjxOyM3y2dpLsn0aiqS0ecA0G/ROomaawop8EZGFetoJKJM468OZlx2aKoQemzvFIq0Mn1ZhcrlA1alAsDYqzZI8iHO4JIS3YbeLLkVGAlYA+bmA5enXN9mGhC9cgoMC79EZiLD9XvOw4iXDjqXaCzFZHU1shMWwaJfpyxBm+Mxs2vtZzwETDqeu9rohNMl60dODf6+JoXYiahP+B+P2iKlL7ORb1YsAH/4ZMsVgRckj8snb4uc3XgwLRNNw+oB78ApZGr0j3Zc32U9rpmulbHIroWO07OV4Xsplnu8lhGvfodA2gjb nicolas@tchoum'
    ACTIVE_SSH_KEY_2 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5+JfM82k03J98GWL6ghJ4TYM8DbvDnVh1s1rUDNlM/1U5rwbgXHOR4xV3lulgYEYRtYeMoL3rt4ZpEyXWkOreOVsUlkW66SZJR5aGVTNJOLX7HruEDqj7RWlt0u0MH6DgBVAJimQrxYN50jYD4XnDUjb/qv55EhPvbJ3jcAb3zuyRXMKZYGNVzVFLUagbvVaOwR23csWSLDTsAEI9JzaxMKvCNRwk3jFepiCovXbw+g0iyvJdp0+AJpC57ZupyxHeX9J2oz7im2UaHHqLa2qUZL6c4PNV/D2p0Bts4Tcnn3OFPL90RF/ao0tjiUFxM3ti8pRHOqRcZHcOgIhKiaLX nicolas@tchoum'
    ACTIVE_SSH_KEY_3 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/pSRh11xbadAh24fQlc0i0dneG0lI+DCkng+bVmumgRvfD0w79vcJ2U1qir2ChjpNvi2n96HUGIEGNV60/VG05JY70mEb//YVBmQ3w0QPO7toEWNms9SQlwR0PN6tarATumFik4MI+8M23P6W8O8OYwsnMmYwaiEU5hDopH88x74MQKjPiRSrhMkGiThMZhLVK6j8yfNPoj9yUxPBWc7zsMCC2uAOfR5Fg6hl2TKGxTi0vecTh1csDcO2agXx42RRiZeIQbv9j0IJjVL8KhXvbndVnJRjGGbxQFAedicw8OrPH7jz6NimmaTooqU9SwaPInK/x3omd297/zzcQm3p nicolas@tchoum'
    ACTIVE_SSH_KEY_4 = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCScLGus1vrZ9OyzOj3TtYa+IHUp5V+2hwcMW7pphGIAPRi5Pe6GwSbSV5GnanerOH9ucmEREaCIdGOzO2zVI35e3RD6wTeW28Ck7JN1r2LSgSvXGvxGyzu0H4Abf66Kajt+lN0/71tbFtoTaJTGSYE3W0rNU6OQBvHf1o4wIyBEFm3cu+e2OrmW/nVIqk8hCN2cU/0OutOWT+vaRLbIU3VQmHftqa4NVxdc4OG48vpZxlJwKexqAHj8Ok/sn3k4CIo8zR0vRaeGPqAmOpm84uEfRWoA71NNS4tIhENlikuD5SJIdyXE9d8CwGTth4jP9/BNT0y4C8cGYljjUWkx3v nicolas@tchoum'

    before do
      active_ssh_key_1 = FactoryGirl.create(:gitolite_public_key, :user_id => @user1.id, :title => 'active1', key: ACTIVE_SSH_KEY_1, :key_type => 1)
      active_ssh_key_2 = FactoryGirl.create(:gitolite_public_key, :user_id => @user1.id, :title => 'active2', key: ACTIVE_SSH_KEY_2, :key_type => 1)
      active_ssh_key_3 = FactoryGirl.create(:gitolite_public_key, :user_id => @user2.id, :title => 'active3', key: ACTIVE_SSH_KEY_3)
      active_ssh_key_4 = FactoryGirl.create(:gitolite_public_key, :user_id => @user2.id, :title => 'active4', key: ACTIVE_SSH_KEY_4)
    end

    it "should have 5 keys" do
      expect(GitolitePublicKey.all.length).to be == 5
    end

    it "should have 3 user keys" do
      expect(GitolitePublicKey.user_key.length).to be == 3
    end

    it "should have 2 deploy keys" do
      expect(GitolitePublicKey.deploy_key.length).to be == 2
    end

    it "user1 should have 3 keys" do
      expect(GitolitePublicKey.by_user(@user1).length).to be == 3
    end

    it "user2 should have 2 keys" do
      expect(GitolitePublicKey.by_user(@user2).length).to be == 2
    end
  end


  ## Test format validation
  describe "when ssh key is valid" do
    ssh_keys = [
      'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/Ec2gummukPxlpPHZ7K96iBdG5n8v0PJEDvTVZRRFlS0QYa407gj9HuMrPjwEfVHqy+3KZmvKLWQBsSlf0Fn+eAPgnoqwVfZaJnfgkSxJiAzRraKQZX1m2wx2SVMfjw7/1j59zV60UhFiwEQ3Eqlg3xjQmjvrwDM+SoshrWB+TeqwO/K+QEP1ZbURYoCxc92GrLYWKixsAov/zr0loXqul9fydZcWwJE3H/BWC7PTtn4jfjG9+9F+SZ0OMwQvSGKhVlj3GBDtaDBnsuoHGh/CA2W240nwpQysG2BJ5DWXu6vKbjNn6uV91wXeKDEDpuWqv5Vi2XAxGTWKc5lF0IJ5 nicolas@tchoum',
      'ssh-dss AAAAB3NzaC1kc3MAAACBAKscxrmjRgXtb0ZUaaBUteBtF2cI0vStnni9KVQd94L8qqxvKLbDl5JTKjUvG2s7rD4sVRzBoTkuDGb7OZLf56wJyF3k+k8uNRJzvH/CZbkKM2hjuRVYVort1EwcH7JiEQr7bCLe7MRaltuo/M1vhapwy7fhKxAo9YoYVWiGoFTVAAAAFQDPywT8yFDahFvxtt/95Q9Emq8R7QAAAIBHYnvt3hT9NYy+nOuZG+cQTz0hnVzUIWuj0XF2iyx52s2eSmF0HxIsZ0D9g2A0L1Xr/vlkWBMq/zJZJgJw2Ifys8L47HzjhL8K0Skdm23Z6rQR9hlOEZ5Rcank98U6VRYPWpYk7OLdRDruwXb+Ms5YhIztxsGO3YfRBdSBrW4DMAAAAIAJmmwivw3XoFP6C97LB+tJAjWRYJHpiDwOWNDKu0dZewUzUAo40NuHNgKJS2nsxW0sphaeMtf70IbvDsFQG45I+G2dlt+s19t4YCbVcz7xrw7LceEz+f0UR2/Z+LIK2GPIIoyymOq/kIIxni3xgKDl4mvvt45TTsQzs0zhkmEy/g== nicolas@tchoum',
      'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLIcYw8NbJc28tDsC+8sf/o14hQmQfdC31OFP0eb5qFVRgEjMJ9mwolqWIW+AcbIAhX2GJVdTLZoUJj6T5PiUtM= nicolas@tchoum'
    ]

    ssh_keys.each do |valid_key|
      it "should be valid" do
        ssh_key = FactoryGirl.build(:gitolite_public_key, :user_id => @user1.id, :title => 'foo', :key => valid_key)
        expect(ssh_key).to be_valid
      end
    end
  end

end
