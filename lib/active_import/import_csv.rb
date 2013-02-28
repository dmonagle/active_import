require 'iconv' unless String.method_defined?(:encode)

module ActiveImport
  if RUBY_VERSION =~ /^1.9/
    require 'csv'
  else
    require 'fastercsv'
  end

  class ImportCsv
    attr_reader :data_file, :converter, :estimated_rows

    def initialize(model_converter, data_file)
      @converter = model_converter
      @data_file = data_file
    end

    def all_headers_found(headers)
      mappings = @converter.columns

      @missing_headers_mandatory = []
      @missing_headers_optional = []
      found_at_least_one = false

      mappings.each_pair do |column_name, mapping|
        if headers[column_name].nil?
          if mapping[:mandatory]
            @missing_headers_mandatory << column_name
          else
            @missing_headers_optional << column_name
          end
        else
          found_at_least_one = true
        end
      end
      if found_at_least_one
        @missing_headers_optional.each { |field| puts "Missing optional column #{field}".yellow }
        @missing_headers_mandatory.each { |field| puts "Missing mandatory column #{field}".red }
      end
      return false unless @missing_headers_mandatory.empty?
      true
    end

    def parse(&block)
      column_mappings = @converter.columns

      headers = {}
      header = true
      data_count = 0
      row_number = 0
      csv_class = nil
      if RUBY_VERSION =~ /^1.9/
        csv_class = CSV
        puts "Using built in Ruby 1.9 CSV parser".cyan
      else
        csv_class = FasterCSV
        puts "Using FasterCSV parser".cyan
      end

      # Get an estimate of the number of rows in the file
      puts @data_file.to_s.yellow
      @estimated_rows = csv_class.read(@data_file).length - 1
      puts "Estimated Rows: #{@estimated_rows}".magenta

      csv_class.foreach(@data_file, {:encoding => 'windows-1251:utf-8'}) do |row|
        row_number += 1
        if (header)
          column = 0
          row.each do |column_value|
            column += 1
            column_mappings.each do |column_name, mapping|
              match = mapping[:match] || mapping[:header]
              if /#{match}/.match(column_value)
                puts "Found header for #{column_name} at column #{column}".green
                if (headers[column_name].nil?)
                  headers[column_name] = column
                else
                  puts "Found duplicate header '#{column_name}' on columns #{column} and #{headers[column_name]}.".red
                end
              end
            end
          end
          unless all_headers_found(headers)
            puts "Missing headers".red
            break
          end
          header = false
        else
          import_row = {}
          headers.each_pair do |name, column|
            value = row[column - 1].to_s
            import_row[name] = value
          end
          data_count += 1
          yield import_row, @converter, row_number, @estimated_rows
        end
      end
      puts "Imported #{data_count} rows".cyan
    end
  end
end