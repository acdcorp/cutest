class Cutest
  module Database
    extend self

    module Helper
      require 'active_record'

      extend ActiveSupport::Concern

      private

      def factory *attrs
        attrs.each do |key, value|
          if key.is_a? Hash
            key.each do |k, v|
              send("#{k}=", v) unless send("#{k}").present?
            end
          else
            send("#{key}=", value) unless send("#{key}").present?
          end
        end

        if respond_to?(:creator_id) and not creator_id
          self.creator_id = Cutest.config.creator_id
        end

        if respond_to?(:updater_id) and not updater_id
          self.updater_id = Cutest.config.updater_id
        end
      end
    end

    def reset
      connect

      ignore_tables = %w(schema_migrations)

      if config.key? :ignore_tables
        ignore_tables.concat config[:ignore_tables]
      end

      conn   = ActiveRecord::Base.connection
      tables = conn.execute("show tables").map { |r| r[0]  }

      tables.each do |t|
        unless ignore_tables.include? t
          conn.execute("SET FOREIGN_KEY_CHECKS = 0")
          conn.execute("TRUNCATE #{t}")
          conn.execute("SET FOREIGN_KEY_CHECKS = 1")
        end
      end
    end

    def connect
      return if ActiveRecord::Base.connected?

      ActiveRecord::Base.default_timezone = Time.zone

      db = URI.parse config[:url]

      ActiveRecord::Base.establish_connection(
          adapter:      db.scheme == 'postgres' ? 'postgresql' : db.scheme,
          encoding:     'utf8',
          reconnect:    true,
          database:     db.path[1..-1],
          host:         db.host,
          port:         db.port,
          username:     db.user,
          password:     db.password,
      )
    end

    def config
      Cutest.config.database
    end
  end
end

ActiveRecord::Base.send :include, Cutest::Database::Helper
