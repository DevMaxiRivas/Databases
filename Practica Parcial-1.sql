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
delete from orders o
using customers c
where 
	c.companyname ilike '%companyname%' and
	c.customerid = o.customerid 
;

--
-- Trabajo Práctico 2
-- Base de Datos II

-- A) Crear una función que permita eliminar espacios en blanco innecesarios
-- (trim) de una columna de una tabla. Los nombres de columna y tabla deben ser
-- pasados como parámetros y la función deberá devolver como resultado la
-- cantidad de filas afectadas.

create or replace function delete_trim(pt_columnname text, pt_tablename text)
returns int
as 
$$
declare li_quantity int;
begin
	execute 
		format( 
		'update %1$I
		 set %2$I = trim(%2$I)
		 where %2$I != trim(%2$I)
		 ;'
		,pt_tablename,pt_columnname)
	;
	get diagnostics li_quantity = ROW_COUNT;
	return li_quantity;
end;
$$
language plpgsql;

select * from delete_trim('companyname','customers'); 

-- B) Programar una función que reciba como parámetro un orderid y devuelva una
-- cadena de caracteres (resumen) con el id, nombre, precio unitario y cantidad
-- de todos los productos incluidos en la orden en cuestión.

create or replace function detalle_orden(pi_orderid integer)
returns text as $$
declare
    lr_fila record;
    lt_texto text := '';
begin
    for lr_fila in
        select p.productid, p.productname, od.unitprice, od.quantity
        from products p join orderdetails od using(productid)
        where orderid = pi_orderid
    loop
        lt_texto := format(
            e'%1s %2s - %2$ - %s - %s\n',
            lt_texto,
            lr_fila.productid,
            trim(lr_fila.productname),
            lr_fila.unitprice,
            lr_fila.quantity
        );
    end loop;
    return lt_texto;
end;
$$ language plpgsql;

-- c) prueba con orderid = 11077

select detalle_orden(11077);


-- D) Crear una función que muestre por cada detalle de orden: el nombre del
-- cliente, la fecha, la identificación de cada artículo (id y nombre),
-- cantidad, importe unitario y subtotal de cada ítem para un intervalo de
-- tiempo dado por parámetros.

DROP FUNCTION intervalo_orders(date,date);
CREATE OR replace FUNCTION intervalo_orders(pd_desde date, pd_hasta date)
RETURNS TABLE (
	companyname varchar(40),
	orderdate date,
	productid int4,
	productname varchar(40),
	quantity int4,
	unitprice numeric(10,2),
	subtotal numeric(10,2)
) AS 
$$
BEGIN
	RETURN query
		SELECT
			c.companyname,
			o.orderdate, 
			p.productid, 
			p.productname,
			od.quantity, 
			od.unitprice,
			od.quantity * od.unitprice - od.discount
		FROM
			customers c
			INNER JOIN orders o using(customerid)
			INNER JOIN orderdetails od using(orderid)
			INNER JOIN products p using(productid)
		WHERE o.orderdate BETWEEN pd_desde AND pd_hasta
		ORDER BY o.orderid
		;
END;
$$
LANGUAGE plpgsql;


SELECT * FROM intervalo_orders('1996-07-04', '1997-01-01');

-- E) Función para el devolver el total de una orden dada por parámetro.

create or replace function return_total_orden(pi_orderid int4)
returns numeric(10,2) as
$$
declare ln_total numeric(10,2);
begin
	select coalesce(sum(quantity * unitprice - discount),0)
	into ln_total 
	from orderdetails
	where orderid = pi_orderid
	;
	return ln_total;
end;
$$
language plpgsql;

select * from return_total_orden(10248);


-- F) Crear una función donde se muestren todos los atributos de cada Orden
-- junto a Id y Nombre del Cliente y el Empleado que la confeccionó. Mostrar el
-- total utilizando la función del punto anterior.
create or replace function orden_detallada()
returns table(
	orderid INTEGER,
    customerid VARCHAR(10),
    employeeid INTEGER,
    orderdate DATE,
    requireddate DATE,
    shippeddate DATE,
    shipvia INTEGER,
    freight NUMERIC(10, 2),
    shipname VARCHAR(40),
    shipaddress VARCHAR(60),
    shipcity VARCHAR(15),
    shipregion VARCHAR(15),
    shippostalcode VARCHAR(10),
    shipcountry VARCHAR(15),
    cliente VARCHAR(40), -- nuevo
    empleado TEXT, -- nuevo
    total NUMERIC(10, 2) -- nuevo
) as
$$
begin
	return query
		select
			o.*,
			c.companyname,
			concat(e.lastname,' ',e.firstname), 
			(select * from return_total_orden(o.orderid))
		from 
			customers c
			inner join orders o using(customerid)
			inner join employees e using(employeeid)
	;					
end;
$$
language plpgsql;

SELECT orderid, customerid, empleado,total FROM orden_detallada();

-- G) Crear una función que muestre, por cada mes del año ingresado por
-- parámetro, la cantidad de órdenes generada, junto a la cantidad de órdenes
-- acumuladas hasta ese mes (inclusive).
create or replace function muestra_mes(pi_year int4)
returns table(
	mes text,
	cantidad int4,
	acumuladas int4
) as 
$$
begin
	acumuladas := 0;
	for mes, cantidad in (
		select 
			to_char(orderdate,'TMMonth') as month,
			count(orderid) as quantity
			from orders
			where date_part('year',orderdate) = pi_year
			group by date_part('month',orderdate),1
	) loop
		acumuladas = acumuladas + cantidad;
		return next;
	end loop;
	
end;
$$
language plpgsql;

SELECT * FROM muestra_mes('1997');

-- H) Crear una función que permita generar las órdenes de compra necesarias
-- para todos los productos que se encuentran por debajo del nivel de stock,
-- para esto deberá crear una tabla de órdenes de compra y su correspondiente
-- tabla de detalles.

create table orderssupliers(
	orderid serial primary key,
	supplierid int4, foreign key (supplierid) references suppliers,
	orderdate date
);
create table orderdetailssupliers(
	orderid integer not null, foreign key (orderid) references orderssupliers,
	productid integer not null, foreign key (productid) references products,
	quantity int4,
	primary key(orderid, productid)
);

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


-- Trabajo Práctico 3
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


-- TP4
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


-- Muestra todos los productos agregando el promedio de precios y cantidad por categoria


-- Define una ventana "particionando" por nombre de la categoria y por el nombre del producto


-- Define una ventana "particionando" por nombre de la categoria y "ordenamos" por el nombre del producto


-- Muestra todos los productos repitiendo en cada fila el promedio general


-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria


-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
-- Agregando la diferencia entre el precio de cada producto 
-- y el promedio segun categoria
 


-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
-- Agregando la diferencia entre el precio de cada producto 
-- y el promedio segun categoria
-- Agregando ranking de precios por categoria


-- Diferencia entre dense_rank() y rank() 
-- Por ejemplo rank() si se tiene dos filas con rank 3 el siguiente en el ranking sera 5
-- Por ejemplo dense_rank() si se tiene dos filas con rank 3 el siguiente en el ranking sera 4
