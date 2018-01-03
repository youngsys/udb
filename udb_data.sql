USE udbGit
GO


INSERT INTO "Realm" VALUES ('A test client')		-- 1


INSERT INTO "Category" (
	"categoryName",
	"fkRealm",
	"fkParentCategory"
) VALUES 
	('Corporate Structure', 1, NULL),		--1
		('Geography',1,1),					--2
		('Staff',1,1),						--3
			('Blah',1,3),					--4
	('Operations',1,NULL),					--5
		('Workflow',1,5),					--6
		('Projects',1,5)					--7


INSERT INTO "Entity" (
	"entityName",
	"fkRealm"
) VALUES
	('Client',1),							--1
	('Division',1),							--2
	('Project',1)							--3


INSERT INTO "Relation" (
	"relationName", 
	"isNullable", 
	"cardinality", 
	"fkPrimaryEntity", 
	"fkForeignEntity"
) VALUES
	('fkClient','N','N',1,2)				--1
,	('fkParentDivision','Y','N',2,2)		--2
,	('fkDivision','N','N',2,3)				--3


INSERT INTO "EntityInstance" (
	fkEntity
,	attribJson
) VALUES
	(1,'{"name":"A test client"}')					--1
,	(2,'{"name":"A division","relations":{"fkClient":1}}')		--2
,	(3,'{"name":"A project","relations":{"fkDivision":2}}')		--3


return

