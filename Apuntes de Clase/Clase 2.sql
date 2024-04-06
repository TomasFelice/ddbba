/*
	Codigo de CLASE 2
*/

-- con ctrl+r escondemos la ventanan d abajo :)

create database practicaClase
go
use practicaClase
go

-- schemas son formas de agrupar objetos de la ddbb
-- sp, functions, triggers, etc -> pertenecen a un schema
create schema ddbba
go

create table ddbba.Venta
(
	id		int identity(1,1) primary key,
	fecha	smalldatetime,
	ciudad	char(20),
	monto	decimal(10,2)
)
go
--suprimo los mensajes de "registro insertado"
set nocount on
-- Generamos algunos valores al azar
declare @contador int
	,	@FechaInicio AS date
	,	@FechaFin AS date
	,	@DiasIntervalo As int;
-- Inicializo valores y limites
SELECT	@FechaInicio	= '20230101',
		@FechaFin		= '20230731',
		@DiasIntervalo	= (1 + DATEDIFF(DAY, @FechaInicio, @FechaFin)),
		@contador = 0
while @contador < 1000
begin
	insert ddbba.Venta (fecha, ciudad, monto)
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

-- Podemos dar una mirada a los primeros registros
select top 20 * from ddbba.Venta

-- Ventas promedio por ciudad y fecha
select 

-- Queremos cada venta y el prom por dia
select	id, fecha, ciudad, monto, AVG(monto) OVER (PARTITION BY fecha,ciudad) as PromedioDiario
from	ddbba.Venta
order by ciudad, fecha

-- Ahora cada venta y el acumulado diario
select	id, fecha, ciudad, monto, SUM(monto) OVER (PARTITION BY ciudad order by fecha) as TotalAcumuladoPorDia
from	ddbba.Venta
order by ciudad, fecha

-- Ahora las ventas clasificadas segun el percentil de ventas
-- Permite ver las ventas en euna escala de N rangos
select	id, fecha, ciudad, monto, ntile(4) --ntile es una windows function
		over (order by monto) as EscalaVentas
from	ddbba.Venta
order by EscalaVentas, monto

-- CTE
-- Fibonacci
WITH Fibonacci (PrevN, N) AS
(
	SELECT 0,1
	UNION ALL
	SELECT N, PrevN + N
	FROM Fibonacci
	WHERE N < 1000
)
SELECT PrevN as Fibo
	FROM Fibonacci
	OPTION (MAXRECURSION 0);

-- Generemos registros de notas de examen de un par de alumnos

IF OBJECT_ID(N'ddbba.Nota', N'U') IS NOT NULL
	DROP TABLE ddbba.Nota;
GO

-- ver desde aca para abajo 
create table ddbba.Calificacion
(
	
);

-- ver los duplicados
set nocount off
with CTE(alumno, nota, materia, ocurrencias)
as ( select alumno,
			nota,
			materia,
			ROW_NUMBER() OVER(
				partition by alumno, nota, materia
				order by alumno, nota, materia
			) as Ocurrencias
	from ddbba.Calificacion)
select *
from CTE
where ocurrencias > 1;

-- eliminar duplicados
set nocount off
with CTE(alumno, nota, materia, ocurrencias)
as ( select alumno,
			nota,
			materia,
			ROW_NUMBER() OVER(
				partition by alumno, nota, materia
				order by alumno, nota, materia
			) as Ocurrencias
	from ddbba.Calificacion)
delete
from CTE
where ocurrencias > 1;

/*
	Promedios por materia, cada mat en una colimna
	
*/

with