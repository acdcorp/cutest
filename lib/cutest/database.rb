if defined? Sequel
  require_relative 'database/sequel_driver'
  require_relative 'database/sequel_factories'
elsif defined? ActiveRecord
  require_relative 'database/activerecord_driver'
end
