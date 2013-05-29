Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_sisow_settings_to_configurations_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :partial => "spree/admin/shared/configurations_menu_sisow",
                     :disabled => false)