-- Trabajo Práctico 1
-- Base de Datos II

-- 1) Insertar en la tabla region: Noroeste Argentino, con ID 5
insert into region values
(5,'Noroeste Argentino')
;


-- 2) Insertar en la tabla territories al menos 5 territorios de la nueva región
-- utilizando la sintaxis multirow de INSERT
select * from territories where regionid = 5;
insert into territories values
	(233,'San Juan',5),
	(522,'Mendoza',5),
	(512,'Chaco',5),
	(572,'Misiones',5),
	(562,'Salta',5)
;

-- 3) Crear una tabla tmpterritories con los siguientes atributos
    -- territoryid
    -- territorydescription
    -- regionid
    -- regiondescription
create table tmpterritories(
	territoryid varchar(20), foreign key (territoryid) references territories,
    territorydescription varchar(50),
    regionid int4, foreign key (regionid) references region,
    regiondescription varchar(50)
);

-- 4) Mediante la sintaxis INSERT ... SELECT llenar la tabla del punto 3
-- combinando información de las tablas region y territories
truncate table tmpterritories;
select * from tmpterritories;
insert into tmpterritories
	select 
		territoryid,
    	territorydescription,
    	regionid,
    	regiondescription
    from territories inner join region using(regionid)
    returning *
 ;

-- 5) Agregar dos columnas a la tabla customers donde se almacene:
    -- ordersquantity: con la cantidad de órdenes del cliente en cuestión
    -- ordersamount: el importe total de las órdenes realizadas
alter table customers add column ordersquantity int4 default 0;
alter table customers add column ordersamount numeric(10,2) default 0;

-- 5.a) Mediante sentencia UPDATE ... FROM actualizar las columnas agregadas
update customers c
set 
	ordersquantity = a.ordersquantity,
	ordersamount = b.ordersamount 
from 
	(
	select 
		o.customerid,
		count(o.orderid) as ordersquantity
	from orders o
	group by o.customerid
	) as a,
	(
	select  
		o.customerid,
		sum(od.unitprice * od.quantity - od.discount) as ordersamount
	from orders o inner join orderdetails od using(orderid)
	group by o.customerid
	) as b
where 
	c.customerid = a.customerid and
	c.customerid = b.customerid
;

select customerid, ordersquantity, ordersamount
from customers
order by ordersamount desc 
;

update customers c
set 
	ordersquantity = 0,
	ordersamount = 0
;

-- 5.b) Mediante sentencia UPDATE y subconsulta actualizar las col
update customers c
set ordersquantity = (
	select count(o.orderid)
	from orders o
	where c.customerid = o.customerid
	),
	ordersamount = (
	select coalesce(sum(od.unitprice*od.quantity-od.discount),0)
	from orders o inner join orderdetails od using(orderid)
	where c.customerid = o.customerid
	)
;

-- 6) Desarrollar las sentencias necesarias que permitan eliminar todo el
-- historial de òrdenes de un cliente cuyo dato conocido es companyname,
-- utilizando DELETE ... USING


-- Primero se eliminan los detalles, porque hacen referencia (FK) a las órdenes
-- que se quieren eliminar
delete from orderdetails od
using customers c, orders o
where 
	c.companyname ilike '%companyname%' and
	c.customerid = o.customerid and
	od.orderid = o.orderid 
;
	

-- Una vez eliminados los detalles, se eliminan las órdenes

--
-- Trabajo Práctico 2
-- Base de Datos II

-- A) Crear una función que permita eliminar espacios en blanco innecesarios
-- (trim) de una columna de una tabla. Los nombres de columna y tabla deben ser
-- pasados como parámetros y la función deberá devolver como resultado la
-- cantidad de filas afectadas.


-- B) Programar una función que reciba como parámetro un orderid y devuelva una
-- cadena de caracteres (resumen) con el id, nombre, precio unitario y cantidad
-- de todos los productos incluidos en la orden en cuestión.



-- D) Crear una función que muestre por cada detalle de orden: el nombre del
-- cliente, la fecha, la identificación de cada artículo (id y nombre),
-- cantidad, importe unitario y subtotal de cada ítem para un intervalo de
-- tiempo dado por parámetros.


-- E) Función para el devolver el total de una orden dada por parámetro.

-- F) Crear una función donde se muestren todos los atributos de cada Orden
-- junto a Id y Nombre del Cliente y el Empleado que la confeccionó. Mostrar el
-- total utilizando la función del punto anterior.


-- G) Crear una función que muestre, por cada mes del año ingresado por
-- parámetro, la cantidad de órdenes generada, junto a la cantidad de órdenes
-- acumuladas hasta ese mes (inclusive).


-- H) Crear una función que permita generar las órdenes de compra necesarias
-- para todos los productos que se encuentran por debajo del nivel de stock,
-- para esto deberá crear una tabla de órdenes de compra y su correspondiente
-- tabla de detalles.




-- I) Crear una función que calcule y despliegue por cada país destino de
-- ordenes (orders.shipcountry) y por un rango de tiempo ingresado por
-- parámetros la cantidad de productos diferentes que se vendieron y la cantidad
-- de clientes diferentes. Ejemplo de salida:
-- shipcountry productos clientes
-- Argentina   20        5
-- Austria     45        12
-- Belgium     9         2
-- ...         ...       ...
-- Los valores son solo ejemplos.


-- J) Inventar una única función que combine RETURN QUERY, recorrido de
-- resultados de SELECT y RETURN NEXT. Indicar, además del código, qué se espera
-- que devuelva la función inventada.


-- Trabajo Práctico 2
-- Base de Datos II
-- Grupo 3:
    -- Rodrigo Kanchi Flores
    -- Maximiliano Ezequiel Rivas
    -- Ezequiel Lizandro Dzioba

-- a. Crear un disparador para impedir que ingresen dos proveedores en el mismo 
-- domicilio. (tener en cuenta la ciudad y país).

-- b. Realizar un disparador que impida incluir en un detalle de orden, cantidades no 
-- disponibles. 

-- c. Realizar un disparador que actualice el nivel de stock cuando se crean, modifican o 
-- eliminan órdenes (y sus detalles). 


-- d. Realizar un disparador de auditoría sobre la actualización de datos de los clientes. Se 
-- debe almacenar el nombre del usuario la fecha en la que se hizo la actualización, la 
-- operación realizada (alta/baja/modificación) y el valor que tenía cada atributo al 
-- momento de la operación. 

-- e. Agregar atributos en el encabezado de la Orden que registren la cantidad de artículos 
-- del detalle y el importe total de cada orden. Realizar los triggers necesarios para 
-- mantener la redundancia controlada de los nuevos atributos.


-- F) Realizar triggers a elección para probar las siguientes combinaciones y
-- situaciones respondiendo las siguientes consultas:

-- i. ¿Qué sucede con la variable NEW?

-- ii. ¿Qué sucede ante un RETURN NULL?

-- iii. ¿Qué sucede ante un RAISE EXCEPTION?

-- iv. ¿Qué sucede con la variable NEW?

-- v. ¿Qué sucede ante una modificación de valores de NEW y RETURN NEW?

-- vi. ¿Qué sucede ante un RETURN NULL?

-- vii. ¿Qué sucede ante un RAISE EXCEPTION?


--TP4 Funciones de Ventana

-- 1. Listar id, apellido y nombre de los cliente ordenados en un ranking decreciente, según la 
-- función del contacto (dentro de la empresa) contacttitle.
	
-- 2. Mostrar, por cada mes del año 1997, la cantidad de ordenes generadas, junto a la cantidad de 
-- ordenes acumuladas hasta ese mes (inclusive). El resultado esperado es el mismo que el 
-- obtenido en el ejercicio 2.g del trabajo práctico 1.

-- 3. Listar todos los empleados agregando las columnas: salario, salario promedio, ranking según 
-- salario del empleado, ranking según salario del empleado en la ciudad. Utilizando la definición 
-- explícita de ventanas

-- 4. Listar los mismos datos del punto anterior agregando una columna con la diferencia de salario 
-- con el promedio. Utilizando la definición explícita de ventanas

-- 5. Crear una tabla con movimientos históricos de productos y llenarla con los datos 
-- correspondientes. La misma debe tener para cada producto, todas la órdenes en las que fue 
-- comprado, en forma cronológica con las siguientes columnas:
-- productid, 
-- operationorder: autonumerado que comienza en uno para cada producto distinto), 
-- orderdate: fecha de la orden, 
-- companyname, 
-- quantity: cantidad de productos de la orden en cuestión
-- Las primeras 3 filas deberían tener la siguiente información:

-- productid operationorder orderdate Companyname 					Quantity
-- 1			 1 			1996-08-20 QUICK-Stop 					  45
-- 1			 2			1996-08-30 Rattlesnake Canyon Grocery 	  18
-- 1			 3			1996-09-30 Lonesome Pine Restaurant 	  20


-- 6. Listar apellido, nombre, ciudad y salario de los empleados acompañado de la resta del salario 
-- con el salario de la fila anterior de la misma ciudad. El resultado esperado es similar a:
