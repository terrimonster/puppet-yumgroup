Puppet::Type.type(:yumgroup).provide(:yum) do
  desc 'Support for managing the yum groups'

  commands :yum => '/usr/bin/yum'

  defaultfor :osfamily => :redhat

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name] || resources[prov.name.downcase]
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def self.instances
    groups = []

    # get list of all groups
    yum_content = yum('grouplist')

    # turn of collecting to avoid lines like 'Loaded plugins'
    collect_groups = false

    # loop through lines of yum output
    yum_content.lines.each do |line|
      # if we get to 'Available Groups:' string, break the loop
      break if line.chomp =~ /Available Groups:/

      # collect groups
      if collect_groups and line.chomp !~ /(Installed|Available)/
        current_name = line.chomp.sub(/^\s+/,'\1').sub(/ \[.*\]/,'')
        groups << new(
          :name   => current_name,
          :ensure => :present
        )
      end

      # turn on collecting when the 'Installed Groups:' is reached
      collect_groups = true if line.chomp =~ /Installed Groups:/i
    end
    groups
  end

  def create
    yum('-y', 'groupinstall', @resource[:name])
    @property_hash[:ensure] == :present
  end

  def destroy
    yum('-y', 'groupremove', @resource[:name])
    @property_hash[:ensure] == :absent
  end
end
