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
  seed_file = File.open(seed_file_name, "r")
  seed_file.each_line do |seed_line|
    unless (/^#/.match(seed_line))
      seed_info = seed_line.split("|")
      data_file_name = seed_info[0]
      converter_name = seed_info[1]

      unless data_file_name.nil? || converter_name.nil?
        data_file_name = import_file_with_path data_file_name

        if (File.exists? data_file_name)
          converter_name.strip!
          converter_options = process_converter_options seed_info[2]

          puts "Importing from: #{data_file_name.cyan}"
          puts "Using converter: #{converter_name.cyan}"
          puts "Options: #{converter_options.to_s.cyan}"

          model_converter = eval("#{converter_name.camelize}Converter.new")
          model_converter.options = converter_options

          import = nil
          extension = File.extname(data_file_name).downcase.strip
          case extension
            when ".xls"
              puts "Excel file detected".yellow
              import = ActiveImport::ImportExcel.new(model_converter, data_file_name)
            when ".xlsx"
              puts "Excel(X) file detected".yellow
              import = ActiveImport::ImportExcel.new(model_converter, data_file_name)
            when ".csv"
              puts "CSV file detected".yellow
              import = ActiveImport::ImportCsv.new(model_converter, data_file_name)
            else
              puts "File type cannot be processed".red
          end
          parse(import, model_converter) unless import.nil?
        else
          puts "Skipping non existing file: #{data_file_name}".red
        end
      end
    end
  end
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
      seed_from_file seed_file_name
    else
      puts "Cannot find seed file: '#{seed_file_name}'".red
    end
  end
end
