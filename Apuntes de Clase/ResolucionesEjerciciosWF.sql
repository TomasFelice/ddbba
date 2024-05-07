use  PracticaWF
go

---1---

SELECT EmpleadoID, Nombre, Departamento, Salario,
    ROW_NUMBER() OVER (ORDER BY Salario DESC) AS OrdenEmpleadosSalario
FROM tablaswf.Empleados
go
---2---

SELECT EmpleadoID, Nombre, Departamento, Salario,
    RANK() OVER (PARTITION BY Departamento ORDER BY Salario DESC) AS Ranking
    FROM tablaswf.empleados
go
---3---

	SELECT EmpleadoID, Nombre, Departamento, Salario,
    NTILE(4) OVER (ORDER BY Salario DESC) AS GrupoSalario
	FROM tablaswf.Empleados
go
---4---

	SELECT EmpleadoID, Nombre, Departamento, Salario,
    LAG(Salario, 1, 0) OVER (PARTITION BY Departamento ORDER BY Salario) AS SalarioAnterior,
    LEAD(Salario, 1, 0) OVER (PARTITION BY Departamento ORDER BY Salario) AS SiguienteSalario
    FROM tablaswf.Empleados
go
---5---

SELECT id_pedido, id_cliente, monto,
    AVG(monto) OVER (PARTITION BY id_cliente) AS promedio_monto_cliente,
    ROW_NUMBER() OVER (PARTITION BY id_cliente ORDER BY monto) AS posicion_rel_monto_cliente
FROM tablaswf.Pedidos;
go

---6---
SELECT *
FROM (
    SELECT 
        c.nombre,
        c.pais,
        SUM(p.monto) AS monto_total_pedidos,
        RANK() OVER (PARTITION BY c.pais ORDER BY SUM(p.monto) DESC) AS ranking_por_pais
    FROM tablaswf.Clientes c
    INNER JOIN tablaswf.Pedidos p ON c.id_cliente = p.id_cliente
    GROUP BY c.nombre, c.pais
) ranked_clients
WHERE ranking_por_pais <= 3;
go

---7---
SELECT id_pedido, id_cliente, fecha_pedido, monto,
    LEAD(monto) OVER (PARTITION BY id_cliente ORDER BY fecha_pedido) AS diferencia_monto
FROM tablaswf.Pedidos
ORDER BY id_cliente, fecha_pedido;
go

---8---

SELECT p.id_pedido,p.id_cliente,c.pais,p.monto,
    PERCENT_RANK() OVER (PARTITION BY c.pais ORDER BY p.monto) AS percentil_monto
FROM tablaswf.Pedidos p
INNER JOIN tablaswf.Clientes c ON p.id_cliente = c.id_cliente
ORDER BY c.pais, p.monto;
go

---9---

SELECT  p.id_pedido, p.id_cliente, c.nombre AS nombre_cliente,
    COUNT(*) OVER (PARTITION BY p.id_cliente) AS total_pedidos_cliente,
    ROW_NUMBER() OVER (PARTITION BY p.id_cliente ORDER BY p.fecha_pedido) AS posicion_rel_pedidos_cliente
FROM tablaswf.Pedidos p
JOIN tablaswf.Clientes c ON p.id_cliente = c.id_cliente
ORDER BY p.id_cliente, p.fecha_pedido;

