require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns

    query = <<-SQL
      SELECT 
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL

    rows = DBConnection.execute2(query)
    @columns = rows.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col_name|
      define_method(col_name) do
        self.attributes[col_name]
      end

      define_method("#{col_name}=") do |val|
        self.attributes[col_name] = val
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
    query = <<-SQL
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    rows = DBConnection.execute(query)
    self.parse_all(rows)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    query = <<-SQL
      SELECT
        *
      FROM 
        #{self.table_name}
      WHERE
        id = ?
      LIMIT 1
    SQL
    rows = DBConnection.execute(query, id)
    return nil if rows.empty?
    self.new(rows.first)
  end

  def initialize(params = {})
    columns = self.class.columns
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      unless columns.include?(attr_name)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values(with_id=true)
    columns = self.class.columns.reject do |col|  
      col == :id unless with_id 
    end
    columns.map do |col_name|
      self.send(col_name)
    end
  end

  def insert
    table_name = self.class.table_name
    columns = self.class.columns.reject { |col| col == :id }
    col_names = columns.join(", ")
    question_marks = (['?'] * columns.length).join(", ")
    query = <<-SQL
      INSERT INTO
        #{table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    attr_vals = self.attribute_values(false)
    DBConnection.execute(query, *attr_vals)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    table_name = self.class.table_name
    columns = self.class.columns.reject { |col| col == :id }
    col_exprs = columns.map { |col| "#{col} = ?" }.join(", ")

    query = <<-SQL
      UPDATE
        #{table_name}
      SET 
        #{col_exprs}
      WHERE
        id = ?
    SQL

    attr_vals = self.attribute_values(false)
    DBConnection.execute(query, *attr_vals, id)
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
