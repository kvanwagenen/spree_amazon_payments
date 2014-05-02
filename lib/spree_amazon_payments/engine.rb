module SpreeAmazonPayments
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_amazon_payments'

    config.autoload_paths += %W(#{config.root}/lib)

    initializer "spree.amazon_payments.environment", :before => :load_config_initializers do |app|
      Spree::AmazonPayments::Config = Spree::AmazonPaymentsConfiguration.new
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
