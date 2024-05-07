use master
go

if not exists ( select name from master.dbo.sysdatabases where name = 'PracticaWF')
begin
	create database PracticaWF
	collate Latin1_General_CI_AI;
end
go

use PracticaWF
go

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'tablasWF')
BEGIN
	EXEC('CREATE SCHEMA tablasWF')
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA = 'tablasWF' AND TABLE_NAME = 'Empleados')
BEGIN
	CREATE TABLE tablaswf.Empleados (
	 EmpleadoID INT identity(1,1) primary key,
	Nombre VARCHAR(50),
	Departamento VARCHAR(50),
	Salario DECIMAL(10, 2)
)
END
GO

INSERT INTO tablaswf.Empleados (Nombre, Departamento, Salario)
VALUES
('Juan', 'Ventas', 3000.00),
('María', 'Ventas', 2800.00),
('Pedro', 'Marketing', 3200.00),
('Laura', 'Marketing', 3500.00),
('Carlos', 'IT', 4000.00)
go


-- (1)
--Enumerar, de mayor a menor, los empleados de una tabla según el salario que poseen

select e.EmpleadoID, e.Nombre, e.Departamento, e.Salario, rank() over (order by e.Salario desc) OrdenEmpleadosSalario
from tablasWF.Empleados e

-- Insertamos más datos
INSERT INTO tablaswf.Empleados (Nombre, Departamento, Salario)
VALUES
('Ramiro', 'Ventas', 1800.00),
('Tomas', 'Ventas', 3200.00),
('Erik', 'Marketing', 1477.00),
('Esteban', 'Marketing', 15000.00),
('Laura', 'IT', 452.00),
('Romina', 'Ventas', 7855.00),
('Susana', 'Ventas', 1233.00),
('Mateo', 'Marketing', 4755.00),
('Nicolas', 'Marketing', 1236.00),
('Federico', 'IT', 260611.00),
('Miguel', 'Ventas', 4688.00),
('Josefina', 'Ventas', 2855.00),
('Franco', 'Marketing', 7456.00),
('Cesar', 'Marketing', 2555.00),
('Patricio', 'IT', 4000.00)

-- (2)
-- Clasifica a los empleados del ejercicio anterior según sus salarios agrupado por departamento.

select e.EmpleadoID, e.Nombre, e.Departamento, e.Salario, rank() over (partition by e.Departamento order by e.Salario desc) Ranking
from tablasWF.Empleados e

-- (3)
-- Dividí a los empleados del ejercicio anterior en 4 grupos basados en su salario. El grupo 1 
-- contendrá a los empleados con los salarios más altos, mientras que el grupo 4 incluirá a 
-- aquellos con los salarios más bajos. Esto permite asignar un grupo a cada empleado en función 
-- de su nivel de salario dentro de la empresa.

select e.EmpleadoID, e.Nombre, e.Departamento, e.Salario, ntile(4) over (order by e.salario desc) GrupoSalario
from tablasWF.Empleados e

-- (4)
-- Realizar una comparación de salarios entre empleados (del ejercicio anterior) para analizar la 
-- diferencia de salario entre el empleado actual y el siguiente, así como el salario del empleado 
-- anterior, dentro de un mismo departamento. 
-- Generar una consulta que muestre, para cada empleado, su salario actual, el salario del 
-- empleado anterior en orden ascendente de salarios dentro del mismo departamento, y el salario 
-- del empleado siguiente en el mismo orden de salarios. Esta comparación permitirá visualizar 
-- cómo varían los salarios entre los empleados, mostrando la relación de los salarios con respecto 
-- al empleado anterior y posterior en términos de monto

select	e.EmpleadoID,
		e.Nombre,
		e.Departamento,
		e.Salario,
		lag(e.Salario, 1, 0) over (partition by e.Departamento order by e.salario asc) SalarioAnterior,
		lead(e.Salario, 1, 0) over (partition by e.Departamento order by e.salario asc) SalarioPosterior
from tablasWF.Empleados e

/*
	CREACION TABLA CLIENTES
*/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE
TABLE_SCHEMA =
'tablasWF' AND TABLE_NAME =
'Clientes')
BEGIN
CREATE TABLE tablaswf.Clientes (
 id_cliente INT identity(1,1) PRIMARY KEY,
nombre VARCHAR(50),
pais VARCHAR(50)
)
END
GO

/*
	CREACION TABLA PEDIDOS
*/

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA =
'tablasWF' AND TABLE_NAME =
'Pedidos')
BEGIN
CREATE TABLE tablaswf.Pedidos (
 id_pedido INT PRIMARY KEY,
id_cliente INT,
fecha_pedido DATE,
monto DECIMAL(10, 2),
 FOREIGN KEY (id_cliente) REFERENCES tablaswf.Clientes(id_cliente)
)
END
GO

/*
	INSERCION DATOS CLIENTES
*/

INSERT INTO tablaswf.Clientes
(nombre
, pais
)
VALUES ('John Doe', 'Argentina'), ('Jane Smith', 'Australia'), ('Juan García', 'Brasil'), ('Maria Hernandez', 'Canadá'), ('Michael Johnson', 'China'), ('Sophie Martin', 'Dinamarca'), ('Ahmad Khan', 'Egipto'), ('Emily Brown', 'Francia'), ('Hans Müller', 'Alemania'), ('Sofia Rossi', 'Italia'), ('Takeshi Yamada', 'Japón'), ('Javier López', 'México'), ('Eva Novak', 'Países Bajos'), ('Rafael Silva', 'Portugal'), ('Olga Petrova', 'Rusia'), ('Fernanda Gonzalez', 'España'), ('Mohammed Ali', 'Egipto'), ('Lena Schmidt', 'Alemania'), ('Yuki Tanaka', 'Japón'), ('Lucas Costa', 'Brasil');

/*
	INSERCION DATOS PEDIDOS
*/

DECLARE @startDate DATE = '2023-01-01';
DECLARE @endDate DATE = '2023-12-31';
DECLARE @orderId INT = 1;
WHILE @orderId <= 100
BEGIN
INSERT INTO tablaswf.Pedidos (id_pedido,id_cliente, fecha_pedido, monto)
VALUES (
@orderId,
((@orderId - 1) % 20) + 1,
 DATEADD(DAY, ABS(CHECKSUM(NEWID())) % (DATEDIFF(DAY, @startDate, @endDate) + 1),
@startDate),
 ROUND(RAND(CHECKSUM(NEWID())) * 5000 + 1000, 2)
);
SET @orderId = @orderId + 1;
END

/*
	(5)

	Calcular el promedio de los montos de pedidos por cliente, mostrando también el monto de cada 
	pedido y su posición relativa en comparación con el promedio de los montos para ese cliente.
*/

SELECT	p.id_pedido,
		p.id_cliente,
		p.monto,
		avg(p.monto) over (partition by p.id_cliente) promedio_monto_cliente,
		rank() over (partition by p.id_cliente order by monto asc) posicion_rel_monto_cliente
FROM tablasWF.Pedidos p

/*
	(6)

	Encontrar a los tres principales clientes (por monto total de pedidos) de cada país, mostrando 
	su nombre, país y el monto total de sus pedidos.

*/

select * from (
	select		c.nombre,
				c.pais,
				sum(p.monto) monto_total_pedidos,
				rank() over (partition by c.pais order by sum(p.monto) desc) ranking_por_pais
	from		tablasWF.Clientes c
	inner join	tablasWF.Pedidos p on c.id_cliente = p.id_cliente
	group by c.nombre, c.pais
) ranking_clientes
where ranking_por_pais <= 3

/*
	(7)

	Calcular la diferencia de monto entre un pedido y el siguiente pedido realizado por el mismo 
	cliente, ordenado por fecha de pedido. Muestra el ID del pedido, el ID del cliente, la fecha del 
	pedido y la diferencia de monto.

*/

select	p.id_pedido,
		p.id_cliente,
		p.fecha_pedido,
		p.monto,
		( lead(p.monto, 1, null) over (partition by p.id_cliente order by p.fecha_pedido asc) - p.monto ) diferencia_monto
from tablasWF.Pedidos p
order by p.id_cliente, p.fecha_pedido

/*
	(8)

	Determina el percentil de monto de cada pedido en relación con todos los pedidos realizados 
	por clientes del mismo país. Muestra el ID del pedido, el ID del cliente, el monto del pedido y 
	su percentil.

*/

select	p.id_pedido, p.id_cliente, p.monto, c.pais,
		percent_rank() over (partition by c.pais order by p.monto) percentil_monto
from tablasWF.Pedidos p
inner join tablasWF.Clientes c on p.id_cliente = c.id_cliente
order by c.pais, p.monto

/*
	(9)

	Para cada cliente, muestra el ID del pedido, el número total de pedidos realizados por ese cliente, 
	su nombre y la posición relativa de cada pedido en relación con el total de pedidos del cliente 
	(ordenados por fecha de pedido).

*/

select	p.id_pedido, c.id_cliente, c.nombre, p.fecha_pedido,
		count(1) over (partition by c.id_cliente) total_pedidos_cliente,
		row_number() over (partition by c.id_cliente order by p.fecha_pedido) posision_relativa_pedido_cliente
from tablasWF.Clientes c
inner join tablasWF.Pedidos p on c.id_cliente = p.id_cliente