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
	nombre varchar(50) not null,
	constraint pk_localidad primary key clustered (ID)
);
go

create table ddbba.Persona (
	ID int,
	DNI int not null,
	nombre varchar(100) not null,
	apellido varchar(100) not null,
	telefono int not null,
	id_localidad int
	fechaNacimiento date not null,
	patenteVehiculo varchar(7),
	constraint pk_persona primary key clustered (ID),
	constraint fk_localidad (id_localidad) references ddbba.Localidad(ID)
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
	nombre varchar(255)
);
go

create table ddbba.Curso (
	ID int identity(1,1),
	nroComision int,
	materia int,
	constraint pk_curso primary key clustered (ID),
	constraint ck_cod check (
		cod LIKE '[0-9][0-9][0-9][0-9]'
	)
	constraint fk_materia (materia) references ddbba.Materia(ID)
);
go

create table ddbba.Alumno (
	id_alumno int identity(1,1),
	id_persona int not null,
	id_curso int not null,
	constraint pk_alumno primary key clustered (id_alumno),
	constraint fk_persona (id_persona) references ddbba.Persona(ID),
	constraint fk_curso (id_curso) references ddbba.Curso(ID),
);
go

create table ddbba.Docente (
	id_docente int identity(1,1),
	id_persona int not null,
	id_curso int not null,
	constraint pk_alumno primary key clustered (id_docente),
	constraint fk_persona (id_persona) references ddbba.Persona(ID),
	constraint fk_curso (id_curso) references ddbba.Curso(ID),
);
go

create or alter trigger ddbba.verificarAlumno
on ddbba.Alumno after insert
as
begin
	
end;
go