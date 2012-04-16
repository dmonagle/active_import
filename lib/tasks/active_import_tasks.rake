require "active_import"
require "colorize"

def import_file_with_path file
  f = file.strip
  unless /^\//.match(f)
    f = File.join(Rails.root, "db", "active_import", f)
  end
  f
end

def process_converter_options options_string
  converter_options = {}
  if options_string
    options = options_string.split(";")
    options.each do |option|
      s = option.split("=")
      converter_options[s[0].strip] = s[1].strip
    end
  end
  converter_options
end

def process_import_options
  converter = ENV["converter"] || ENV["CONVERTER"]
  converter_model = "#{converter.camelize}Converter"
  options = ENV["converter_options"] || ENV["CONVERTER_OPTIONS"]
  converter_options = process_converter_options options

  puts "Converter Model: #{converter_model.cyan}"
  puts "Converter Options: #{converter_options.to_s.cyan}"
  file = ENV["file"] || ENV["FILE"]
  file ||= "#{converter.underscore}.csv"
  data_file = import_file_with_path file

  if File.exists?(data_file)
    puts "Found import file: #{data_file}".green
  else
    puts "File doesn't exist': #{data_file}".red
  end
  model_converter = eval("#{converter_model}.new")
  model_converter.options = converter_options

  return {:data_file => data_file, :model_converter => model_converter}
end

def parse(import, model_converter)
  model_converter.before
  import.parse do |import_row, converter, row_number, total_rows|
    model_converter.process_values import_row
    model = model_converter.save
    if model.respond_to?("errors")
      print "#{row_number.to_s.cyan}: "
      if model.errors.empty?
        puts "OK".green
      else
        model.errors.full_messages.each { |message| puts message.red }
      end
    end
  end
  model_converter.after
  puts model_converter.report
end

def seed_from_file(seed_file_name)
end

namespace :active_import do
  desc "Load csv file into a model using a model converter"
  task :csv => :environment do
    result = process_import_options
    unless result[:data_file].nil?
      import = ActiveImport::ImportCsv.new(result[:model_converter], result[:data_file])
      parse(import, result[:model_converter])
    end
  end
  desc "Load excel file into a model using a model converter"
  task :excel => :environment do
    result = process_import_options
    unless result[:data_file].nil?
      import = ActiveImport::ImportExcel.new(result[:model_converter], result[:data_file])
      parse(import, result[:model_converter])
    end
  end
  desc "Seed a list of import files"
  task :seed => :environment do
    set = ENV["set"] || ENV["SET"] || ::Rails.env
    seed_file_name = File.join(Rails.root, "db", "active_import", "#{set}.seed")
    if File.exists?(seed_file_name)
      puts "Seeding from file: '#{seed_file_name.yellow}'"
      ActiveImport::Seed.seed_from_file seed_file_name
    else
      puts "Cannot find seed file: '#{seed_file_name}'".red
    end
  end
end
