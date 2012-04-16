require "active_import"
require "colorize"

def process_import_options
  converter = ENV["converter"] || ENV["CONVERTER"]
  converter_model = "#{converter.camelize}Converter"
  options = ENV["converter_options"] || ENV["CONVERTER_OPTIONS"]
  converter_options = ActiveImport.process_converter_options options

  puts "Converter Model: #{converter_model.cyan}"
  puts "Converter Options: #{converter_options.to_s.cyan}"
  file = ENV["file"] || ENV["FILE"]
  file ||= "#{converter.underscore}.csv"
  data_file = ActiveImport.import_file_with_path file

  if File.exists?(data_file)
    puts "Found import file: #{data_file}".green
  else
    puts "File doesn't exist': #{data_file}".red
  end
  model_converter = eval("#{converter_model}.new")
  model_converter.options = converter_options

  return {:data_file => data_file, :model_converter => model_converter}
end

namespace :active_import do
  desc "Load csv file into a model using a model converter"
  task :csv => :environment do
    result = process_import_options
    unless result[:data_file].nil?
      import = ActiveImport::ImportCsv.new(result[:model_converter], result[:data_file])
      ActiveImport.parse(import, result[:model_converter])
    end
  end
  desc "Load excel file into a model using a model converter"
  task :excel => :environment do
    result = process_import_options
    unless result[:data_file].nil?
      import = ActiveImport::ImportExcel.new(result[:model_converter], result[:data_file])
      ActiveImport.parse(import, result[:model_converter])
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
