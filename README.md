# ActiveRecordLite
Active Record Lite (ARL) is an object-relational mapping system inspired by
Active Record. ARL uses Ruby's metaprogramming capabilities to implement its
core functionality.

## Current Features
- `SQLObject::find(id)` returns SQLObject of row with matching id
- `SQLObject#insert` creates new row in the database with current attributes and assigns an id
- `SQLObject#update` maps current attribute values over previous values in the database
- `SQLObject#save` inserts or updates SQLObject based on `id.nil?`
- `SQLObject#where(params)` forms and executes SQL query based on params, returns an array of SQLObjects
- `SQLObject#belongs_to(name, options)` defines a method, `name`, that returns a SQLObject whose `AssocOptions#model_name` and `:primary_key` value correspond to the `:class_name` option and `:foreign_key` value of the association
- `SQLObject#has_many(name, options)` is the inverse of `#belongs_to`; returns an array of SQLObjects with appropriate `:class_name` options and `:foreign_key` values
- `SQLObject#has_one_through(name, through_name, source_name)` defines a relationship between two SQLObjects through two `#belongs_to` relationships. Returns a SQLObject whose `#model_name` corresponds to the `source_name`

## Using ActiveRecordLite
