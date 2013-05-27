module SpreeBillingSisow
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, :type => :boolean, :default => false

      def add_javascripts
        append_file 'app/assets/javascripts/store/all.js', "//= require store/spree_billing_sisow\n"
        append_file 'app/assets/javascripts/admin/all.js', "//= require admin/spree_billing_sisow\n"
      end

      def add_stylesheets
        inject_into_file 'app/assets/stylesheets/store/all.css', " *= require store/spree_billing_sisow\n", :before => /\*\//, :verbose => true
        inject_into_file 'app/assets/stylesheets/admin/all.css', " *= require admin/spree_billing_sisow\n", :before => /\*\//, :verbose => true
      end

      def add_sisow_configuration
        initializer("sisow.rb") do
          "Sisow.configure do |config|\n  config.merchant_key = 'your-merchant-key'\n  config.merchant_id  = 'your-merchant-id'\n  config.test_mode    = false   # default: false\n  config.debug_mode   = false   # default: false\nend"
        end
        puts "Don't forget to configure Sisow in config/initializers/sisow.rb"
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_billing_sisow'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
