USE GRUPO_12;
go
-- 3
create table ddbba.Registro (
	ID int identity(1,1),
	fechaCreacion datetime default getdate(),
	texto varchar(50) default '',
	modulo varchar(10) default '',
	constraint pk_registro primary key clustered (ID)
);

go
-- 4
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
-- 5
create table ddbba.Localidad (
	ID int identity(1,1),
	nombre nvarchar(50) not null,
	constraint pk_localidad primary key clustered (ID)
);
go

create table ddbba.Persona (
	ID int identity,
	DNI int not null,
	nombre nvarchar(100) not null,
	apellido nvarchar(100) not null,
	telefono int not null,
	id_localidad int,
	fechaNacimiento date not null,
	patenteVehiculo varchar(7),
	constraint pk_persona primary key clustered (ID),
	constraint uq_dni unique (DNI),
	constraint fk_localidad foreign key (id_localidad) references ddbba.Localidad (ID),
	constraint ck_telefono check ( 
		telefono LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
	), -- 1O NUMEROS - 12-3456-7890
	constraint ck_patente check (
		patenteVehiculo LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]' OR -- auto patente nueva
		patenteVehiculo LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]' OR -- auto patente vieja
		patenteVehiculo LIKE '[A-Z][0-9][0-9][0-9][A-Z][A-Z][A-Z]' OR -- moto patente nueva
		patenteVehiculo LIKE '[0-9][0-9][0-9][A-Z][A-Z][A-Z]' -- moto patente vieja
	)
);
go

create table ddbba.Materia (
	ID int identity(1,1),
	nombre nvarchar(255),
	constraint pk_materia primary key clustered (ID),
	constraint uq_materia_nombre unique (nombre) -- nombre de la materia unico
);
go


create table ddbba.Curso (
	ID int identity(1,1),
	nroComision int not null,
	id_materia int not null,
	constraint pk_curso primary key clustered (ID),
	constraint ck_nro_comision check (
		nroComision LIKE '[0-9][0-9][0-9][0-9]'
	),
	constraint uq_nro_comision_materia unique (nroComision, id_materia),
	constraint fk_materia foreign key (id_materia) references ddbba.Materia(ID)
);
go

create table ddbba.PersonaCurso (
	id_persona int not null,
	id_curso int not null,
	esDocente bit not null,
	constraint pk_persona_curso primary key clustered (id_persona, id_curso),
	constraint fk_persona foreign key (id_persona) references ddbba.Persona(ID),
	constraint fk_curso foreign key (id_curso) references ddbba.Curso(ID),
	constraint ck_es_docente check (esDocente in (0,1))
);
go

create or alter trigger ddbba.tg_unico_rol_por_materia on
ddbba.PersonaCurso after insert, update as
begin
	set nocount on;

	-- Verificamos cada registro insertado / actualizado
	if exists (
		select 1 from inserted i
		inner join ddbba.Curso c on i.id_curso = c.ID
		inner join ddbba.Materia m on c.id_materia = m.ID
		inner join ddbba.PersonaCurso pc on i.id_persona = pc.id_persona
		group by i.id_persona, m.ID
		having count(distinct case when i.esDocente = 1 then 'D' else 'A' end) > 1
	)
	begin
		raiserror(	'Una persona no puede ser alumno y docente de la misma materia'
					--
					,16 -- severidad
					,1 -- estado
		);
		rollback transaction;
	end
end

/*
	6. Compruebe que las restricciones creadas funcionen correctamente generando 
	juegos de prueba que no se admitan. Documente con un comentario el error de 
	validación en cada caso. Asegúrese de probar con valores no admitidos siquiera una 
	vez cada restricción
*/

-- Set de datos para usar localidades en las personas
set nocount on
insert into ddbba.Localidad values ('Villa Madero');
insert into ddbba.Localidad values ('Tapiales');
insert into ddbba.Localidad values ('La Tablada');
insert into ddbba.Localidad values ('Laferrere');
insert into ddbba.Localidad values ('Ciudad Evita');
insert into ddbba.Localidad values ('Aldo Bonzi');
insert into ddbba.Localidad values ('Gonzalez Catán');

-- PERSONA
-- Pruebo la restricción del teléfono
insert into ddbba.Persona 
(DNI,nombre,apellido,telefono,id_localidad,fechaNacimiento,patenteVehiculo)
values
(44789809, 'Tomás', 'Felice', 1212, 1, convert(date,'20030330'), 'EPE928');
--The INSERT statement conflicted with the CHECK constraint "ck_telefono".
--The conflict occurred in database "GRUPO_12", table "ddbba.Persona", column 'telefono'.

-- Pruebo la restricción de DNI unico
insert into ddbba.Persona 
(DNI,nombre,apellido,telefono,id_localidad,fechaNacimiento,patenteVehiculo)
values
(44789809, 'Tomás', 'Felice', 1158470217, 1, convert(date,'20030330'), 'EPE928');
go

insert into ddbba.Persona 
(DNI,nombre,apellido,telefono,id_localidad,fechaNacimiento,patenteVehiculo)
values
(44789809, 'Tomás', 'Felice', 1158470217, 1, convert(date,'20030330'), 'EPE928');
--Violation of UNIQUE KEY constraint 'uq_dni'.
--Cannot insert duplicate key in object 'ddbba.Persona'.
--The duplicate key value is (44789809).

--Localidad inexistente
insert into ddbba.Persona 
(DNI,nombre,apellido,telefono,id_localidad,fechaNacimiento,patenteVehiculo)
values
(44789808, 'Tomás', 'Felice', 1158470217, 324, convert(date,'20030330'), 'EPE928');
-- The INSERT statement conflicted with the FOREIGN KEY constraint "fk_localidad".
-- The conflict occurred in database "GRUPO_12", table "ddbba.Localidad", column 'ID'.



select * from ddbba.Persona;
/*
	7. Cree un stored procedure para generar registros aleatorios en la tabla de alumnos. 
	Para ello genere una tabla de nombres que tenga valores de nombres y apellidos 
	que podrá combinar de forma aleatoria. Al generarse cada registro de alumno tome 
	al azar dos valores de nombre y uno de apellido. El resto de los valores (localidad, 
	fecha de nacimiento, DNI, etc.) genérelos en forma aleatoria también. El SP debe 
	admitir un parámetro para indicar la cantidad de registros a generar
*/

-- creo tabla auxiliar de nombres
create table ddbba.Nombres (
	id int identity(1,1) primary key,
	nombre nvarchar(30),
)
go
--inserto valores
insert into ddbba.Nombres (nombre) values ('Tomás')
insert into ddbba.Nombres (nombre) values ('Agustín')
insert into ddbba.Nombres (nombre) values ('Martín')
insert into ddbba.Nombres (nombre) values ('Benito')
insert into ddbba.Nombres (nombre) values ('Pepe')
insert into ddbba.Nombres (nombre) values ('Roberto')
insert into ddbba.Nombres (nombre) values ('Anastasio')
insert into ddbba.Nombres (nombre) values ('Lucas')
insert into ddbba.Nombres (nombre) values ('Diego')
insert into ddbba.Nombres (nombre) values ('Franco')
-- creao tabla auxiliar de apellidos

-- inserto valores

-- creo proc para insertar personas
create or alter procedure ddbba.insertarPersonas ( @cantidad int )
as
begin
	declare @contador int
		,	@ AS date
		,	@FechaFin AS date
		,	@DiasIntervalo As int;
	-- Inicializo valores y limites
	SELECT	@FechaInicio	= '20230101',
			@FechaFin		= '20230731',
			@DiasIntervalo	= (1 + DATEDIFF(DAY, @FechaInicio, @FechaFin)),
			@contador = 0
	while @contador < 1000
	begin
		insert ddbba.Persona(fecha, ciudad, monto)
			select DATEADD(DAY, RAND(CHECKSUM(NEWID())) * @DiasIntervalo, @FechaInicio),
				case CAST(RAND() * (5-1) + 1 as int)
					when 1 then 'Buenos Aires'
					when 1 then 'Rosario'
					when 1 then 'Bariloche'
					when 1 then 'Claromeco'
					else		'Iguazu'
					end,
					CAST(RAND() * (2000-100) + 100 as int)
		set @contador = @contador + 1
		print 'Generando el reg nro '+ CAST(@contador as varchar)
	end
end

-- inserto cursos y materias

--creo proc de la consigna