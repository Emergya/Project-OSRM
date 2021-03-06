Given /^the speedprofile "([^"]*)"$/ do |profile|
  read_speedprofile profile
end

Given /^the speedprofile settings$/ do |table|
  table.raw.each do |row|
    speedprofile[ row[0] ] = row[1]
  end
end

Given /^the nodes$/ do |table|
  table.raw.each_with_index do |row,ri|
    row.each_with_index do |name,ci|
      unless name.empty?
        raise "*** node invalid name '#{name}', must be single characters" unless name.size == 1
        raise "*** invalid node name '#{name}', must me alphanumeric" unless name.match /[a-z0-9]/
        raise "*** duplicate node '#{name}'" if name_node_hash[name]
        node = OSM::Node.new make_osm_id, OSM_USER, OSM_TIMESTAMP, ORIGIN[0]+ci*ZOOM, ORIGIN[1]-ri*ZOOM 
        node << { :name => name }
        node.uid = OSM_UID
        osm_db << node
        name_node_hash[name] = node
      end
    end
  end
end

Given /^the ways$/ do |table|
  table.hashes.each do |row|
    name = row.delete 'nodes'
    raise "*** duplicate way '#{name}'" if name_way_hash[name]
    way = OSM::Way.new make_osm_id, OSM_USER, OSM_TIMESTAMP
    defaults = { 'highway' => 'primary' }
    way << defaults.merge( 'name' => name ).merge(row)
    way.uid = OSM_UID
    name.each_char do |c|
      raise "*** node invalid name '#{c}', must be single characters" unless c.size == 1
      raise "*** ways cannot use numbered nodes, '#{name}'" unless c.match /[a-z]/
      node = find_node_by_name(c)
      raise "*** unknown node '#{c}'" unless node
      way << node
    end
    osm_db << way
    name_way_hash[name] = way
  end
end

Given /^the relations$/ do |table|
  table.hashes.each do |row|
    relation = OSM::Relation.new make_osm_id, OSM_USER, OSM_TIMESTAMP
    relation << { :type => :restriction, :restriction => 'no_left_turn' }
    from_way = find_way_by_name(row['from'])
    raise "*** unknown way '#{row['from']}'" unless from_way
    to_way = find_way_by_name(row['to'])
    raise "*** unknown way '#{row['to']}'" unless to_way
    relation << OSM::Member.new( 'way', from_way.id, 'from' )
    relation << OSM::Member.new( 'way', to_way.id, 'to' )
    c = row['via']
    unless c.empty?
      raise "*** node invalid name '#{c}', must be single characters" unless c.size == 1
      raise "*** via node cannot use numbered nodes, '#{c}'" unless c.match /[a-z]/
      via_node = find_node_by_name(c)
      raise "*** unknown node '#{row['via']}'" unless via_node
      relation << OSM::Member.new( 'node', via_node.id, 'via' )
    end
    relation.uid = OSM_UID
    osm_db << relation
  end
end

Given /^the defaults$/ do
end

