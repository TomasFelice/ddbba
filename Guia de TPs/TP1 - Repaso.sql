create database tomi;
go

use tomi;
go

create schema ddbba;
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
	DNI bigint not null,
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
		telefono >= 1000000000 and telefono <= 9999999999
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

-- inserto valores para Materia
insert into ddbba.Materia (nombre) values
('Paradigmas de Programación'),
('Análisis de Sistemas'),
('Bases de Datos Aplicadas'),
('Arquitectura de Computadoras'),
('Introducción a la Gestión de Requisitos');
go
-- inserto valores para Curso
insert into ddbba.Curso (nroComision, id_materia) values
(1234, 1),
(1234, 2),
(1234, 3),
(1234, 4),
(1234, 5),
(4321, 1),
(4321, 2),
(4321, 3),
(4321, 4),
(4444, 1),
(3333, 3),
(2222, 2),
(5555, 5),
(1768, 4),
(3232, 2);
go

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
go
-- creao tabla auxiliar de apellidos
create table ddbba.Apellidos (
	id int identity(1,1) primary key,
	apellido nvarchar(30),
)
go
--inserto valores
insert into ddbba.Apellidos(apellido) values ('Felice')
insert into ddbba.Apellidos(apellido) values ('Dagrosa')
insert into ddbba.Apellidos(apellido) values ('Rodriguez')
insert into ddbba.Apellidos(apellido) values ('Gonzalez')
insert into ddbba.Apellidos(apellido) values ('Fernandez')
insert into ddbba.Apellidos(apellido) values ('Messi')
insert into ddbba.Apellidos(apellido) values ('Ronaldo')
insert into ddbba.Apellidos(apellido) values ('Martinez')
insert into ddbba.Apellidos(apellido) values ('Simpson')
insert into ddbba.Apellidos(apellido) values ('Argento')
go

-- creo tabla auxiliar de patentes
create table ddbba.Patentes (
	id int identity(1,1) primary key,
	patente varchar(7) check (
		patente LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]' OR -- auto patente nueva
		patente LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]' OR -- auto patente vieja
		patente LIKE '[A-Z][0-9][0-9][0-9][A-Z][A-Z][A-Z]' OR -- moto patente nueva
		patente LIKE '[0-9][0-9][0-9][A-Z][A-Z][A-Z]' -- moto patente vieja
	)
)
go

insert into ddbba.Patentes (patente) values
('EPE928'),
('AA123AA'),
('AB123CD'),
('AF432GH'),
('ABC123'),
('BCA321'),
('TE405AS');
go

-- creo proc para insertar personas
create or alter procedure ddbba.insertarAlumnos (@cantidad int)
as
begin
	-- Declaro variables
	declare @contador int
		,	@DNI bigint
		,	@FechaBase AS date
		,	@LimiteInferiorTelefono as bigint
		,	@LimiteSuperiorTelefono as bigint
		,	@MaxIDLocalidad as int
		,	@MaxIDNombre as int
		,	@MaxIDApellido as int
		,	@MaxIDPatente as int
		,	@Nombre as varchar(30)
		,	@Apellido as varchar(30)
		,	@IDLocalidad as int
		,	@FechaNacimiento as date
		,	@Patente as varchar(7)
		,	@MaxIDPersona as int
		,	@MaxIDCurso as int
		,	@Curso as int;

	-- Inicializo valores y limites
	SELECT	@FechaBase					= '20060411',
			@LimiteInferiorTelefono		= 1000000000,
			@LimiteSuperiorTelefono		= 9999999999,
			@MaxIDLocalidad				= (select top 1 max(L.ID) from ddbba.Localidad L),
			@MaxIDNombre				= (select top 1 max(n.id) from ddbba.Nombres n),
			@MaxIDApellido				= (select top 1 max(a.id) from ddbba.Apellidos a),
			@MaxIDPatente				= (select top 1 max(p.id) from ddbba.Patentes p),
			@MaxIDCurso					= (select top 1 max(c.id) from ddbba.Curso c),
			@contador					= 0;

	-- Iniciar loop
	while @contador < @cantidad
	begin
		-- Inicializo variables de persona especifica
		set		@contador			= @contador + 1;
		set		@DNI				= @contador;
		select	@Nombre				= (select top 1 nombre from ddbba.Nombres where id = cast(rand() * @MaxIDNombre + 1 AS int)),
				@Apellido			= (select top 1 apellido from ddbba.Apellidos where id = cast(rand() * @MaxIDApellido + 1 AS int)),
				@IDLocalidad		= cast(rand() * @MaxIDLocalidad + 1 AS int),
				@FechaNacimiento	= cast(DATEADD(DAY, RAND(CHECKSUM(NEWID())), @FechaBase) as date),
				@Patente			= (select top 1 patente from ddbba.Patentes where id = cast(rand() * @MaxIDPatente + 1 AS int)),
				@Curso				= cast(rand() * @MaxIDCurso + 1 AS int);

		-- Inserto personas
		insert ddbba.Persona(DNI,nombre,apellido,telefono,id_localidad,fechaNacimiento,patenteVehiculo)
			select	@DNI,
					@Nombre,
					@Apellido,
					cast(((rand() * (@LimiteSuperiorTelefono - @LimiteInferiorTelefono)) + @LimiteInferiorTelefono) as bigint),
					@IDLocalidad,
					@FechaNacimiento,
					@Patente;
		
		-- Me guardo el ID de la persona creada
		select	@MaxIDPersona	= (select max(id) from ddbba.Persona);

		-- Hago alumno a la persona creada
		insert into ddbba.PersonaCurso (id_persona, id_curso, esDocente)
			select	@MaxIDPersona,
					@Curso,
					0;

		print 'Generando el reg nro '+ CAST(@contador as varchar)
	end
end;
go

-- 8. Utilizando el SP creado en el punto anterior, genere 1000 registros de alumnos.

declare @cantidad as int;
set @cantidad = 1000;

exec ddbba.insertarAlumnos @cantidad;

-- 9. Elimine los registros duplicados utilizando common table expressions.
WITH CTE(nombre, apellido, telefono,id_localidad,fechaNacimiento,patenteVehiculo, duplicadas) as
	(select nombre, apellido, telefono,id_localidad,fechaNacimiento,patenteVehiculo,
	ROW_NUMBER() over(partition by nombre, apellido, telefono,id_localidad,fechaNacimiento,patenteVehiculo order by id) as duplicadas
	from ddbba.Persona)
delete from CTE where duplicadas > 1

/*
12. Cree una vista empleando la opción “SCHEMABINDING” para visualizar las 
comisiones (nro de comisión, código de materia, nombre de materia, apellido y 
nombre de los alumnos). El apellido y nombre debe mostrarse con el formato 
“Apellido, Nombres” (observe la coma intermedia).
a. Verifique qué ocurre si intenta modificar el tamaño de uno de los campos de 
texto de la tabla de alumnos. 
b. Verifique qué ocurre si intenta agregar un campo a la tabla de alumno.
c. Verifique qué ocurre si intenta agregar un campo que admita nulos a la tabla 
de alumno. ¿Hay diferencia entre agregarlo si la tabla está vacía o tiene 
registros?
d. ¿Puede usar SCHEMABINDING con una vista del tipo “Select * From..”?
*/

create or alter view ddbba.comisiones
with schemabinding
as
	select distinct m.ID codigoMateria, m.nombre, c.nroComision, p.apellido + ', ' + p.nombre nombreYApellido
	from ddbba.Curso c
	inner join ddbba.Materia m on c.id_materia = m.ID
	inner join ddbba.PersonaCurso pc on c.ID = pc.id_curso
	inner join ddbba.Persona p on pc.id_persona = p.ID
go

select * from ddbba.comisiones order by codigoMateria, nroComision

-- a. Verifique qué ocurre si intenta modificar el tamaño de uno de los campos de 
-- texto de la tabla de alumnos. 
alter table ddbba.Persona
alter column nombre varchar(135)
/*
	Msg 5074, Level 16, State 1, Line 377
	The object 'comisiones' is dependent on column 'nombre'.
	Msg 4922, Level 16, State 9, Line 377
	ALTER TABLE ALTER COLUMN nombre failed because one or more objects access this column.
*/

-- b. Verifique qué ocurre si intenta agregar un campo a la tabla de alumno.
alter table ddbba.PersonaCurso
add nuevoCampo int

alter table ddbba.PersonaCurso
drop column nuevoCampo
-- Lo reaiza sin problemas
alter table ddbba.Persona
add nuevoCampo int

alter table ddbba.Persona
drop column nuevoCampo
-- Lo realiza sin problemas

-- c. Verifique qué ocurre si intenta agregar un campo que admita nulos a la tabla 
-- de alumno. ¿Hay diferencia entre agregarlo si la tabla está vacía o tiene 
-- registros?
-- Lo voy a intentar ahora para que no acepte nulos
alter table ddbba.PersonaCurso
add nuevoCampo int not null

-- ALTER TABLE only allows columns to be added that can contain nulls,
--	or have a DEFAULT definition specified, or the column being added is an identity or timestamp column,
--	or alternatively if none of the previous conditions are satisfied the table must be empty to allow addition of this column.
--	Column 'nuevoCampo' cannot be added to non-empty table 'PersonaCurso' because it does not satisfy these conditions.
alter table ddbba.Persona
add nuevoCampo int not null

alter table ddbba.Persona
drop column nuevoCampo
-- Lo realiza sin problemas

-- d. ¿Puede usar SCHEMABINDING con una vista del tipo “Select * From..”?
 -- Probemos..
create or alter view ddbba.comisiones2
with schemabinding
as
	select *
	from ddbba.Curso c
	inner join ddbba.Materia m on c.id_materia = m.ID
	inner join ddbba.PersonaCurso pc on c.ID = pc.id_curso
	inner join ddbba.Persona p on pc.id_persona = p.ID

-- Comprobamos que no esta permitido
-- Syntax '*' is not allowed in schema-bound objects.
-- Esto se da para garantizar la integridad de los datos

-- 13. Agregue a la tabla de comisión soporte para día y turno de cursada. (Modifique la 
-- tabla). Los números de comisión son únicos para cada cuatrimestre.

create table ddbba.comisionesTable (
	nro char(4),
	dia nvarchar(10),
	turno nvarchar(10),
	constraint pk_comisiones primary key clustered (nro),
	constraint ck_comisiones check (nro LIKE '[1-6][369]00'),
	constraint ck_dia check (dia in ('Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado')),
	constraint ck_turno check (turno in ('Mañana', 'Tarde', 'Noche'))
);
go

insert into ddbba.comisionesTable (nro, dia, turno)
values
('1300', 'Lunes', 'Mañana'),
('1600', 'Lunes', 'Tarde'),
('1900', 'Lunes', 'Noche'),
('2300', 'Martes', 'Mañana'),
('2600', 'Martes', 'Tarde'),
('2900', 'Martes', 'Noche'),
('3300', 'Miércoles', 'Mañana'),
('3600', 'Miércoles', 'Tarde'),
('3900', 'Miércoles', 'Noche'),
('4300', 'Jueves', 'Mañana'),
('4600', 'Jueves', 'Tarde'),
('4900', 'Jueves', 'Noche'),
('5300', 'Viernes', 'Mañana'),
('5600', 'Viernes', 'Tarde'),
('5900', 'Viernes', 'Noche'),
('6300', 'Sábado', 'Mañana'),
('6600', 'Sábado', 'Tarde')
go

alter table ddbba.curso
add dia nvarchar(10),
	turno nvarchar(10),
	cuatrimestre int,
	constraint ck_cuatrimestre check (cuatrimestre >= 1 and cuatrimestre <= 3)
go

create or alter trigger tg_comision on ddbba.curso
after insert, update as
begin
	declare @id int;
	declare @idMateria int;
	declare @nroComision int;
	declare @dia nvarchar(10);
	declare @turno nvarchar(10);
	declare @cuatrimestre int;

	SELECT @id = i.ID,
           @idMateria = i.id_materia,
		   @nroComision = i.nroComision,
		   @dia = i.dia,
		   @turno = i.turno,
		   @cuatrimestre = i.cuatrimestre
    FROM inserted i;

	if not exists(
		select 1 from ddbba.curso c
		inner join inserted i on c.ID = i.ID
		where c.dia = i.dia and c.turno = i.turno and c.cuatrimestre = i.cuatrimestre
	)
		insert into ddbba.Curso (ID, id_materia, nroComision, dia, turno, cuatrimestre)
		values
		(@id, @idMateria, @nroComision, @dia, @turno, @turno);

end
go

-- 14. Complete los datos de día y curso con valores aleatorios
update ddbba.Curso
set dia = (select top 1 dia from ddbba.comisionesTable cs where cs.nro = nroComision),
	turno = (select top 1 turno from ddbba.comisionesTable cs where cs.nro = nroComision),
	cuatrimestre = (cast(rand() * 4 as int))
go

--15. Genere una función validaCursada que devuelva la cantidad de materias 
--	superpuestas a las que está inscripto un alumno, recibiendo el DNI por parámetro.

create or alter function ddbba.validaCursada (@DNI bigint)
returns int
begin
	declare @cantidadSuperpuestas as int;

	set @cantidadSuperpuestas = (
		select count(1) from ddbba.Persona p
		inner join ddbba.PersonaCurso pc on p.ID = pc.id_persona
		inner join ddbba.Curso c on pc.id_curso = c.ID
		where p.DNI = @DNI AND (
			select count(1) from ddbba.PersonaCurso pc2
			inner join ddbba.Curso c2 on pc2.id_curso = c2.ID
			where pc2.id_persona = PC.id_persona and c2.nroComision = c.nroComision
		) > 1
	);

	return @cantidadSuperpuestas;
end
go

-- 16. Cree una vista que utilice la función del punto anterior y muestre los alumnos con 
-- superposición de inscripciones.
create or alter view ddbba.alumnosConSuperposicion
as
	select p.ID, p.DNI, concat(concat(p.apellido, ', '), p.nombre) apellido_nombre
	from ddbba.Persona p
	where ddbba.validaCursada(p.DNI) > 1

-- 17. Cree un SP que elimine las inscripciones superpuestas o duplicadas.
create or alter proc ddbba.eliminasInsripcionesSuperpuestas
as
begin
	delete pc from ddbba.PersonaCurso pc
	where exists (
		select 1 from ddbba.alumnosConSuperposicion acs
		where acs.ID = pc.id_persona
	)
end
go

exec ddbba.eliminasInsripcionesSuperpuestas
go

select * from ddbba.alumnosConSuperposicion
go

-- 18. Cree una vista que presente una vista PIVOT de cantidad de inscripciones para las 
-- materias por cada turno. Utilice su criterio para presentarlo de la manera que 
-- considere más clara.
create or alter view ddbba.inscripcionesMateriaTurno
as
	with InscripcionesPorTurno (Materia, Turno, Cantidad) as (
		select m.nombre Materia, c.turno Turno, count(m.ID) Cantidad from ddbba.Materia m
		inner join ddbba.Curso c on m.ID = c.id_materia
		inner join ddbba.PersonaCurso pc on c.ID = pc.id_curso
		group by m.nombre, c.turno
	) -- fin CTE
	select Materia, isnull(Mañana, 0) Mañana, isnull(Tarde, 0) Tarde, isnull(Noche, 0) Noche
	from InscripcionesPorTurno
	pivot( sum(Cantidad) for
		Turno in ([Mañana], [Tarde], [Noche])
	) Pivoteado

go

select * from ddbba.inscripcionesMateriaTurno

-- 19. Utilizando Window Functions cree una vista que muestre los alumnos inscritos a una 
-- materia y en una columna también muestre la cantidad total de materias a las que se 
-- ha inscrito ese alumno (en un mismo cuatrimestre).

create or alter view ddbba.alumnos_inscriptos_materia
as
	select	p.ID, p.DNI, concat(p.apellido, ', ', p.nombre) nombre_apellido, m.nombre materia, c.cuatrimestre,
			count(m.id) over (partition by p.ID, c.cuatrimestre) cantidad_materias_alumno_cuatrimestre
	from ddbba.Persona p
	inner join ddbba.PersonaCurso pc on p.ID = pc.id_persona and pc.esDocente = 0
	inner join ddbba.Curso c on pc.id_curso = c.ID
	inner join ddbba.Materia m on c.id_materia = m.ID
go

select * from ddbba.alumnos_inscriptos_materia order by ID, cuatrimestre

-- 20. Utilizando Window Functions presente el 5% más joven y el 5% menos joven del 
-- alumnado.

select	p.ID, p.DNI, CONCAT(p.apellido, ', ', p.nombre) nombreYApellido, p.fechaNacimiento,
		percent_rank() over (partition by p.dni order by p.fechaNacimiento) masJovenes,
		percent_rank() over (partition by p.dni order by p.fechaNacimiento) menosJovenes
from ddbba.Persona p
inner join ddbba.PersonaCurso pc on p.ID = pc.id_persona and pc.esDocente = 0

select * from ddbba.Persona