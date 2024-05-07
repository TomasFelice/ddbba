USE pruebasddbba
GO

/*
IMPORTANTE:
No recomendamos el uso en productivo de SQL Server para acceso a APIs web 
Existen muchas alternativas para hacerlo de muchisimas maneras distintas
con otros lenguajes mucho mas amigables y avanzados.

Dado que la materia DDBBA la pueden cursar sin haber avanzado tanto en
programacion, incluimos esta guia para darles un primer contacto con las
API con el lenguaje que van conociento: T-SQL.

Ademas... esta re copado.

Para ejecutar un llamado a una API desde SQL primero vamos a tener que 
habilitar ciertos permisos que por default vienen bloqueados.
En este caso, 'Ole Automation Procedures' permite a SQL Server 
utilizar el controlador OLE para interactuar con los objetos COM.
(excede el alcance de la materia profundizar sobre OLE y objetos COM,
que por otra parte están bastante obsoletos)
*/

EXEC sp_configure 'show advanced options', 1;	--Este es para poder editar los permisos avanzados.
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	-- Aqui habilitamos esta opcion avanzada
RECONFIGURE;
GO

--	Para empezar vamos a utilizar una API pública que devuelve la hora
--  Muchas API publicas requieren un token que obtenemos al registrarnos
--	Pero esta no... por eso nos gustó
--	Referencia: https://www.worldtimeapi.org

--	Armamos el URL del llamado tal como hallamos en la doc de la API
DECLARE @ruta NVARCHAR(64) = 'https://www.worldtimeapi.org/api/timezone'
DECLARE @continente NVARCHAR(64) = 'America'
DECLARE @pais NVARCHAR(64) = 'Argentina'
DECLARE @provincia NVARCHAR(64) = 'Cordoba'
DECLARE @url NVARCHAR(256) = CONCAT(@ruta, '/', @continente, '/', @pais, '/', @provincia)
-- Observe que podemos usar CONCAT para concatenar strings, tambien lo hemos hecho con el operador +
-- Nos queda asi:
PRINT @url
-- En vez de hacer un print y verlo en la consola, podemos guardar 
-- el llamado en un log y revisar el mismo si el sistema no funciona como queremos.

-- Esto lo podemos comparar con la referencia de https://www.worldtimeapi.org/pages/examples
-- (ahora ejecutar hasta el siguiente GO)
DECLARE @Object INT
DECLARE @json TABLE(respuesta NVARCHAR(MAX))	-- Usamos una tabla variable
DECLARE @respuesta NVARCHAR(MAX)

EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT	-- Creamos una instancia del objeto OLE, que nos permite hacer los llamados.
EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE' -- Definimos algunas propiedades del objeto para hacer una llamada HTTP Get.
EXEC sp_OAMethod @Object, 'SEND' 
EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT --, @json OUTPUT -- Señalamos donde vamos a guardar la respuesta.

-- Observe que si el SP devuelve una tabla lo podemos almacenar con INSERT
INSERT @json 
	EXEC sp_OAGetProperty @Object, 'RESPONSETEXT' -- Obtenemos el valor de la propiedad 'RESPONSETEXT' del objeto OLE luego de realizar la consulta.

SELECT respuesta FROM @json
Go


-- Perfecto, confirmamos que funciona y recibimos datos,
-- nos resta darle a ese json una forma que nos sea útil
-- Repetiremos el codigo y agregamos la interpretacion del JSON
DECLARE @ruta NVARCHAR(64) = 'https://www.worldtimeapi.org/api/timezone'
DECLARE @continente NVARCHAR(64) = 'America'
DECLARE @pais NVARCHAR(64) = 'Argentina'
DECLARE @provincia NVARCHAR(64) = 'Cordoba'
DECLARE @url NVARCHAR(256) = CONCAT(@ruta, '/', @continente, '/', @pais, '/', @provincia)
DECLARE @Object INT
DECLARE @json TABLE(DATA NVARCHAR(MAX))
DECLARE @respuesta NVARCHAR(MAX)

EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT
EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'
EXEC sp_OAMethod @Object, 'SEND'
EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT , @json OUTPUT

-- esta es la sintaxis para insertar una tabla devuelta por un SP 
INSERT INTO @json 
	EXEC sp_OAGetProperty @Object, 'RESPONSETEXT'

DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json)
SELECT * FROM OPENJSON(@datos)
WITH
(
	[Datetime2] datetime2 '$.datetime',
	[FechaHoraISO] nvarchar(40) '$.datetime',
	[Dia del año] int '$.day_of_year',
	[Dia de la semana] int '$.day_of_week',
	[UTC Offset] nvarchar(30) '$.utc_offset'
);
-- Observe que usamos datetime2 porque datetime esta limitada en el rango de años
-- El formato FechaHoraISO es estandar
go

-- Para el siguiente ejemplo vamos con una API que nos sirva un poco más, esta API gratuita de traducción:
-- Fuente: https://mymemory.translated.net/doc/

-- Como con la anterior, vamos a empezar armando el URL, 
-- lo que vamos a necesitar parametrizar es la frase a traducir, el idioma y a que idioma queremos.
DECLARE @ruta NVARCHAR(64) = 'https://api.mymemory.translated.net/get?'
DECLARE @fraseOriginal NVARCHAR(256) = 'How odd to watch a mortal kindle, then to dwindle day by day, knowing their bright souls are tinder, and the wind will have its way'
DECLARE @idiomaOriginal NVARCHAR(8) = 'en'
DECLARE @idiomaTraduccion NVARCHAR(8) = 'es-es'
DECLARE @url NVARCHAR(336) = CONCAT(@ruta, 'q=', @fraseOriginal, '&langpair=', @idiomaOriginal, '|', @idiomaTraduccion)

PRINT @url
-- Ejecutamos hasta aqui si solo queremos ver la URL armada con la consulta
-- Sugerencia: pruebe esa misma URL en Postman

DECLARE @Object INT
DECLARE @json TABLE(DATA NVARCHAR(MAX))
DECLARE @respuesta NVARCHAR(MAX)

EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT
EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE'
EXEC sp_OAMethod @Object, 'SEND'
EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT, @json OUTPUT

INSERT INTO @json 
	EXEC sp_OAGetProperty @Object, 'RESPONSETEXT'

DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json)
SELECT * FROM OPENJSON(@datos)
WITH
(
	[Frase traducida] NVARCHAR(256) '$.responseData.translatedText',
	[Fidelidad] real '$.responseData.match'
);
go

-- Finalmente un ejemplo con una API falsa:
-- https://jsonplaceholder.typicode.com
-- Lo interesante de este ejemplo es como pasarle los parametros, 
-- los dos anteriores eran ejemplos de llamadas GET donde el parametro 
-- va en la url, pero no tiene porque ser así.

DECLARE @url NVARCHAR(64) = 'https://jsonplaceholder.typicode.com/posts'
DECLARE @Object INT
DECLARE @respuesta NVARCHAR(MAX)
DECLARE @json TABLE(DATA NVARCHAR(MAX))
DECLARE @body NVARCHAR(MAX) = 
'{
	"title": "Titulo de prueba",
	"body": "Esto es una prueba.",
	"userId": 1
}'

EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
EXEC sp_OAMethod @Object, 'OPEN', NULL, 'POST', @url, 'FALSE' -- Cambiamos el metodo de GET a POST.
EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Content-Type', 'application/json' -- Agregamos el header que indica que la solicitud viene con un body json.
EXEC sp_OAMethod @Object, 'SEND', NULL, @body -- Enviamos la solicitud y el body.
EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT --, @json OUTPUT

INSERT INTO @json EXEC sp_OAGetProperty @Object, 'RESPONSETEXT'

DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json)
SELECT * FROM OPENJSON(@datos)
WITH
(
	[Titulo] NVARCHAR(256) '$.title',
	[Cuerpo] NVARCHAR(256) '$.body',
	[User Id] int '$.userId',
	[Id] int '$.id'
);