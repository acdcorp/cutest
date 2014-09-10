class Cutest
  module Database
    extend self

    def reset database = false, options = {}
      db = connect database

      c = config.merge options

      ignore_tables = %w(schema_migrations)

      if c.key? :ignore_tables
        ignore_tables.concat c[:ignore_tables]
      end

      db.tables.each do |t|
        unless ignore_tables.include? t
          db.run("SET FOREIGN_KEY_CHECKS = 0")
          db.run("TRUNCATE #{t}")
          db.run("SET FOREIGN_KEY_CHECKS = 1")
        end
      end
    end

    def connect database = false
      @db ||= Sequel.connect database || config[:url]
    end

    def config
      Cutest.config.database.clone
    end
  end
end
