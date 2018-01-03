# udb
Dynamic Universal Database for jSon(/xml)

This is an example of a dynamic database structure for use in workflow applications where ad hoc storage can be defined and become 
instantly available for use without database structure changes.

Instead of tables, create entities in the Entity table. Instead of declarative relational integrity, describe the relations in the 
Relation table.

Records "live" in the EntityInstance table, and the database trigger reads its attribJson field to create/maintain records in the
"RelationInstance" table from the data in the "relations" node in the jSon data.

The beauty is that the attributes are defined within the jSon structure, but relational integrity is still maintained.

This example code works in SQL Server 2016.
