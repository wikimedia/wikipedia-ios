#!/usr/bin/env ruby

def iterate_and_remove(dir)
  Dir.foreach(dir) do |item|
    next if item.start_with?('.') || item.length == 0
    #puts item
    full_path = dir + '/' + item
    #puts full_path
    begin
      new_file = ''
      skip = true
      File.foreach(full_path) do |line|
        if skip && (/^\/\//.match(line) || line.strip.length == 0)
          
        else
          skip = false
          new_file << line
        end
      end
      File.delete(full_path)
      f = File.new(full_path, 'w')
      f.write(new_file)
      f.close
    rescue Errno::EISDIR

    end
  end
end

dirs = ['Wikipedia/Code', 'WikipediaUnitTests/Code', 'WMFKit']

dirs.each do |dir|
  iterate_and_remove(dir)
end

