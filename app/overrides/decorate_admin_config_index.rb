Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "amazon_payments_configuration_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text => "<%= configurations_sidebar_menu_item 'Amazon Payments', admin_amazon_payments_settings_path %>",
                     :disabled => false)