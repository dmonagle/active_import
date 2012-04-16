module ActiveImport
  class Seed

    def self.seed_from_file seed_file_name
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
  end
end
