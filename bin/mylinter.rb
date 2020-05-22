#!/usr/bin/env ruby

require_relative '../lib/validate_file.rb'
require 'tmpdir'

space_ident = 2

# Get the files from directory that are .xml files
string_all_files = `ls`
all_files = string_all_files.split("\n")
xml_files = []
all_files.each do |file|
  xml_files << file if file.slice(-4..-1) == '.xml'
end

tempfilename = File.join(Dir.tmpdir, 'temporary')
tempfile = File.new(tempfilename, 'w')

files_validation = []
# loop on xml files to make validations
xml_files.each do |file|
  new_file = ValidateFile.new(file, space_ident)
  file_lines = IO.readlines(file)
  file_lines.each_with_index do |line, i|
    line.gsub!("\n", " #{i + 1}\n")
    line.gsub!('>', "> #{i + 1}\n")
    tempfile.syswrite(line)
  end

  temp_lines = IO.readlines(tempfile)
  temp_lines.each do |line|
    new_file.check_line(line)
  end
  files_validation << new_file
end

tempfile.close

files_validation.each do |check_file|
  check_file.check_unclosed_tags
  check_file.errors.open_tag.each do |_v, i|
    puts i
  end
  check_file.errors.close_tag.each do |_v, i|
    puts i
  end
  check_file.errors.ident.each do |v|
    puts v
  end
  puts '============================================='
  puts "TOTAL ERRORS FOUND #{check_file.error_number}"
  puts '============================================='
end

File.delete(tempfilename)
