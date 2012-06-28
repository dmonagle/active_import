module ActiveImport
  class ModelConverter
    attr_accessor :options, :columns
    # TODO: columns should be a reader only once old code has been fixed up
    attr_reader :converted_values, :raw_values

    def initialize
      @columns = {}
      setup
    end

    def setup
    end

    def add_column column_name, options
      @columns[column_name] = options
    end

    def before
    end

    def after
    end

    def print_columns
      @columns.each_pair do |name, column|
        puts name
      end
    end

    def csv_headers()
      selected_columns = @columns

      [].tap do |o|
        selected_columns.each_value do |column|
          o << (column[:header] || column[:match])
        end
      end.to_csv.html_safe
    end

    def csv_values(values)
      selected_columns = @columns

      [].tap do |o|
        selected_columns.each_key do |column|
          o << values[column]
        end
      end.to_csv.html_safe
    end

    def process_values(values)
      @raw_values = values
      @converted_values = convert_attributes(values)
    end

    def remove_nil_from_converted_values
      @converted_values.delete_if { |k, v| v.nil? }
    end

    def remove_blank_from_converted_values
      @converted_values.delete_if { |k, v| v.to_s.blank? }
    end

    def convert_attributes(values)
      cv = {}
      @columns.each_pair do |name, column|
        cv[name] = convert_attribute(name, values)
      end
      cv
    end

    def convert_string(value)
      value = value.to_i if (value.to_i == value.to_f) if /^\s*[\d]+(\.0+){0,1}\s*$/.match(value.to_s)
      return nil if value.to_s.blank? || value.to_s.nil?
      value.to_s
    end

    def convert_clean_string(value)
      value = value.to_i if (value.to_i == value.to_f) if /^\s*[\d]+(\.0+){0,1}\s*$/.match(value.to_s)
      value = value.gsub(/[^A-Za-z0-9 \.,\?'""!@#\$%\^&\*\(\)-_=\+;:<>\/\\\|\}\{\[\]`~]/, '').strip if value.is_a?(String)
      return nil if value.to_s.blank? || value.to_s.nil?
      value.to_s
    end

    def convert_boolean value
      /^y|t/.match(value.strip.downcase) ? true : false
    end

    def convert_date s
      return nil if (s.nil? || s.blank?)
      return Date.strptime(s, "%d/%m/%y") if /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2}$/.match(s)
      return DateTime.new(1899,12,30) + s.to_f if s.to_f unless s !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
      begin
      result = Date.parse(s)
      rescue
        puts "Could not parse date ".red + "'#{s}'"
      end

      return result
    end

    def report
      ""
    end

    private

    def convert_attribute(attribute, values)
      return nil if values[attribute].nil?
      conversion_function = "convert_#{columns[attribute][:type].to_s}"
      value = values[attribute]
      if self.respond_to? conversion_function
        value = eval("#{conversion_function} value")
      end
      value
    end


  end
end