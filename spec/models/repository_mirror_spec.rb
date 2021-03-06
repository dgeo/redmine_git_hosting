require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RepositoryMirror do

  before do
    @project        = FactoryGirl.create(:project)
    @repository_git = FactoryGirl.create(:repository, :project_id => @project.id)
    @mirror         = FactoryGirl.build(:repository_mirror, :repository_id => @repository_git.id)
  end

  subject { @mirror }

  it { should respond_to(:repository) }
  it { should respond_to(:url) }
  it { should respond_to(:push_mode) }
  it { should respond_to(:include_all_branches) }
  it { should respond_to(:include_all_tags) }
  it { should respond_to(:explicit_refspec) }
  it { should respond_to(:active) }

  it { should be_valid }

  it { expect(@mirror.active).to be true }
  it { expect(@mirror.include_all_branches).to be false }
  it { expect(@mirror.include_all_tags).to be false }
  it { expect(@mirror.explicit_refspec).to eq "" }
  it { expect(@mirror.push_mode).to eq 0 }
  it { expect(@mirror.push_mode).to be_a(Integer) }

  ## Test presence validation
  describe "when repository_id is not present" do
    before { @mirror.repository_id = "" }
    it { should_not be_valid }
  end

  describe "when url is not present" do
    before { @mirror.url = "" }
    it { should_not be_valid }
  end

  describe "when push_mode is not present" do
    before { @mirror.push_mode = "" }
    it { should_not be_valid }
  end

  describe "when push_mode is out of range" do
    before { @mirror.push_mode = 3 }
    it { should_not be_valid }
  end

  describe "when include_all_branches && include_all_tags" do
    before do
      @mirror.push_mode = 1
      @mirror.include_all_branches = true
      @mirror.include_all_tags = true
    end

    it { should_not be_valid }
  end

  describe "when push_mode forced without params" do
    before do
      @mirror.push_mode = 1
    end

    it { should_not be_valid }
  end

  describe "when push_mode fast forward without params" do
    before do
      @mirror.push_mode = 2
    end

    it { should_not be_valid }
  end

  describe "when active is true" do
    before { @mirror.active = true }
    it { should be_valid }
    it { expect(@mirror.active).to be true }
  end

  describe "when active is false" do
    before { @mirror.active = false }
    it { should be_valid }
    it { expect(@mirror.active).to be false }
  end

  ## Test format validation
  describe "when git url is valid" do
    it "should be valid" do
      addresses = [
        'ssh://user@host.xz:2222/path/to/repo.git',
        'ssh://user@host.xz/path/to/repo.git',
        'ssh://host.xz:2222/path/to/repo.git',
        'ssh://host.xz/path/to/repo.git',
        'ssh://user@host.xz/path/to/repo.git',
        'ssh://host.xz/path/to/repo.git',
        'ssh://user@host.xz/~user/path/to/repo.git',
        'ssh://host.xz/~user/path/to/repo.git',
        'ssh://user@host.xz/~/path/to/repo.git',
        'ssh://host.xz/~/path/to/repo.git'
      ]

      addresses.each do |valid_address|
        @mirror.url = valid_address
        expect(@mirror).to be_valid
      end
    end
  end

  ## Test uniqueness validation
  describe "when mirror url is already taken" do
    before do
      @mirror.save
      @mirror_with_same_url = @mirror.dup
      @mirror_with_same_url.save
    end

    it { expect(@mirror_with_same_url).not_to be_valid }
  end

end
