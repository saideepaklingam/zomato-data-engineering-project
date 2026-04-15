/* Database Creation */
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ZomatoDB')
    CREATE DATABASE ZomatoDB

USE ZomatoDB

/* Schemas 
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze') EXEC('CREATE SCHEMA bronze')
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver') EXEC('CREATE SCHEMA silver')
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')   EXEC('CREATE SCHEMA gold')


SELECT name FROM sys.schemas WHERE name IN ('bronze','silver','gold')