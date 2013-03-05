module ActiveImport
  require "roo"
  require 'iconv' unless String.method_defined?(:encode)

  class ImportExcel
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
        @missing_headers_optional.each { |field| puts "Missing optional column #{field.to_s.yellow}" }
        @missing_headers_mandatory.each { |field| puts "Missing mandatory column #{field.to_s.red}" }
      end
      return false unless @missing_headers_mandatory.empty?
      true
    end

    def find_excel_header_row(e)
      column_mappings = @converter.columns

      e.sheets.each do |sheet|
        puts "Looking for the header row in sheet #{sheet}".cyan
        e.default_sheet = sheet
        e.first_row.upto(e.last_row) do |row|
          headers = {}
          (e.first_column..e.last_column).each do |column|
            column_mappings.each do |column_name, mapping|
              match = mapping[:match] || mapping[:header]
              if /#{match}/.match(e.cell(row, column).to_s)
                puts "Found header for #{column_name.to_s.green} at column #{column} at row #{row}"
                if (headers[column_name].nil?)
                  headers[column_name] = column
                else
                  puts "Found duplicate header '#{column_name.to_s.red}' on columns #{column} and #{headers[column_name]}."
                end
              end
            end
          end

          if all_headers_found(headers)
            puts "All headers found on row #{row}".green
            return {:row => row, :sheet => sheet, :headers => headers}
          end
        end
      end
      return nil
    end

    def parse(&block)
      column_mappings = @converter.columns

      excelx = false
      case File.extname(data_file).downcase
        when ".xls"
          e = Roo::Excel.new(data_file)
        when ".xlsx"
          excelx = true
          e = Roo::Excelx.new(data_file)
      end

      result = find_excel_header_row(e)

      if result.nil?
        puts "Could not find header row.".red
        return
      end

      e.default_sheet = result[:sheet]
      header_row = result[:row]
      headers = result[:headers]

      # Loop through the data
      puts "Reading data from row #{header_row + 1} to #{e.last_row}"
      @estimated_rows = e.last_row - header_row;
      row_number = 0
      (header_row + 1).upto(e.last_row) do |row|
        row_number += 1
        import_row = {}
        headers.each_pair do |name, column|
          if excelx
            value = e.cell(row, column).to_s
          else
            value = e.cell(row, column).to_s
          end
          import_row[name] = value
        end
        yield import_row, @converter, row_number, @estimated_rows
      end
    end
  end
end