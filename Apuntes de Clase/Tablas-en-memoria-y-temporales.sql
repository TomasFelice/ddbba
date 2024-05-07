/*
Las tablas en memoria en SQL Server existen desde la versión 2014
Para que se puedan crear primero hay que habilitarlo en la base de datos
Por supuesto, si el proyecto lo contempla podriamos haberlo habilitado desde un principio
*/

RAISERROR(N'Este script no está pensado para que lo ejecutes "de una" con F5. Seleccioná y ejecutá de a poco.', 20, 1) WITH LOG;
GO

USE [master]
GO

CREATE DATABASE [Probanding]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Probanding', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Probanding.mdf' ), 
 FILEGROUP [Memoria] CONTAINS MEMORY_OPTIMIZED_DATA  DEFAULT
( NAME = N'MemoryDBInMemoryData', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\ProbandingMemoria.mdf' )
 LOG ON 
( NAME = N'Probanding_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Probanding_log.ldf'  )
GO


/*
Sino tenemos que modificar la DB:

ALTER DATABASE PruebasDB
	ADD  FILEGROUP [Memoria] CONTAINS MEMORY_OPTIMIZED_DATA 
go

alter database pruebasDB
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
go

*/
use probanding
go

-- Ahora podemos indicar al crear una tabla
-- si se almacenará en memoria o no
-- y si queremos que persista o no
create schema ddbba;
go

drop table ddbba.PruebaEnMemoria

IF OBJECT_ID(N'[ddbba].[PruebaEnMemoria]', N'U') IS NULL 
	create table ddbba.PruebaEnMemoria (
		id		int	identity(1,1) primary key NONCLUSTERED,
		nombre	varchar(35)
	)
	with ( MEMORY_OPTIMIZED = ON
	, DURABILITY =  SCHEMA_ONLY ) -- solo mantenemos el schema, los datos no
else
	print 'Ya existe'
go

/*
No se pueden generar indices cluster en las tablas en memoria.
Por ello debemos aclarar que el PK es nonclustered
La clausula WITH es la que determina que se almacena en memoria 
Por default la durabilidad (persistencia) es para esquema y datos
Pero si queremos mantener solo la estructura de la tabla, lo
indicamos con SCHEMA_ONLY (definicion de campos).
*/

drop table ddbba.PruebaEnMemoriaPersistente
go

IF NOT EXISTS (
    SELECT * FROM sys.tables t 
    JOIN sys.schemas s ON (t.schema_id = s.schema_id) 
    WHERE s.name = 'ddbba' AND t.name = 'PruebaEnMemoriaPersistente') 
begin
	create table ddbba.PruebaEnMemoriaPersistente (
		id		int	identity(1,1) primary key nonclustered,
		nombre	varchar(35)
	)
	with ( MEMORY_OPTIMIZED = ON
	, DURABILITY =  SCHEMA_AND_DATA ) -- mantenemos schema y datos
end

-- Aqui hicimos explicito que queremos conservar los datos
/*
Veamos ahora la prueba, insertemos valores en ambas
*/

insert ddbba.PruebaEnMemoria(nombre)
select 'Chau'

insert ddbba.PruebaEnMemoriaPersistente(nombre)
select 'Chau'
-- Constatamos lo que se inserto:
select * from ddbba.PruebaEnMemoriaPersistente
select * from ddbba.PruebaEnMemoria
go



/* Ahora habria que reiniciar el servicio SQL Server
 (para no reiniciar el sistema operativo, que es medio violento e innecesario)

 Una vez que haya reiniciado, conectese nuevamente a la DB y ejecute a partir de aqui
 No es necesario que cierre SSMS

 */
 -- esto detiene el motor:
 shutdown

 -- en este punto tendrias que iniciar el servicio SQL Server de nuevo.

use pruebasDB
go
exec sp_help 'ddbba.PruebaEnMemoriaPersistente'

use Probanding
go
-- por default tal vez su usuario no use esta DB al conectarse

-- Veamos que nos quedo:
select * from ddbba.PruebaEnMemoriaPersistente
select * from ddbba.PruebaEnMemoria

select @@servername

create database pruebasddbba;
go

use pruebasddbba
go
-- Ahora creemos una tabla temporal
Create table #temporal
(
	a int primary key,
	b varchar(10)
)
-- Guardemos algo
insert #temporal
values (11,'Hoooola')
--
select @@rowcount [cuenta de afectadas]
set nocount on
-- ¿En qué DB la generó?
select * from #temporal
-- Tip: busque System Databases -> tempdb -> Temporary Tables

-- ¿Por qué le agrega un sufijo al nombre de la tabla?
--		Porque podrian existir distintos usuarios creando dbs
--		tewmporales con el mismo nombre y cada usuario deberá ver la suya

-- ¿Qué pasa si varios usuarios crean la misma temporal?
--		Se crean con nombres distintos
--		Por lo tanto no se solaparán
--		Cada sesios es independiente


-- ¿Y si le especificamos un esquema? 
-- Porque a ddbba no lo creamos en tempdb...
Create table ddbba.#temporalisima
(
	a int primary key,
	b varchar(10)
)
-- ¿En qué base lo creó? ¿Con qué esquema?
-- ¿Esto va a funcionar:
Create table ddbba.#temporal
(
	a int primary key
	,b varchar(10)
)

-- CUANDO USAMOS TABLAS TEMPORALES NO LE DA BOLA AL SCHEMA
-- SIEMPRE VAN EN TEMPDB


-- Veamos ahora el alcance:
select * from #temporal
select * from pruebasdb.dbo.#temporal
select * from Probanding.dbo.#temporal
select * from [AdventureWorks2017].dbo.#temporal
-- Es la misma tabla! 
-- Osea que todo muestra lo mismo
-- Por el mismo motivo, ignora los schemas y las db

-- Qué pasa si intentamos verla desde OTRA SESION de usuario?
-- (genere una conexión distinta y verifique)
-- No lo vamos a poder ver

-- Veamos qué pasa con una temporal global (observe el doble numeral):
Create table ##temporalGlobal
(
	a int primary key,
	b varchar(20)
)

-- Guardemos algo
insert ##temporalGlobal
values (1,'Flaaanders')

-- Observe la tabla temporal creada en tempdb.
-- ¿Se modificó el nombre de la tabla para distinguirla entre sesiones? ¿Por qué?
--		No se modifica porque justamente es global, entonces no diferencia por sesiones
--		Si ingreso desde otra sesión, voy a poder accederla sin problemas

-- Ahora verifique nuevamente desde una conexion distinta (mismo usuario o distinto)

-- ¿Cuanto tiempo perduran las tablas temporales?
-- Desconectese del motor y vuelva a conectarse
-- Verifique a qué temporales tiene acceso.
--		Duran mientras la sesión esté activa
--		Las temp globales duran hasta que termina la sesión que la creó


-- Veamos ahora el alcance:
select * from #temporal
select * from ##temporalGlobal

/*
Ejecute lo siguiente en la otra sesion:

begin tran
delete from ##temporalGlobal

Verifique que la tabla aun existe

Abra una nueva sesion
Ejecute
select * from ##temporalGlobal

Ahora:
cierre la conexion original
ejecute un COMMIT TRAN en la segunda ventana.
¿qué pasó con la temporal?
*/
