require_relative 'db_connection'
require 'active_support/inflector'

class SQLObject
  def self.columns
    column_names = DBConnection.execute2(<<-SQL)[0]
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    column_names.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column_sym|
      define_method column_sym do
         attributes[column_sym]
      end

      define_method "#{column_sym.to_s}=" do |val|
        attributes[column_sym] = val
        @attributes = attributes
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id: id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = :id
    SQL

    self.parse_all(result).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_sym = attr_name.to_sym

      unless self.class.columns.include?(attr_sym)
        fail "unknown attribute '#{attr_name}'"
      end

      send "#{attr_sym}=", value
    end
  end

  def attributes
    @attributes ||= { }
  end

  def attribute_values
    self.class.columns.map { |column| send "#{column}" }
  end

  def insert
    col_names = self.class.columns.join(", ")

    n = attribute_values.length

    question_marks = (["?"] * n).join(", ")

    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    id = DBConnection.last_insert_row_id
    self.id = id
  end

  def update
    set_columns = self.class.columns.map do |attr_name|
      "#{attr_name} = ?"
    end.join(", ")
    DBConnection.execute(<<-SQL, attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_columns}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
