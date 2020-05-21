#!/usr/bin/env ruby

require_relative "../lib/validateFile.rb"
require "tmpdir"

# Get the files from directory that are .xml files
string_all_files = `ls`
all_files = []
all_files = string_all_files.split("\n")
xml_files = []
all_files.each do |file|
  if file.slice(-4..-1) == ".xml"
    xml_files << file
  end
end

tempfilename = File.join(Dir.tmpdir, "temporary")
tempfile = File.new(tempfilename, "w")

files_validation = []
#loop on xml files to make validations
xml_files.each do |file|
  new_file = ValidateFile.new(file)
  file_lines = IO.readlines(file)
  file_lines.each_with_index do |line, i|
    line.gsub!("\n", " #{i + 1}\n")
    line.gsub!(">", "> #{i + 1}\n")
    tempfile.syswrite(line)
  end

  temp_lines = IO.readlines(tempfile)
  temp_lines.each_with_index do |line, i|
    new_file.check_line(line)
  end
  files_validation << new_file
end

tempfile.close

files_validation.each do |check_file|
  check_file.check_unclosed_tags
  check_file.errors.open_tag.each do |v, i|
    puts i
  end
  check_file.errors.close_tag.each do |v, i|
    puts i
  end
end

File.delete(tempfilename)

p xml_files
