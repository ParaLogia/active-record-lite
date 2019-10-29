require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    conditions = params.keys.map do |attr|
      "#{attr} = ?"
    end
    conditions = conditions.join(" AND ")

    query = <<-SQL
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{conditions}
    SQL

    rows = DBConnection.execute(query, *params.values)
    self.parse_all(rows)
  end
end

class SQLObject
  extend Searchable
end
