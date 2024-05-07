use pruebasddbba
go

create table ddbba.Venta
(
	id int identity(1,1) primary key ,
	fecha smalldatetime,
	ciudad	char(20),
	monto	decimal(10,2)
	)
go

-- suprimo los mensajes de "registro insertado'
set nocount on
-- Generemos algunos valores al azar
declare @contador int
	, @FechaInicio AS date
	, @FechaFin AS date
	, @DiasIntervalo AS int;
-- Inicializo valores y limites
SELECT @FechaInicio   = '20230101',
		@FechaFin     = '20230731',
		@DiasIntervalo = (1+DATEDIFF(DAY, @FechaInicio, @FechaFin))
	,@contador = 0
-- Las ciudades las hardcodié. Genero otro random y lo convierto
while @contador < 1000
begin	
	insert ddbba.venta (fecha,ciudad,monto)
		select DATEADD(DAY, RAND(CHECKSUM(NEWID()))*@DiasIntervalo,@FechaInicio),
			case Cast(RAND()*(5-1)+1 as int)
				when 1 then 'Buenos Aires'
				when 2 then 'Rosario'
				when 3 then 'Carlos Paz'
				when 4 then 'Claromeco'
				else  'Iguazu'
				end ,
				Cast(RAND()*(2000-100)+100 as int)
	set @contador = @contador + 1
	print 'Generado el registro nro ' + cast(@contador as varchar)
end

-- Podemos dar una mirada a los primeros registros
select top 20 * from ddbba.venta

-- Si no nos gusta... borramos y generamos de nuevo
--truncate table ddbba.venta

-- Ventas promedio por ciudad y fecha
select	fecha, ciudad, avg(monto) VentaPromedio
from	ddbba.venta
group by	fecha, ciudad;

-- Queremos ver cada venta y el promedio por dia
select id, fecha, ciudad, monto, AVG(monto) OVER (PARTITION BY fecha,ciudad) as PromedioDiario
from	ddbba.venta
order by ciudad,fecha

-- Ahora cada venta y el acumulado diario
select id, fecha, ciudad, monto, sum(monto) OVER (PARTITION BY ciudad order by fecha) as TotalAcumuladoPorDia
from	ddbba.venta
order by ciudad,fecha

-- Ahora las ventas clasificadas segun el percentil de ventas
-- Permite ver las ventas en una escala de N rangos
/*
percentil:
 Valor que divide un conjunto ordenado de datos estadísticos de forma 
 que un porcentaje de tales datos sea inferior a dicho valor. 
 Un individuo en el percentil 80 está por encima del 80 % del grupo a que pertenece.
*/
select id, fecha, ciudad, monto, ntile(4) OVER (order by monto) as EscalaVentas
from	ddbba.venta
order by EscalaVentas,fecha


