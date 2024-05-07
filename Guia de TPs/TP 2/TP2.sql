--1. Tome nota de la intercalación (collate) de la base de datos creada en el TP1.
--2. Genere tres bases de datos adicionales, para lograr obtener una combinación de 
--todas las variantes de sensibilidad a acentos y mayúsculas/minúsculas.
create database tp2_ci_as collate SQL_Latin1_General_CP1_CI_AS;
create database tp2_cs_as collate SQL_Latin1_General_CP1_CS_AS;
create database tp2_ci_ai collate SQL_Latin1_General_CP1_CI_AI;
go

--3. Cree un esquema denominado “ddbba” (por bases de datos aplicada). Todos los 
--objetos que cree a partir de aquí deberán pertenecer a este esquema o a otro según 
--corresponda. No debe usar el esquema default (dbo).

use tp2_ci_as;
go
create schema ddbba;
go

use tp2_cs_as;
go
create schema ddbba;
go

use tp2_ci_ai;
go
create schema ddbba;
go

--4. Recomendamos emplear la tabla y SP “registro” mencionados en el TP1 para 
--operaciones de debugging. 
create table ddbba.Registro (
	ID int identity(1,1),
	fechaCreacion datetime default getdate(),
	texto varchar(50) default '',
	modulo varchar(10) default '',
	constraint pk_registro primary key clustered (ID)
);

go

create or alter procedure ddbba.insertarLog (
	@texto varchar(50),
	@modulo varchar(10)
)
as
begin
	declare @moduloDefault varchar(10);
	set @moduloDefault = 'N/A';

	if @modulo = '' or @modulo is null
		set @modulo = @moduloDefault;

	insert into ddbba.Registro (texto, modulo)
	values (@texto, @modulo);
end

go

--5. Descargue de la web https://datos.gob.ar/dataset/otros-nombres-personasfisicas/archivo/otros_2.1 
--todos los CSV de distintos períodos.

--6. Genere la estructura de tabla para almacenar los datos descargados. Haga esto en 
--las cuatro DB.

-- db tomi
use tomi;
go

drop table if exists ddbba.nombresCSV;
go
create table ddbba.nombresCSV (
	nombre nvarchar(50),
	cantidad int,
	anio int
);

bulk insert ddbba.nombresCSV
from 'C:\Users\tomas\OneDrive\Escritorio\UNLAM\BBDD Aplicada\ddbba\Guia de TPs\TP 2\Scripts\nombres-2015.csv'
with
(
	fieldterminator = ',',
	rowterminator = '0x0A',
	codepage = '65001',
	firstrow = 2,
	lastrow = 50000
);
go

select * from ddbba.nombresCSV;
go

-- db tp2_ci_ai
use tp2_ci_ai;
go

drop table if exists ddbba.nombresCSV;
go
create table ddbba.nombresCSV (
	nombre nvarchar(50),
	cantidad int,
	anio int
);

bulk insert ddbba.nombresCSV
from 'C:\Users\tomas\OneDrive\Escritorio\UNLAM\BBDD Aplicada\ddbba\Guia de TPs\TP 2\Scripts\nombres-2015.csv'
with
(
	fieldterminator = ',',
	rowterminator = '0x0A',
	codepage = '65001',
	firstrow = 50001,
	lastrow = 100000
);
go

select * from ddbba.nombresCSV;
go

-- db tp2_ci_as
use tp2_ci_as;
go

drop table if exists ddbba.nombresCSV;
go
create table ddbba.nombresCSV (
	nombre nvarchar(50),
	cantidad int,
	anio int
);

bulk insert ddbba.nombresCSV
from 'C:\Users\tomas\OneDrive\Escritorio\UNLAM\BBDD Aplicada\ddbba\Guia de TPs\TP 2\Scripts\nombres-2015.csv'
with
(
	fieldterminator = ',',
	rowterminator = '0x0A',
	codepage = '65001',
	firstrow = 100001,
	lastrow = 150000
);
go

select * from ddbba.nombresCSV;
go

-- db tp2_cs_as
use tp2_cs_as;
go

drop table if exists ddbba.nombresCSV;
go
create table ddbba.nombresCSV (
	nombre nvarchar(50),
	cantidad int,
	anio int
);

bulk insert ddbba.nombresCSV
from 'C:\Users\tomas\OneDrive\Escritorio\UNLAM\BBDD Aplicada\ddbba\Guia de TPs\TP 2\Scripts\nombres-2015.csv'
with
(
	fieldterminator = ',',
	rowterminator = '0x0A',
	codepage = '65001',
	firstrow = 150001
);
go

select * from ddbba.nombresCSV;
go



