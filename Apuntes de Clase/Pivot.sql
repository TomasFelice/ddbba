use pruebasDB
go

select top 10 * from ddbba.venta

-- Vamos al ejemplo del material
-- Note que el CTE simplifica la consulta
with VentasResumidas (Total, Ciudad, Mes) as(
	select monto, 
		Ciudad, 
		cast(datepart(mm,fecha) as varchar) + '-' + cast(datepart(yyyy, fecha) as varchar)  Mes
	from ddbba.Venta)
select *
from VentasResumidas 
pivot(sum(Total) for Mes in ([1-2023],[2-2023],[3-2023],[4-2023],[5-2023],[6-2023],[7-2023]) ) Cruzado

/*
Aspectos a notar:
* Usamos datepart para extraer porciones de la fecha. No es la única forma (en el material de clase usamos otra).
* El pivot siempre se hace con funciones de agregado.
* Los valores que generamos para cada mes los debemos indicar hardcodeados en el pivot.
* Si faltan datos para un valor, genera un NULL.
* El uso de CAST fuerza la interpretacion como cadena de texto. 
* Ese "varchar" admite hasta 30 caracteres. El cast luego truncará, sino debe indicarse tamaño.
* El pivot lleva nombre. El error por no indicarlo no es intuitivo.
* Usamos corchetes en los valores de columna de PIVOT.
*/

-- Si no queremos usar CTE, podemos usar una subconsulta.
select *
from (select monto, 
		Ciudad, 
		cast(month(fecha) as varchar) + '-' + cast(year(fecha) as varchar)  Mes
	from ddbba.Venta) SubConsultaConNombre
pivot(sum(monto) for Mes in ([1-2023],[2-2023],[3-2023],[4-2023],[5-2023],[6-2023],[7-2023]) ) Cruzado

/*
Necesitamos que el campo para pivot este disponible previamente
Por eso va la subconsulta o la CTE
*/
-- Otro ejemplo. Repasemos la estructura
select top 20 *
from ddbba.nota

/*
Observe que ahora no es necesaria una subconsulta, el campo "materia" se interpreta tal cual
El uso de la funcion de agregado es obligatorio. 
*/
select *
from ddbba.nota
pivot ( max(nota) for materia in (Reposteria, Filologia, Hermenéutica) ) A

/*
¿Qué pasa si falta el valor de un cruce?
Veamos. Rompamos algo.
*/
Delete from ddbba.Nota
where alumno='Juan Bochazo' and materia='Filologia'

-- a ver que pasa...
select *
from ddbba.nota
pivot ( max(nota) for materia in (Reposteria, Filologia, Hermenéutica) ) A

/*
¿Qué tendríamos que hacer para que no aparezca asi?
*/
select alumno, isnull(Reposteria,0) Reposteria, isnull(Filologia,0) Filología, isnull(Hermenéutica,0) Hermenéutica
From (
	select *
	from ddbba.nota
	pivot ( max(nota) for materia in (Reposteria, Filologia, Hermenéutica) ) A
) B

-- Claramente no es práctico codificar los nombres de las materias
-- Añadamos algo de SQL dinámico a la receta
-- Vengan todas las materias que quieran, con esta consulta no hay limite. Las atendemos a todas.

declare @cadenaSQL nvarchar(max)
set @cadenaSQL = 'select alumno '
-- Select opera en forma iterativa. Notar que no necesito nada extra para concatenar
-- Cuando usamos COALESCE es porque al principio la variable puede tener NULL y concatenar con NULL, da NULL
select  @cadenaSQL =  @cadenaSQL + ', isnull(' + rtrim(materia) + ', 0) ' + materia
from ddbba.nota
group by materia

set @cadenaSQL = @cadenaSQL + ' From (
	select *
	from ddbba.nota 
	pivot ( max(nota) for materia in ('
select  @cadenaSQL =  @cadenaSQL  + rtrim(materia) + ','
from ddbba.nota
group by materia
-- saco una coma "extra" con funciones de cadena
set @cadenaSQL = left(@cadenaSQL,len(@cadenaSQL)-1) + ')) A ) B'
-- la vieja confiable del debugging de sql dinamico
-- print @cadenaSQl
execute sp_executesql @cadenaSQL;