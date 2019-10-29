require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
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
    self.model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]

    @class_name ||= name.to_s.camelize
    @foreign_key ||= "#{name}_id".intern
    @primary_key ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]

    @class_name ||= name.to_s.singularize.camelize
    @foreign_key ||= "#{self_class_name.underscore}_id".intern
    @primary_key ||= :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    self.assoc_options[name] = options
    define_method(name) do 
      f_key, p_key = options.foreign_key, options.primary_key
      id = self.send(f_key)
      model_class = options.model_class
      matching = model_class.where(id: id)
      matching.first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.to_s, options)
    define_method(name) do 
      f_key, p_key = options.foreign_key, options.primary_key
      id = self.send(p_key)
      model_class = options.model_class
      model_class.where(f_key => id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
