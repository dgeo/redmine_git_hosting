require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Repository::Git do

  before :all do
    Setting.plugin_redmine_git_hosting[:gitolite_redmine_storage_dir] = 'redmine/'
    Setting.plugin_redmine_git_hosting[:http_server_subdir] = 'git/'
    User.current = nil

    @project_parent = FactoryGirl.create(:project, :identifier => 'project-parent')
    @project_child  = FactoryGirl.create(:project, :identifier => 'project-child', :parent_id => @project_parent.id)
  end


  def create_user_with_permissions(project)
    role = FactoryGirl.create(:role)
    user = FactoryGirl.create(:user, :login => 'redmine-test-user')

    members = Member.new(:role_ids => [role.id], :user_id => user.id)
    project.members << members

    return user
  end


  context "common_tests" do
    before do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = true
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = false

      @repository_1   = FactoryGirl.create(:repository, :project_id => @project_child.id, :is_default => true)
      @repository_2   = FactoryGirl.create(:repository, :project_id => @project_child.id, :identifier => 'repo-test')

      @repository_1.extra
      @repository_2.extra
    end

    subject { @repository_1 }

    ## Test relations
    it { should respond_to(:git_extra) }
    it { should respond_to(:git_notification) }
    it { should respond_to(:mirrors) }
    it { should respond_to(:post_receive_urls) }
    it { should respond_to(:deployment_credentials) }
    it { should respond_to(:git_config_keys) }

    ## Test attributes
    it { should respond_to(:identifier) }
    it { should respond_to(:url) }
    it { should respond_to(:root_url) }

    ## Test methods
    it { should respond_to(:extra) }

    it { should respond_to(:report_last_commit_with_git_hosting) }
    it { should respond_to(:extra_report_last_commit_with_git_hosting) }

    it { should respond_to(:git_cache_id) }
    it { should respond_to(:redmine_name) }

    it { should respond_to(:gitolite_repository_path) }
    it { should respond_to(:gitolite_repository_name) }
    it { should respond_to(:redmine_repository_path) }

    it { should respond_to(:new_repository_name) }
    it { should respond_to(:old_repository_name) }

    it { should respond_to(:http_user_login) }
    it { should respond_to(:git_access_path) }
    it { should respond_to(:http_access_path) }

    it { should respond_to(:ssh_url) }
    it { should respond_to(:git_url) }
    it { should respond_to(:http_url) }
    it { should respond_to(:https_url) }

    it { should respond_to(:available_urls) }

    it { should respond_to(:default_list) }
    it { should respond_to(:mail_mapping) }

    it { should respond_to(:get_full_parent_path) }
    it { should respond_to(:exists_in_gitolite?) }
    it { should respond_to(:gitolite_hook_key) }

    it { should be_valid }

    ## Test attributes more specifically
    it { expect(@repository_1.report_last_commit_with_git_hosting).to be true }
    it { expect(@repository_1.extra_report_last_commit_with_git_hosting).to be true }

    it { expect(@repository_1.extra[:git_http]).to eq 1 }
    it { expect(@repository_1.extra[:git_daemon]).to be false }
    it { expect(@repository_1.extra[:git_notify]).to be true }
    it { expect(@repository_1.extra[:default_branch]).to eq 'master' }

    it { expect(@repository_1.available_urls).to be_a(Hash) }

    describe "#available_urls" do

      context "with no option" do
        before do
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 0
          @repository_1.save
        end

        my_hash = {}

        it "should return an empty Hash" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with all options" do
        before do
          @user = create_user_with_permissions(@project_child)
          User.current = @user

          @repository_1.extra[:git_daemon] = true
          @repository_1.extra[:git_http]   = 2
          @repository_1.save
        end

        my_hash = {
          :ssh   => {:url => "ssh://git@localhost/redmine/project-parent/project-child.git",             :commiter => "false"},
          :https => {:url => "https://redmine-test-user@localhost/git/project-parent/project-child.git", :commiter => "false"},
          :http  => {:url => "http://redmine-test-user@localhost/git/project-parent/project-child.git",  :commiter => "false"},
          :git   => {:url => "git://localhost/redmine/project-parent/project-child.git",                 :commiter => "false"}
        }

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with git daemon" do
        before do
          User.current = nil

          @repository_1.extra[:git_daemon] = true
          @repository_1.extra[:git_http]   = 0
          @repository_1.save
        end

        my_hash = {:git => {:url=>"git://localhost/redmine/project-parent/project-child.git", :commiter=>"false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with ssh" do
        before do
          @user = create_user_with_permissions(@project_child)
          User.current = @user

          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 0
          @repository_1.save
        end

        my_hash = { :ssh => {:url => "ssh://git@localhost/redmine/project-parent/project-child.git", :commiter => "false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with http" do
        before do
          User.current = nil
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 3
          @repository_1.save
        end

        my_hash = { :http => {:url => "http://localhost/git/project-parent/project-child.git", :commiter => "false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with https" do
        before do
          User.current = nil
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 1
          @repository_1.save
        end

        my_hash = { :https => {:url => "https://localhost/git/project-parent/project-child.git", :commiter => "false"}}

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end

      context "with http and https" do
        before do
          User.current = nil
          @repository_1.extra[:git_daemon] = false
          @repository_1.extra[:git_http]   = 2
          @repository_1.save
        end

        my_hash = {
          :https => {:url => "https://localhost/git/project-parent/project-child.git", :commiter => "false"},
          :http  => {:url => "http://localhost/git/project-parent/project-child.git",  :commiter => "false"}
        }

        it "should return a Hash of Git url" do
          expect(@repository_1.available_urls).to eq my_hash
        end
      end
    end

    ## Test uniqueness validation
    describe "when blank identifier is already taken by a repository" do
      before do
        @repository = FactoryGirl.build(:repository, :project_id => @project_child.id, :identifier => '')
      end

      it { expect(@repository).not_to be_valid }
    end

    describe "when set as default and blank identifier is already taken by a repository" do
      before do
        @repository = FactoryGirl.build(:repository, :project_id => @project_child.id, :identifier => '', :is_default => true)
      end

      it { expect(@repository).not_to be_valid }
    end

    describe "when identifier is already taken by a project" do
      before do
        @repository = FactoryGirl.build(:repository, :project_id => @project_child.id, :identifier => 'project-child')
      end

      it { expect(@repository).not_to be_valid }
    end

    describe "when identifier is already taken by a repository with same project" do
      before do
        @repository = FactoryGirl.build(:repository, :project_id => @project_child.id, :identifier => 'repo-test')
      end

      it { expect(@repository).not_to be_valid }
    end

    describe "when identifier are not unique" do
      before do
        @repository = FactoryGirl.build(:repository, :project_id => @project_parent.id, :identifier => 'repo-test')
      end

      it { expect(@repository).to be_valid }
    end

    describe "when identifier are unique" do
      before do
        Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = true
        @repository = FactoryGirl.build(:repository, :project_id => @project_parent.id, :identifier => 'repo-test')
      end

      it { expect(@repository).not_to be_valid }
    end


    ## Test change validation
    describe "when identifier is changed" do
      before do
        @repository_1.identifier = "foo"
      end

      it { expect(@repository_1).not_to be_valid }
    end

    describe "when git_daemon is true" do
      before do
        @repository_1.extra[:git_daemon] = true
        @repository_1.save
      end

      it { should be_valid }
      it { expect(@repository_1.extra[:git_daemon]).to be true }
    end

    describe "when git_daemon is false" do
      before do
        @repository_1.extra[:git_daemon] = false
        @repository_1.save
      end

      it { should be_valid }
      it { expect(@repository_1.extra[:git_daemon]).to be false }
    end

    describe "when git_notify is true" do
      before do
        @repository_1.extra[:git_notify] = true
        @repository_1.save
      end

      it { should be_valid }
      it { expect(@repository_1.extra[:git_notify]).to be true }
    end

    describe "when git_notify is false" do
      before do
        @repository_1.extra[:git_notify] = false
        @repository_1.save
      end

      it { should be_valid }
      it { expect(@repository_1.extra[:git_notify]).to be false }
    end

    describe "when default_branch is changed" do
      before do
        @repository_1.extra[:default_branch] = 'devel'
        @repository_1.save
      end

      it { should be_valid }
      it { expect(@repository_1.extra[:default_branch]).to eq 'devel' }
    end


    ## Test format validation
    describe "when git http is valid" do
      it "should be valid" do
        modes = [ 0, 1, 2, 3 ]
        modes.each do |valid_mode|
          @repository_1.extra[:git_http] = valid_mode
          expect(@repository_1.extra).to be_valid
        end
      end
    end

    describe "when git http is invalid" do
      it "should be invalid" do
        modes = [ 4, 5, 6, 7 ]
        modes.each do |invalid_mode|
          @repository_1.extra[:git_http] = invalid_mode
          expect(@repository_1.extra).not_to be_valid
        end
      end
    end


    describe "Repository::Git class" do
      it { expect(Repository::Git).to respond_to(:repo_ident_unique?) }
      it { expect(Repository::Git).to respond_to(:have_duplicated_identifier?) }
      it { expect(Repository::Git).to respond_to(:repo_path_to_git_cache_id) }
      it { expect(Repository::Git).to respond_to(:find_by_path) }

      describe ".repo_ident_unique?" do
        it { expect(Repository::Git.repo_ident_unique?).to be false }
      end

      describe ".have_duplicated_identifier?" do
        it { expect(Repository::Git.have_duplicated_identifier?).to be false }
      end

      describe ".repo_path_to_git_cache_id" do
        describe "when repo path is not found" do
          before do
            @git_cache_id = Repository::Git.repo_path_to_git_cache_id('foo.git')
          end

          it { expect(@git_cache_id).to be nil }
        end
      end
    end
  end


  def collection_of_unique_repositories
    @repository_1   = FactoryGirl.create(:repository, :project_id => @project_child.id, :is_default => true)
    @repository_2   = FactoryGirl.create(:repository, :project_id => @project_child.id, :identifier => 'repo1-test')

    @repository_3   = FactoryGirl.create(:repository, :project_id => @project_parent.id, :is_default => true)
    @repository_4   = FactoryGirl.create(:repository, :project_id => @project_parent.id, :identifier => 'repo2-test')

    @repository_1.extra
    @repository_2.extra
    @repository_3.extra
    @repository_4.extra
  end


  def collection_of_non_unique_repositories
    @repository_1   = FactoryGirl.create(:repository, :project_id => @project_child.id, :is_default => true)
    @repository_2   = FactoryGirl.create(:repository, :project_id => @project_child.id, :identifier => 'repo-test')

    @repository_3   = FactoryGirl.create(:repository, :project_id => @project_parent.id, :is_default => true)
    @repository_4   = FactoryGirl.create(:repository, :project_id => @project_parent.id, :identifier => 'repo-test')

    @repository_1.extra
    @repository_2.extra
    @repository_3.extra
    @repository_4.extra
  end


  context "when hierarchical_organisation_with_non_unique_identifier" do
    before do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = true
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = false
      collection_of_non_unique_repositories
    end

    describe ".repo_ident_unique?" do
      it "should be false" do
        expect(Repository::Git.repo_ident_unique?).to be false
      end
    end

    describe ".have_duplicated_identifier?" do
      it "should be true" do
        expect(Repository::Git.have_duplicated_identifier?).to be true
      end
    end

    describe "repository1" do
      it "should be default repository" do
        expect(@repository_1.is_default).to be true
      end

      it "should have nil identifier" do
        expect(@repository_1.identifier).to be nil
      end

      it "should have a valid url" do
        expect(@repository_1.url).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it "should have a valid root_url" do
        expect(@repository_1.root_url).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_1.git_cache_id).to eq 'project-child'
      end

      it "should have a valid redmine_name" do
        expect(@repository_1.redmine_name).to eq 'project-child'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_1.gitolite_repository_path).to eq 'repositories/redmine/project-parent/project-child.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_1.gitolite_repository_name).to eq 'redmine/project-parent/project-child'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_1.redmine_repository_path).to eq 'project-parent/project-child'
      end

      it "should have a valid ssh_url" do
        expect(@repository_1.ssh_url).to eq 'ssh://git@localhost/redmine/project-parent/project-child.git'
      end

      it "should have a valid git_url" do
        expect(@repository_1.git_url).to eq 'git://localhost/redmine/project-parent/project-child.git'
      end

      it "should have a valid http_url" do
        expect(@repository_1.http_url).to eq 'http://localhost/git/project-parent/project-child.git'
      end

      it "should have a valid https_url" do
        expect(@repository_1.https_url).to eq 'https://localhost/git/project-parent/project-child.git'
      end

      it "should have a valid http_user_login" do
        expect(@repository_1.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_1.git_access_path).to eq 'redmine/project-parent/project-child.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_1.http_access_path).to eq 'git/project-parent/project-child.git'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_1.new_repository_name).to eq 'redmine/project-parent/project-child'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_1.old_repository_name).to eq 'redmine/project-parent/project-child'
      end
    end

    describe "repository2" do
      it "should not be default repository" do
        expect(@repository_2.is_default).to be false
      end

      it "should have a valid identifier" do
        expect(@repository_2.identifier).to eq 'repo-test'
      end

      it "should have a valid url" do
        expect(@repository_2.url).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid root_url" do
        expect(@repository_2.root_url).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid git_cache_id" do
        expect(@repository_2.git_cache_id).to eq 'project-child/repo-test'
      end

      it "should have a valid redmine_name" do
        expect(@repository_2.redmine_name).to eq 'repo-test'
      end

      it "should have a valid gitolite_repository_path" do
        expect(@repository_2.gitolite_repository_path).to eq 'repositories/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid gitolite_repository_name" do
        expect(@repository_2.gitolite_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end

      it "should have a valid redmine_repository_path" do
        expect(@repository_2.redmine_repository_path).to eq 'project-parent/project-child/repo-test'
      end

      it "should have a valid ssh_url" do
        expect(@repository_2.ssh_url).to eq 'ssh://git@localhost/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid git_url" do
        expect(@repository_2.git_url).to eq 'git://localhost/redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid http_url" do
        expect(@repository_2.http_url).to eq 'http://localhost/git/project-parent/project-child/repo-test.git'
      end

      it "should have a valid https_url" do
        expect(@repository_2.https_url).to eq 'https://localhost/git/project-parent/project-child/repo-test.git'
      end

      it "should have a valid http_user_login" do
        expect(@repository_2.http_user_login).to eq ''
      end

      it "should have a valid git_access_path" do
        expect(@repository_2.git_access_path).to eq 'redmine/project-parent/project-child/repo-test.git'
      end

      it "should have a valid http_access_path" do
        expect(@repository_2.http_access_path).to eq 'git/project-parent/project-child/repo-test.git'
      end

      it "should have a valid new_repository_name" do
        expect(@repository_2.new_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end

      it "should have a valid old_repository_name" do
        expect(@repository_2.old_repository_name).to eq 'redmine/project-parent/project-child/repo-test'
      end
    end

    describe "repository3" do
      it "should have a git_cache_id" do
        expect(@repository_3.git_cache_id).to eq 'project-parent'
      end

      it "should have a redmine_name" do
        expect(@repository_3.redmine_name).to eq 'project-parent'
      end
    end

    describe "repository4" do
      it "should have a git_cache_id" do
        expect(@repository_4.git_cache_id).to eq 'project-parent/repo-test'
      end

      it "should have a redmine_name" do
        expect(@repository_4.redmine_name).to eq 'repo-test'
      end
    end

    describe ".repo_path_to_git_cache_id" do
      describe "when identifier are not unique" do
        before do
          @repo1 = Repository::Git.repo_path_to_object(@repository_1.url)
          @repo2 = Repository::Git.repo_path_to_object(@repository_2.url)
          @repo3 = Repository::Git.repo_path_to_object(@repository_3.url)
          @repo4 = Repository::Git.repo_path_to_object(@repository_4.url)

          @git_cache_id1 = Repository::Git.repo_path_to_git_cache_id(@repository_1.url)
          @git_cache_id2 = Repository::Git.repo_path_to_git_cache_id(@repository_2.url)
          @git_cache_id3 = Repository::Git.repo_path_to_git_cache_id(@repository_3.url)
          @git_cache_id4 = Repository::Git.repo_path_to_git_cache_id(@repository_4.url)
        end

        describe "repositories should match" do
          it { expect(@repo1).to eq @repository_1 }
          it { expect(@repo2).to eq @repository_2 }
          it { expect(@repo3).to eq @repository_3 }
          it { expect(@repo4).to eq @repository_4 }

          it { expect(@git_cache_id1).to eq 'project-child' }
          it { expect(@git_cache_id2).to eq 'project-child/repo-test' }
          it { expect(@git_cache_id3).to eq 'project-parent' }
          it { expect(@git_cache_id4).to eq 'project-parent/repo-test' }
        end
      end
    end
  end


  context "flat_organisation_with_unique_identifier" do
    before do
      Setting.plugin_redmine_git_hosting[:hierarchical_organisation] = false
      Setting.plugin_redmine_git_hosting[:unique_repo_identifier] = true
      collection_of_unique_repositories
    end

    describe ".repo_ident_unique?" do
      it "should be false" do
        expect(Repository::Git.repo_ident_unique?).to be true
      end
    end

    describe ".have_duplicated_identifier?" do
      it "should be true" do
        expect(Repository::Git.have_duplicated_identifier?).to be false
      end
    end

    describe "repository1" do
      it { expect(@repository_1.is_default).to be true }
      it { expect(@repository_1.identifier).to be nil }
      it { expect(@repository_1.url).to eq      'repositories/redmine/project-child.git' }
      it { expect(@repository_1.root_url).to eq 'repositories/redmine/project-child.git' }
      it { expect(@repository_1.git_cache_id).to eq 'project-child' }
      it { expect(@repository_1.redmine_name).to eq 'project-child' }
      it { expect(@repository_1.gitolite_repository_path).to eq 'repositories/redmine/project-child.git' }
      it { expect(@repository_1.gitolite_repository_name).to eq 'redmine/project-child' }
      it { expect(@repository_1.redmine_repository_path).to eq  'project-child' }
      it { expect(@repository_1.new_repository_name).to eq 'redmine/project-child' }
      it { expect(@repository_1.old_repository_name).to eq 'redmine/project-child' }
      it { expect(@repository_1.http_user_login).to eq  '' }
      it { expect(@repository_1.git_access_path).to eq  'redmine/project-child.git' }
      it { expect(@repository_1.http_access_path).to eq 'git/project-child.git' }
      it { expect(@repository_1.ssh_url).to eq   'ssh://git@localhost/redmine/project-child.git' }
      it { expect(@repository_1.git_url).to eq   'git://localhost/redmine/project-child.git' }
      it { expect(@repository_1.http_url).to eq  'http://localhost/git/project-child.git' }
      it { expect(@repository_1.https_url).to eq 'https://localhost/git/project-child.git' }
    end


    describe "repository2" do
      it { expect(@repository_2.is_default).to be false }
      it { expect(@repository_2.identifier).to eq 'repo1-test' }
      it { expect(@repository_2.url).to eq      'repositories/redmine/repo1-test.git' }
      it { expect(@repository_2.root_url).to eq 'repositories/redmine/repo1-test.git' }
      it { expect(@repository_2.git_cache_id).to eq 'repo1-test' }
      it { expect(@repository_2.redmine_name).to eq 'repo1-test' }
      it { expect(@repository_2.gitolite_repository_path).to eq 'repositories/redmine/repo1-test.git' }
      it { expect(@repository_2.gitolite_repository_name).to eq 'redmine/repo1-test' }
      it { expect(@repository_2.redmine_repository_path).to eq  'repo1-test' }
      it { expect(@repository_2.new_repository_name).to eq 'redmine/repo1-test' }
      it { expect(@repository_2.old_repository_name).to eq 'redmine/repo1-test' }
      it { expect(@repository_2.http_user_login).to eq  '' }
      it { expect(@repository_2.git_access_path).to eq  'redmine/repo1-test.git' }
      it { expect(@repository_2.http_access_path).to eq 'git/repo1-test.git' }
      it { expect(@repository_2.ssh_url).to eq   'ssh://git@localhost/redmine/repo1-test.git' }
      it { expect(@repository_2.git_url).to eq   'git://localhost/redmine/repo1-test.git' }
      it { expect(@repository_2.http_url).to eq  'http://localhost/git/repo1-test.git' }
      it { expect(@repository_2.https_url).to eq 'https://localhost/git/repo1-test.git' }
    end


    describe "repository3" do
      it { expect(@repository_3.url).to eq      'repositories/redmine/project-parent.git' }
      it { expect(@repository_3.root_url).to eq 'repositories/redmine/project-parent.git' }
      it { expect(@repository_3.git_cache_id).to eq 'project-parent' }
      it { expect(@repository_3.redmine_name).to eq 'project-parent' }
    end


    describe "repository4" do
      it { expect(@repository_4.url).to eq      'repositories/redmine/repo2-test.git' }
      it { expect(@repository_4.root_url).to eq 'repositories/redmine/repo2-test.git' }
      it { expect(@repository_4.git_cache_id).to eq 'repo2-test' }
      it { expect(@repository_4.redmine_name).to eq 'repo2-test' }
    end


    describe ".repo_path_to_git_cache_id" do
      describe "when identifier are unique" do
        before do
          @repo1 = Repository::Git.repo_path_to_object(@repository_1.url)
          @repo2 = Repository::Git.repo_path_to_object(@repository_2.url)
          @repo3 = Repository::Git.repo_path_to_object(@repository_3.url)
          @repo4 = Repository::Git.repo_path_to_object(@repository_4.url)

          @git_cache_id1 = Repository::Git.repo_path_to_git_cache_id(@repository_1.url)
          @git_cache_id2 = Repository::Git.repo_path_to_git_cache_id(@repository_2.url)
          @git_cache_id3 = Repository::Git.repo_path_to_git_cache_id(@repository_3.url)
          @git_cache_id4 = Repository::Git.repo_path_to_git_cache_id(@repository_4.url)
        end

        describe "repositories should match" do
          it { expect(@repo1).to eq @repository_1 }
          it { expect(@repo2).to eq @repository_2 }
          it { expect(@repo3).to eq @repository_3 }
          it { expect(@repo4).to eq @repository_4 }

          it { expect(@git_cache_id1).to eq 'project-child' }
          it { expect(@git_cache_id2).to eq 'repo1-test' }
          it { expect(@git_cache_id3).to eq 'project-parent' }
          it { expect(@git_cache_id4).to eq 'repo2-test' }
        end
      end
    end
  end

end
