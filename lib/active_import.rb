require "active_import/import_csv"
require "active_import/import_excel"
require 'active_import/model_converter'
require 'active_import/seed'

module ActiveImport
  class Railtie < ::Rails::Railtie
    railtie_name :active_import

    rake_tasks do
      load "tasks/active_import_tasks.rake"
    end
  end
end
