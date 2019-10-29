require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      source_table = source_options.table_name

      f_key = through_options.foreign_key
      p_key = through_options.primary_key
      through_id = self.send(f_key)

      join_f_key = source_options.foreign_key
      join_p_key = source_options.primary_key
      
      query = <<-SQL
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{through_table}.#{join_f_key}
                            = #{source_table}.#{join_p_key}
        WHERE
          #{through_table}.#{p_key} = ?
      SQL

      rows = DBConnection.execute(query, through_id)
      source_options.model_class.new(rows.first)
    end

  end
end
