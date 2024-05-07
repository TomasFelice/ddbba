use pruebasddbba
go

drop table if exists ddbba.cliente
go

CREATE TABLE ddbba.cliente (
    ID [int]	IDENTITY(1,1) NOT NULL,
    Documento	varchar(20) NOT NULL,
    Nombre		varchar(50) NOT NULL,
    Direccion	varchar(50)  NULL,
    Ocupacion	varchar(50) NOT NULL,
 CONSTRAINT ClientesPK PRIMARY KEY (Id)
)
GO

/* Este archivo guardelo como "clientes.xml" 

<?xml version="1.0" encoding="utf-8"?>
<Clientes>
  <Cliente>
    <Documento>300 000 000</Documento>
    <Nombre>Ponzio</Nombre>
    <Direccion>Belgrano 2011</Direccion>
    <Ocupacion>Sufridor</Ocupacion>
  </Cliente>
  <Cliente>
    <Documento>300 000 001</Documento>
    <Nombre>JJ Lopez</Nombre>
    <Direccion>Belgrano 0626</Direccion>
    <Ocupacion>Conductor</Ocupacion>
  </Cliente>
  <Cliente>
    <Documento>300 000 002</Documento>
    <Nombre>Sanfilippo Jose</Nombre>
    <Direccion>Almagro</Direccion>
    <Ocupacion>Cajero</Ocupacion>
  </Cliente>
  <Cliente>
    <Documento>300 000 003</Documento>
    <Nombre>Pipi Romagnoli</Nombre>
    <Direccion>Boedo</Direccion>
    <Ocupacion>Repositor</Ocupacion>
  </Cliente>
  <Cliente>
    <Documento>300 000 004</Documento>
    <Nombre>Ruben Insua</Nombre>
    <Direccion>Flores</Direccion>
    <Ocupacion>Responsable At. al cliente</Ocupacion>
  </Cliente>
</Clientes>

*/

-- Primer opción: cargar el archivo en una tabla

INSERT INTO ddbba.Cliente (documento, nombre, direccion, Ocupacion)
	SELECT
	   XMLClientes.Cliente.query('Documento').value('.', 'VARCHAR(20)'),
	   XMLClientes.Cliente.query('Nombre').value('.', 'VARCHAR(50)'),
	   XMLClientes.Cliente.query('Direccion').value('.', 'VARCHAR(50)'),
	   XMLClientes.Cliente.query('Ocupacion').value('.', 'VARCHAR(50)')
	FROM (SELECT CAST(XMLClientes AS xml)
		  FROM OPENROWSET(BULK 'C:\pruebas\clientes.xml', SINGLE_BLOB) AS T(XMLClientes)) AS T(XMLClientes)
		  CROSS APPLY XMLClientes.nodes('Clientes/Cliente') AS XMLClientes (Cliente);


-- Otra forma
-- Vamos a cargar el XML como cadena en una tabla primero (observe el tipo de dato XML)

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'XMLCrudo' AND TABLE_SCHEMA = 'ddbba')
   DROP TABLE ddbba.XMLCrudo;

-- podes leer sobre varias formas de verificar si existe una tabla (u objeto) antes de borrarlo aqui:
-- https://www.mssqltips.com/sqlservertip/6769/sql-server-drop-table-if-exists/

CREATE TABLE ddbba.XMLCrudo
(
	Id INT IDENTITY PRIMARY KEY,
	XMLData XML,
	FechaHoraCarga DATETIME	-- Solo informativo
)

INSERT INTO ddbba.XMLCrudo(XMLData, FechaHoraCarga)
	SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE() 
	FROM OPENROWSET(BULK 'C:\pruebas\Clientes.xml', SINGLE_BLOB)  x;

-- (1) a partir de aqui ejecutamos en bloque
DECLARE @XML AS XML, 
	@hDoc AS INT, 
	@SQL NVARCHAR (MAX)

SELECT @XML = XMLData 
			FROM ddbba.XMLCrudo

-- Se almacena en una cache interna (ver que luego se debe liberar)
EXEC sp_xml_preparedocument @hDoc OUTPUT, @XML
-- Observar que la variable @hDoc es un handle, y se utilizó como variable de salida en la llamada al SP
-- OpenXML es una función utilizada en el FROM.
SELECT *
FROM OPENXML(@hDoc, 'Clientes/Cliente')
WITH 
(
	Documento [varchar](50) 'Documento',
	Nombre [varchar](100) 'Nombre',
	Direccion [varchar](100) 'Direccion',
	Ocupacion [varchar](100) 'Ocupacion'
)
-- liberamos la memoria usada
EXEC sp_xml_removedocument @hDoc
--- (1) hasta aqui



/*
mas info en
https://www.red-gate.com/simple-talk/databases/sql-server/learn/using-the-for-xml-clause-to-return-query-results-as-xml/
https://www.sqlshack.com/for-xml-path-clause-in-sql-server/
*/


select * 
from ddbba.cliente
for xml RAW;
-- la forma más básica hace que cada fila sea un ROW en un XML genérico
-- y cada campo es un atributo de ese elemento XML

-- Supongamos que no nos gusta ver que cada fila se llama row (fila en inglés)
select * 
from ddbba.cliente
for xml RAW ('Cliente');
-- ahora cada fila es un Cliente.

-- Si queremos que además tenga una raiz lo indicamos... y le ponemos nombre
select * 
from ddbba.cliente
for xml RAW ('Cliente'), ROOT('DocCliente');

-- Si preferimos una forma más simple y similar a la original, 
-- separamos los campos como elementos
select * 
from ddbba.cliente
for xml RAW ('Cliente'), ROOT('DocCliente'), ELEMENTS;

-- Supongamos que uno de los clientes llamado "pipi" ya no tiene barrio
Update ddbba.cliente
set		direccion=null
where	nombre like 'Pipi%'

-- Observe que si hay un valor nulo el elemento no se incluye
select * 
from ddbba.cliente
for xml RAW ('Cliente'), ROOT('DocCliente'), ELEMENTS;

-- A menos que indiquemos una palabra clave:
select * 
from ddbba.cliente
for xml RAW ('Cliente'), ROOT('DocCliente'), ELEMENTS XSINIL;
-- Ahora el nulo aparece indicado
-- pero además veremos en el elemento raiz que se indica el esquema default

-- Podemos especificar que además del esquema aparezcan los tipos de datos
select * 
from ddbba.cliente
for xml RAW ('Cliente'), ROOT('DocCliente'), ELEMENTS,XMLSCHEMA;

-- En lugar de utilizar la alternativa RAW veamos la opcion AUTO
select * 
from ddbba.cliente
for xml auto, ROOT('DocCliente'), ELEMENTS XSINIL;
-- Observe que no se indica el nombre de la fila

-- Hagamos algo un poquito mas interesante
-- Supongamos que registramos una tabla relacionada
create table ddbba.gol (
	fecha	smalldatetime,
	rival	char(15),
	idCliente	int references ddbba.cliente (id))

insert ddbba.gol
	select '01/01/1971','Flamengo',1
	union
	select '01/01/1981','Racing',2
	union			
	select '01/01/1982','Inter',2
	union			
	select '01/01/1983','Nacional',3
	union
	select '01/01/1974','Palmeiras',3
	union
	select '01/02/1971','Peñarol',3
	union
	select '01/04/1971','Cruzeiro',1

-- Observe ahora como se presentan los registros relacionados en la vista XML
SELECT Jugador.Nombre, Jugador.ID,
	Jugador.Direccion, Gol.rival, gol.fecha
FROM ddbba.cliente Jugador 
   INNER JOIN ddbba.gol Gol
   ON Jugador.id = Gol.idCliente
FOR XML AUTO, ROOT ('Cliente'), ELEMENTS XSINIL; 

-- Otra forma similar de presentar lo mismo
-- Note la subconsulta en el SELECT
SELECT Jugador.Nombre, Jugador.ID,
	(	select Gol.rival, gol.fecha 
		from	ddbba.gol 
		where	gol.idCliente = Jugador.id
		FOR	XML AUTO, TYPE, ELEMENTS)
FROM ddbba.cliente Jugador 
FOR XML AUTO; 

-- Hay mucho mas que se puede lograr...