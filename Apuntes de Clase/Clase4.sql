create database [DBDatosEnMemoria]
	containment = none
	on primary
	( name = N'PruebasDisco', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\DBDatosEnDisco.mdf'),
	filegroup [Memoria] contains memory_optimized_data default
	( name = N'PruebasMemoria', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\DBDatosEnMemoria.mdf')
	log on
	( name = N'Probanding_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\DBDatosEnMemoria_log.ldf')

