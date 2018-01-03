USE [udbGit]
SET NOCOUNT ON
set xact_abort on


CREATE TABLE "Realm" (
	"pkRealm"		INT IDENTITY,
	"realmName"		VARCHAR(100) NOT NULL
,	CONSTRAINT "PKRealm"  PRIMARY KEY CLUSTERED ("pkRealm")
)

CREATE TABLE "Category" (
	"pkCategory"			INT IDENTITY
,	"categoryName"			VARCHAR(100) NOT NULL
,	"fkRealm"				INT NOT NULL CONSTRAINT "FK_Category_Realm" REFERENCES "Realm" ("pkRealm")
,	"fkParentCategory"		INT NULL CONSTRAINT "FK_Category_Category" REFERENCES "Category" ("pkCategory")
,	CONSTRAINT "PKCategory"  PRIMARY KEY CLUSTERED ("pkCategory")
)

CREATE TABLE "Entity" (
	"pkEntity"			INT IDENTITY
,	"entityName"		VARCHAR(100) NOT NULL
,	"fkRealm"			INT NOT NULL CONSTRAINT "FK_Entity_Realm" REFERENCES "Realm" ("pkRealm")
,	CONSTRAINT "PKEntity"  PRIMARY KEY CLUSTERED ("pkEntity")
)

CREATE TABLE "EntityCategory" (
	"pkEntityCategory"	INT IDENTITY
,	"fkCategory"		INT NOT NULL CONSTRAINT "FK_EntityType_Category" REFERENCES "Category" ("pkCategory")
,	"fkEntity"			INT NULL CONSTRAINT "FK_EntityCategory_Entity" REFERENCES "Entity" ("pkEntity")
,	CONSTRAINT "PKEntityCategory"  PRIMARY KEY CLUSTERED ("pkEntityCategory")
)

CREATE TABLE "Relation" (
	"pkRelation"		INT IDENTITY
,	"relationName"		NVARCHAR(100) COLLATE Latin1_General_BIN2 NOT NULL 
,	"isNullable"		CHAR(1)									-- Y/N
,	"cardinality"		CHAR(1)									-- 1/N
,	"fkPrimaryEntity"	INT NOT NULL CONSTRAINT "FK_Relation_Entity" REFERENCES "Entity" ("pkEntity")
,	"fkForeignEntity"	INT NOT NULL CONSTRAINT "FK_Relation_TargetEntity" REFERENCES "Entity" ("pkEntity")
,	CONSTRAINT "PKRelation"  PRIMARY KEY CLUSTERED ("pkRelation")
)

CREATE TABLE "EntityInstance" (
	"pkEntityInstance"		INT IDENTITY
,	"attribJson"		VARCHAR(MAX) NULL
,	"fkEntity"			INT NOT NULL CONSTRAINT "FK_EntityInstance_Entity" REFERENCES "Entity" ("pkEntity")
,	CONSTRAINT "PKEntityInstance"  PRIMARY KEY CLUSTERED ("pkEntityInstance")
)

CREATE TABLE "RelationInstance" (
	"fkRelation"				INT NOT NULL CONSTRAINT "FK_RelationInstance_Relation" REFERENCES "Relation" ("pkRelation")
,	"fkForeignEntityInstance"	INT NOT NULL CONSTRAINT "FK_RelationInstance_ForeignEntity" REFERENCES "EntityInstance" ("pkEntityInstance") ON DELETE CASCADE
,	"fkPrimaryEntityInstance"	INT NOT NULL CONSTRAINT "FK_RelationInstance_PrimaryEntity" REFERENCES "EntityInstance" ("pkEntityInstance")
,	CONSTRAINT "PKRelationInstance"  PRIMARY KEY CLUSTERED ("fkForeignEntityInstance", "fkPrimaryEntityInstance")
)

GO

-------------------------------------------------------

CREATE TRIGGER "trgEntityInstance"
   ON  "EntityInstance"
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

	;WITH src AS (	
				SELECT	fk."fkRelation"
				,		fk."fkForeignEntityInstance"
				,		pk."fkPrimaryEntityInstance"
				FROM	(	SELECT	ins."pkEntityInstance" AS "fkForeignEntityInstance"
							,		ins."attribJson"
							,		ins."fkEntity" AS "fkForeignEntity"
							,		rel."fkPrimaryEntity"
							,		rel."pkRelation" AS "fkRelation"
							,		rel."relationName"
							,		rel."isNullable"
							FROM	inserted ins
							JOIN	"Relation" rel
							ON		rel."fkForeignEntity" = ins."fkEntity"
						) fk
				LEFT	JOIN (
							SELECT	ins."pkEntityInstance" AS "fkForeignEntityInstance"
							,		pk."pkEntityInstance" AS "fkPrimaryEntityInstance"
							,		ins."fkEntity" AS "fkForeignEntity"
							,		pk."fkEntity" AS "fkPrimaryEntity"
							,		er."key" AS "relationName"
							FROM	inserted ins
							CROSS	APPLY OPENJSON(ins."attribJson", '$.relations') er
							JOIN	"EntityInstance" pk
							ON		pk."pkEntityInstance" = er."value"
						) pk
				ON		pk."fkForeignEntity" = fk."fkForeignEntity"
				AND		pk."fkPrimaryEntity" = fk."fkPrimaryEntity"
				AND		pk."relationName" = fk."relationName"
				WHERE	pk."fkPrimaryEntityInstance" IS NOT NULL
				OR		fk."isNullable" = 'N'
			) 
	MERGE	INTO "RelationInstance" AS tgt USING src
	ON		tgt."fkForeignEntityInstance" = src."fkForeignEntityInstance"
	AND		tgt."fkPrimaryEntityInstance" = src."fkPrimaryEntityInstance"
	WHEN	NOT MATCHED THEN INSERT ( "fkRelation", "fkForeignEntityInstance", "fkPrimaryEntityInstance")
			VALUES (src."fkRelation", src."fkForeignEntityInstance", src."fkPrimaryEntityInstance")
	WHEN	NOT MATCHED BY SOURCE THEN DELETE;

END

GO