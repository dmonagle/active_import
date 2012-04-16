module ActiveImport
  def self.import_file_with_path file
    f = file.strip
    unless /^\//.match(f)
      f = File.join(Rails.root, "db", "active_import", f)
    end
    f
  end

  def self.process_converter_options options_string
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

  def self.parse(import, model_converter)
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
end