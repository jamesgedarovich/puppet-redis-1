require 'spec_helper'

describe 'redis', :type => 'class' do

  context "On a Debian OS with default params" do

    let :facts do
      {
        :osfamily  => 'Debian',
        :ipaddress => '10.0.0.1'
      }
    end # let

    it do
      should contain_package('build-essential').with_ensure('present')
      should contain_package('wget').with_ensure('present')

      should contain_file('/opt/redis-src').with(:ensure => 'directory')
      should contain_file('/etc/redis').with(:ensure => 'directory')
      should contain_file('redis-lib').with(:ensure => 'directory',
                                            :path   => '/var/lib/redis')
      should contain_file('redis-lib-port').with(:ensure => 'directory',
                                                 :path   => '/var/lib/redis/6379')
      should contain_file('redis-pkg').with(:ensure => 'present',
                                            :path   => '/opt/redis-src/redis-2.4.13.tar.gz',
                                            :mode   => '0644',
                                            :source => 'puppet:///modules/redis/redis-2.4.13.tar.gz')
      should contain_exec('get-redis-pkg').with_command(/http:\/\/redis\.googlecode\.com\/files\/redis-2\.4\.13\.tar\.gz/)
      should contain_file('redis-init').with(:ensure => 'present',
                                             :path   => '/etc/init.d/redis_6379',
                                             :mode   => '0755')
      should contain_file('redis-cli-link').with(:ensure => 'link',
                                                 :path   => '/usr/local/bin/redis-cli',
                                                 :target => '/opt/redis/bin/redis-cli')

      should contain_exec('unpack-redis').with(:cwd  => '/opt/redis-src',
                                               :path => '/bin:/usr/bin')
      should contain_exec('install-redis').with(:cwd   => '/opt/redis-src',
                                                :path  => '/bin:/usr/bin')

      should contain_service('redis').with(:ensure => 'running',
                                           :name   => 'redis_6379',
                                           :enable => true)

      # These values were changed in 2.6.
      should contain_file('6379.conf').with_content(/maxclients 0/)
      should contain_file('6379.conf').with_content(/hash-max-zipmap-entries 512/)
      should contain_file('6379.conf').with_content(/hash-max-zipmap-value 64/)
      should_not contain_file('6379.conf').with_content(/hash-max-ziplist-entries 512/)
      should_not contain_file('6379.conf').with_content(/hash-max-ziplist-value 64/)
    end # it
  end # context

  context "On a Debian OS with non-default src and bin locations" do

    let :facts do
      {
        :osfamily  => 'Debian',
        :ipaddress => '10.0.0.1'
      }
    end # let

    let :params do
      {
        :redis_src_dir => '/fake/path/to/redis-src',
        :redis_bin_dir => '/fake/path/to/redis'
      }
    end # let

    it do
      should contain_package('build-essential').with_ensure('present')
      should contain_package('wget').with_ensure('present')

      should contain_file('/fake/path/to/redis-src').with(:ensure => 'directory')
      should contain_file('/etc/redis').with(:ensure => 'directory')
      should contain_file('redis-lib').with(:ensure => 'directory',
                                            :path   => '/var/lib/redis')
      should contain_file('redis-lib-port').with(:ensure => 'directory',
                                                 :path   => '/var/lib/redis/6379')
      should contain_file('redis-pkg').with(:ensure => 'present',
                                            :path   => '/fake/path/to/redis-src/redis-2.4.13.tar.gz',
                                            :mode   => '0644',
                                            :source => 'puppet:///modules/redis/redis-2.4.13.tar.gz')
      should contain_file('redis-init').with(:ensure => 'present',
                                             :path   => '/etc/init.d/redis_6379',
                                             :mode   => '0755')
      should contain_file('redis-cli-link').with(:ensure => 'link',
                                                 :path   => '/usr/local/bin/redis-cli',
                                                 :target => '/fake/path/to/redis/bin/redis-cli')

      should contain_exec('unpack-redis').with(:cwd  => '/fake/path/to/redis-src',
                                               :path => '/bin:/usr/bin')
      should contain_exec('install-redis').with(:cwd   => '/fake/path/to/redis-src',
                                                :path  => '/bin:/usr/bin')

      should contain_service('redis').with(:ensure => 'running',
                                           :name   => 'redis_6379',
                                           :enable => true)
    end # it
  end # context

  context "On a Debian OS with version 2.6 param" do

    let :facts do
      {
        :osfamily  => 'Debian',
        :ipaddress => '10.0.0.1'
      }
    end # let

    let :params do
      {
        :version => '2.6.4'
      }
    end # let

    it do
      should_not contain_file('redis-pkg')
      should contain_exec('get-redis-pkg').with_command(/http:\/\/redis\.googlecode\.com\/files\/redis-2\.6\.4\.tar\.gz/)

      # Maxclients is left out for 2.6 unless it is explicitly set.
      should_not contain_file('6379.conf').with_content(/maxclients 0/)

      # These params were renamed b/w 2.4 and 2.6.
      should contain_file('6379.conf').with_content(/hash-max-ziplist-entries 512/)
      should contain_file('6379.conf').with_content(/hash-max-ziplist-value 64/)
      should_not contain_file('6379.conf').with_content(/hash-max-zipmap-entries 512/)
      should_not contain_file('6379.conf').with_content(/hash-max-zipmap-value 64/)
    end # it
  end # describe

  context "On Debian systems with no password parameter" do

    let :facts do
      {
        :osfamily  => 'Debian',
        :ipaddress => '10.0.0.1'
      }
    end # let

    let :params do
      {
        :redis_password => false
      }
    end # let

    it do
      should_not contain_file('6379.conf').with_content(/^requirepass/)
    end # it
  end # context

  context "On Debian systems with password parameter" do

    let :facts do
      {
        :osfamily  => 'Debian',
        :ipaddress => '10.0.0.1'
      }
    end # let

    let :params do
      {
        :redis_password => 'ThisIsAReallyBigSecret'
      }
    end # let

    it do
      should contain_file('6379.conf').with_content(/^requirepass ThisIsAReallyBigSecret/)
    end # it
  end # context

  context "With an invalid version param." do

    let :facts do
      {
        :ipaddress => '10.0.0.1'
      }
    end # let

    let :params do
      {
        :version => 'bad version'
      }
    end # let

    it do
      expect { should raise_error(Puppet::Error) }
    end # it
  end # context
end # describe
