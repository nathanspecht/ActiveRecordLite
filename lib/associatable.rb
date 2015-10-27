require_relative 'searchable'
require 'active_support/inflector'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions

  def initialize(name, options = {})
    #if options given
    self.foreign_key = options[:foreign_key]
    self.primary_key = options[:primary_key]
    self.class_name  = options[:class_name]

    #defaults
    self.foreign_key ||= "#{name}_id".to_sym
    self.primary_key ||= :id
    self.class_name  ||= name.to_s.camelcase.singularize
  end
end

class HasManyOptions < AssocOptions

  def initialize(name, self_class_name, options = {})
    #if options given
    self.foreign_key = options[:foreign_key]
    self.primary_key = options[:primary_key]
    self.class_name  = options[:class_name]

    #defaults
    self.foreign_key ||= "#{self_class_name.underscore}_id".to_sym
    self.primary_key ||= :id
    self.class_name  ||= name.to_s.camelcase.singularize
  end
end

module Associatable

  def assoc_options
    @assoc_options ||= {}
  end

  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    self.assoc_options[name] = options

    define_method "#{name}" do
      foreign_key_value  = self.send "#{options.foreign_key}"
      target_model_class = options.model_class

      target_model_class.where(options.primary_key => foreign_key_value).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)

    define_method "#{name}" do
      primary_key_value = self.send "#{options.primary_key}"
      target_model_class = options.model_class

      target_model_class.where(options.foreign_key => primary_key_value)
    end
  end

  def has_one_through(name, through_name, source_name)
    define_method "#{name}" do

      through_options = self.class.assoc_options[through_name]
      source_options  =
        through_options.model_class.assoc_options[source_name]

      source_table = source_options.table_name
      through_table = through_options.table_name

      result = DBConnection.execute(<<-SQL, self.send(through_options.foreign_key)).first
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{through_table}.#{source_options.foreign_key} = #{source_table}.#{source_options.primary_key}
        WHERE
          #{through_table}.#{source_options.primary_key} = ?
      SQL

      source_options.model_class.parse_all([result]).first
    end
  end
end

class SQLObject
  extend Associatable
end
