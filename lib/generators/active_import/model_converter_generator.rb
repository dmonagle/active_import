require 'rails/generators'

module ActiveImport
  module Generators
    class ModelConverterGenerator < Rails::Generators::NamedBase
      class_option :converter_name, :type => :string, :default => nil, :desc => "Names the converter file, defaults to the model name"

      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      def create_files
        Dir.mkdir("app/model_converters") unless File.directory?("app/model_converters")
        @model_name = file_name
        @class_name = class_name
        @model =  eval(@class_name)
        @attributes = @model.attribute_names
        @converter_name = options.converter_name || @class_name
        template 'model_converter.rb.erb', "app/model_converters/#{@converter_name.underscore}_converter.rb"
        Dir.mkdir("db/active_import") unless File.directory?("db/active_import")
        template 'data.csv.erb', "db/active_import/#{@converter_name.underscore}.csv"
      end
    end
  end
end
