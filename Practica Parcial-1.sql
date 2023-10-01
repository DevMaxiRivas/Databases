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

create or replace function reponer_stock()
returns void as
$$
declare lr_fila RECORD;
declare li_actualsup int4 := '000';
declare li_actualord int4;
begin 
	for lr_fila in(
		select 
			supplierid, 
			productid, 
			unitsonorder - unitsinstock as quantity
		from 
			products
		where 
			not discontinued
			and unitsinstock < reorderlevel
			and unitsonorder - unitsinstock > 0
		order by 1
	) loop 
		if li_actualsup != lr_fila.supplierid then 
			li_actualsup := lr_fila.supplierid; 
			insert into orderssupliers values
			(default,li_actualsup,current_date)
			returning orderid into li_actualord
			;
		end if;
		insert into orderdetailssupliers values
		(li_actualord,lr_fila.productid,lr_fila.quantity)
		;	
	end loop;
end;
$$
language plpgsql;

select * from reponer_stock();
select * 
from 
	orderssupliers 
	inner join orderdetailssupliers using(orderid)
	inner join products using(productid)
;


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
DROP FUNCTION info_pais(date,date);
create or replace function info_pais(pd_desde DATE, pd_hasta DATE)
returns table(
	shipcountry varchar(15),
	productos bigint,
	clientes bigint
) as
$$
begin
	return query
		select
			o.shipcountry,
			count(distinct od.productid) as prods,
			count(distinct c.customerid) as clien
		from
			customers c
			inner join orders o using(customerid)
			inner join orderdetails od using(orderid)
		where orderdate between pd_desde and pd_hasta
		group by 1
	;
end;
$$
language plpgsql;
SELECT * FROM info_pais('1997-01-01', '1997-12-31');

-- J) Inventar una única función que combine RETURN QUERY, recorrido de
-- resultados de SELECT y RETURN NEXT. Indicar, además del código, qué se espera
-- que devuelva la función inventada.

CREATE OR REPLACE FUNCTION return_query_next()
RETURNS TABLE(
    nombre VARCHAR(40),
    telefono VARCHAR(24),
    pais VARCHAR(15),
    rol TEXT
) AS $$
BEGIN
    RETURN QUERY
        SELECT companyname as nombre, phone as telefono, country as pais, 'Cliente' as rol
        FROM customers;
    RETURN QUERY
        SELECT companyname as nombre, phone as telefono, country as pais, 'Proveedor' as rol
        FROM suppliers;
    FOR nombre, telefono, rol IN
        SELECT companyname, phone, 'Transporte'
        FROM shippers
    LOOP
        -- Como 'shippers' no tiene 'country', se infiere a partir del teléfono.
        CASE
            WHEN telefono ILIKE '(50%' THEN
                pais := 'USA';
            ELSE
                pais := NULL;
        END CASE;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

-- La función devuelve una tabla con los nombres de todas las compañias de la
-- base de datos, su teléfono, su país y su rol (cliente, proveedor, rol)
SELECT * FROM return_query_next();


-- Trabajo Práctico 3

-- a. Crear un disparador para impedir que ingresen dos proveedores en el mismo 
-- domicilio. (tener en cuenta la ciudad y país).

create or replace function supplier_ver()
returns trigger as
$$
declare li_supid varchar(60);
begin
	li_supid = (
		select s.supplierid
		from suppliers s
		where 
			trim(s.address) ilike trim(new.address)
			and trim(s.city) ilike trim(new.city)
			and trim(s.country) ilike trim(new.country)
		limit 1
	);
	if li_supid is not null then
		raise notice 'La direccion ya se encuentra registrada en otro proveedor';
		return null;
	else
		return new;
	end if;
end;
$$
language plpgsql;

create or replace trigger supplier_verificacion before update or insert on suppliers
for each row execute procedure supplier_ver();

insert into suppliers values 
(145,'Prueba','MR','MR','49 Gilbert St.','London','Alguna','AAAA','UK','654646','FAX','www.pag.com');



-- b. Realizar un disparador que impida incluir en un detalle de orden, cantidades no 
-- disponibles. 
create or replace function control_stock()
returns trigger as
$$
declare li_stockdisp int4;
begin 
	li_stockdisp = (
		select unitsinstock
		from products
		where productid = new.productid
	);
	if li_stockdisp < new.quantity then
		raise notice 'Stock insuficiente';
		return null;
	else
		return new;
	end if;
end;
$$
language plpgsql;

create or replace trigger controlador_stock before insert or update on orderdetails
for each row execute procedure control_stock();

insert into orderdetails values (10251,1,'123','1000','20');



-- c. Realizar un disparador que actualice el nivel de stock cuando se crean, modifican o 
-- eliminan órdenes (y sus detalles). 
create or replace function modifica_stock()
returns trigger as
$$
begin
	case
		when TG_OP = 'UPDATE' then
			if new.productid = old.productid then
				update products 
				set unitsinstock = unitsinstock + old.quantity - new.quantity
				where productid = new.productid
				;
			else 
				update products 
				set unitsinstock = unitsinstock + old.quantity
				where productid = old.productid
				;
				update products 
				set unitsinstock = unitsinstock - new.quantity
				where productid = new.productid
				;
			end if;
		when TG_OP = 'INSERT' then
			update products 
			set unitsinstock = unitsinstock - new.quantity
			where productid = new.productid
			;
		when TG_OP = 'DELETE' then
			update products 
			set unitsinstock = unitsinstock + old.quantity
			where productid = old.productid
			;
	end case;
	raise notice 'De % paso a %',old.quantity,new.quantity;
	return new;
end;
$$
language plpgsql;

create or replace trigger modificacion_orderdetails after insert or update or delete on orderdetails
for each row execute procedure modifica_stock();

insert into orderdetails values (10248,1,14.00,10,0);
delete from orderdetails where orderid = 10248 and productid  = 4;

update orderdetails set quantity = '15', productid = '4' 
where orderid = '10248' and productid = '1';

update products set unitsinstock = 29 where productid = 1; 
select * from orderdetails where orderid = 10248 and productid =4;
select productid, unitsinstock
from products 
where productid = 4;

-- d. Realizar un disparador de auditoría sobre la actualización de datos de los clientes. Se 
-- debe almacenar el nombre del usuario la fecha en la que se hizo la actualización, la 
-- operación realizada (alta/baja/modificación) y el valor que tenía cada atributo al 
-- momento de la operación. 
create table audits(
	auditid serial primary key,
	user_ name not null,
	modifydate timestamp not null,
	operation text not null,
	before_customerid varchar(5),
	before_companyname varchar(40),
	before_contactname varchar(30),
	before_contacttitle varchar(30),
	before_address varchar(60),
	before_city varchar(15),
	before_region varchar(15),
	before_postalcode varchar(10),
	before_country varchar(15),
	before_phone varchar(24),
	before_fax varchar(24),
	after_customerid varchar(5),
	after_companyname varchar(40),
	after_contactname varchar(30),
	after_contacttitle varchar(30),
	after_address varchar(60),
	after_city varchar(15),
	after_region varchar(15),
	after_postalcode varchar(10),
	after_country varchar(15),
	after_phone varchar(24),
	after_fax varchar(24)	
);

select current_timestamp, now() from customers limit 1;

create or replace function audit()
returns trigger as
$$
begin 
	case 
		when TG_OP = 'UPDATE' then
			insert into audits values
			(
			default,current_user,now(),'MODIFICACION',
			old.*,new.*
			)
			;
		when TG_OP = 'INSERT' then
			insert into audits(
			auditid,
			user_,
			modifydate,
			operation,
			after_customerid, 
			after_companyname, 
			after_contactname, 
			after_contacttitle, 
			after_address, 
			after_city, 
			after_region, 
			after_postalcode, 
			after_country, 
			after_phone, 
			after_fax
			) values
			(default,current_user,current_timestamp,'ALTA',new.*)
			;
		when TG_OP = 'DELETE' then
			insert into audits(
			auditid,
			user_,
			modifydate,
			operation,
			before_customerid,
			before_companyname,
			before_contactname,
			before_contacttitle,
			before_address, 
			before_city, 
			before_region, 
			before_postalcode, 
			before_country, 
			before_phone, 
			before_fax
			) values 
			(default,current_user,current_timestamp,'BAJA',old.*)
			;
	end case;
	return new;
end;
$$
language plpgsql;

create or replace trigger auditoria after update or insert or delete on customers
for each row execute procedure audit();

--Test
truncate audits;
select * from audits;

insert into customers values
('NEWUS','Alfreds Futterkiste','Maria Anders','Sales Representative','Obere Str. 57',
'Berlin','12209','Germany','030-0074321','030-0076545')
;
update customers set contactname = 'NEWCO' where customerid ilike '%NEWUS%';
delete from customers where customerid ilike '%NEWUS%';

-- e. Agregar atributos en el encabezado de la Orden que registren la cantidad de artículos 
-- del detalle y el importe total de cada orden. Realizar los triggers necesarios para 
-- mantener la redundancia controlada de los nuevos atributos.
alter table orders add column quantity int4;
alter table orders add column amount money;

create or replace function total_orders(pi_orderid int4)
returns table(
	quantity int4,
	amount money
) as 
$$
begin
	return query
		select
			coalesce(sum(od.quantity),0)::int4,
			coalesce(sum(od.quantity * od.unitprice - od.discount),0)::money
		from orderdetails od
		where pi_orderid = od.orderid
	;
end;
$$
language plpgsql;

select * from total_orders(10248);


create or replace function recalcular_orden()
returns trigger as
$$
declare li_quantity int4;
declare li_amount money;
begin 
	select * into li_quantity, li_amount from total_orders(new.orderid);
	if li_quantity > 0 then
		update orders
		set quantity = li_quantity, amount = li_amount
		where orderid = new.orderid or old.orderid = orderid
		;
	else
		delete from orderdetails
		where old.orderid = orderid
		;
		delete from orders
		where old.orderid = orderid
		;
	end if;
	return new;
end;
$$
language plpgsql;

create or replace trigger calcular_orden after update or insert or delete on orderdetails
for each row execute procedure recalcular_orden();

select productid, unitsinstock from products where productid = 3;

update orderdetails 
set quantity = 6
where orderid = 10782;

select orderid, quantity, amount
from orders
where orderid = 10782;

select *
from orderdetails o  
where orderid = 10782;

insert into orders values
(10782,null,null,null,null,null,null,null,null,null,null,null);

insert into orderdetails 
values (10782,3,12.50,1,0);

delete from orderdetails 
where orderid = 10782;

-- F) Realizar triggers a elección para probar las siguientes combinaciones y
-- situaciones respondiendo las siguientes consultas:

-- BEFORE - FOR STATEMENT ------------------------------------------------------

CREATE OR REPLACE FUNCTION before_for_statement()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE '[BEFORE STMT] NEW = %', NEW; -- (i)
    IF
	0 < (SELECT COUNT(*) FROM countries WHERE country = 'URU')
    AND TG_OP != 'DELETE' THEN
        RAISE EXCEPTION '[BEFORE STMT] Uruguay existe :O' -- (iii)
        USING HINT = 'Elimina a Uruguay ;) SALAME';
    END IF;
    RETURN NULL; -- (ii)
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER before_for_statement BEFORE INSERT OR UPDATE OR DELETE
ON countries FOR STATEMENT
EXECUTE FUNCTION before_for_statement();

-- i. ¿Qué sucede con la variable NEW?

-- NEW es NULL.
DELETE FROM countries
WHERE country = 'CAN'; -- NEW = <NULL>

-- ii. ¿Qué sucede ante un RETURN NULL?

-- La ejecución de la función finaliza, por lo que el trigger y la transacción
-- también finalizan y los cambios se ven aplicados.
INSERT INTO countries VALUES ('Canada', 'CAN');

-- iii. ¿Qué sucede ante un RAISE EXCEPTION?

-- La transacción se interrumpe y todos los cambios se deshacen (rollback).
INSERT INTO countries VALUES ('Uruguay', 'URU');
UPDATE countries SET descripcountry = 'uruguay' WHERE country = 'URU';
DELETE FROM countries WHERE country = 'URU';
INSERT INTO countries VALUES
    ('emiratos árabes unidos', 'ARE'),
    ('Bolivia', 'BOL');

-- AFTER - FOR EACH ROW --------------------------------------------------------

CREATE OR REPLACE FUNCTION after_for_each_row()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    RAISE NOTICE '[AFTER ROW] NEW = %', NEW; -- (iv)
    IF TG_OP != 'DELETE' THEN
        NEW.descripcountry := UPPER(NEW.descripcountry); -- (v)
        RAISE NOTICE '[AFTER ROW] NEW* = %', NEW;
    END IF;
    CASE NEW.country
        WHEN 'ARE', 'USA' THEN RETURN NEW; -- (v)
        WHEN 'ERR' THEN RAISE EXCEPTION '[AFTER ROW] Algo salió mal.'; -- (vii)
        ELSE RETURN NULL; -- (vi)
    END CASE;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER after_for_each_row AFTER INSERT OR UPDATE OR DELETE
ON countries FOR EACH ROW
EXECUTE FUNCTION after_for_each_row();

-- iv. ¿Qué sucede con la variable NEW?

-- INSERT: toma los valores de la fila a insertar.
INSERT INTO countries VALUES ('Nombre', 'Cod'); -- NEW = (Nombre,Cod)
select * from countries ;
-- UPDATE: toma los valores de la fila a actualizar y sus correspondientes
-- modificaciones.
UPDATE countries SET descripcountry = 'bolivia'
WHERE country = 'BOL'; -- NEW = (bolivia,BOL)

-- DELETE: es NULL.
DELETE FROM countries WHERE country = 'CHI'; -- NEW = <NULL>

-- v. ¿Qué sucede ante una modificación de valores de NEW y RETURN NEW?

-- A diferencia de BEFORE (FOR EACH ROW), los cambios hechos a NEW solo existen
-- durante la ejecución de la funcióm y no persisten luego de la transacción al
-- usar RETURN NEW.
UPDATE countries SET descripcountry = 'United States'
WHERE country = 'USA'; -- NEW* = ("UNITED STATES",USA)
SELECT descripcountry FROM countries WHERE country = 'USA'; -- United States

-- vi. ¿Qué sucede ante un RETURN NULL?

-- A diferencia de BEFORE (FOR EACH ROW), RETURN NULL no evita el INSERT, UPDATE
-- o DELETE y simplemente finaliza la ejecución de la función para la fila
-- actual.
DELETE FROM countries WHERE country = 'Cod';

-- vii. ¿Qué sucede ante un RAISE EXCEPTION?

-- La transacción se interrumpe y todos los cambios se deshacen (rollback).
INSERT INTO countries VALUES ('Error', 'ERR');


-- TP4
-- 1. Listar id, apellido y nombre de los cliente ordenados en un ranking decreciente, según la 
-- función del contacto (dentro de la empresa) contacttitle.

	
-- 2. Mostrar, por cada mes del año 1997, la cantidad de ordenes generadas, junto a la cantidad de 
-- ordenes acumuladas hasta ese mes (inclusive). El resultado esperado es el mismo que el 
-- obtenido en el ejercicio 2.g del trabajo práctico 1.

select 
	to_char(orderdate,'TMMonth') as mes,
	count(orderid) as cantidad,
	sum(count(orderid)) over(order by date_part('month',orderdate)) as acumuladas
from orders
where date_part('year',orderdate) = '1997'
group by date_part('month',orderdate),1
;


-- 3. Listar todos los empleados agregando las columnas: salario, salario promedio, ranking según 
-- salario del empleado, ranking según salario del empleado en la ciudad. Utilizando la definición 
-- explícita de ventanas
select
	concat(lastname,' ', firstname) as name,
	salary,
	avg(salary) over () as avg_salary,
	dense_rank() over(order by salary desc) ranking,
	city,
	dense_rank() over(partition by city order by salary desc) city_ranking
from employees
order by city,1 desc
;

select * from employees;

-- 4. Listar los mismos datos del punto anterior agregando una columna con la diferencia de salario 
-- con el promedio. Utilizando la definición explícita de ventanas
select
	concat(lastname,' ', firstname) as name,
	salary,
	avg(salary) over () as avg_salary,
	dense_rank() over(order by salary desc) as ranking,
	city,
	dense_rank() over(partition by city order by salary desc) as city_ranking,
	salary - avg(salary) over () as difference_salary
from employees
order by city,1 desc
;

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
create table movements(
	productid int4, foreign key (productid) references products,
	operationorder bigint,
	orderdate date,
	companyname varchar(60),
	quantity int4
);

alter table orders add column quantity int4;
alter table orders add column amount money;

insert into movements
	select
		productid,
		row_number() over (partition by productid order by orderdate) as operationorder,
		orderdate,
		companyname,
		od.quantity
	from
		customers 
		inner join orders using(customerid)
		inner join orderdetails od using(orderid)
	order by 1,2
	;
select * from movements;

-- 6. Listar apellido, nombre, ciudad y salario de los empleados acompañado de la resta del salario 
-- con el salario de la fila anterior de la misma ciudad. El resultado esperado es similar a:
select
	concat(lastname,' ', firstname) as name,
	city,
	salary,
	salary - lag(salary) over (partition by city order by salary)
from employees;

-- Muestra todos los productos agregando el promedio de precios y cantidad por categoria
select 
	productid,
	avg(unitprice) over () as avg,
	categoryid,
	count(productid) over(partition by categoryid) as quantity_x_categoryid
from products
; 

-- Define una ventana "particionando" por nombre de la categoria y por el nombre del producto
select
	categoryid,
	productname,
	unitprice::money,
	dense_rank() over (partition by categoryid order by unitprice desc) as ranking
from
	products
;

-- Define una ventana "particionando" por nombre de la categoria y "ordenamos" por el nombre del producto
select
	categoryid,
	productname,
	unitprice::money,
	dense_rank() over (partition by categoryid order by categoryid,productname) as ranking
from
	products
;

-- Muestra todos los productos repitiendo en cada fila el promedio general
select
	productid,
	productname,
	unitprice::money,
	avg(unitprice) over () as avg
from products
order by 1;


-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
select
	categoryid,
	productid,
	productname,
	unitprice::money,
	avg(unitprice) over ()::money as avg,
	avg(unitprice) over (partition by categoryid)::money as avg_category
from products
order by 1;

-- Pero ¿cómo podemos hacer si lo que queremos es mantener el listado completo de los 
-- datos de productos, con sus categorías y además la cantidad y promedio de precio por 
-- categoría?

select
	categoryname, 
	productid,
	productname,
	count(productid) over(partition by categoryid) as quantity_category,
	avg(unitprice) over(partition by categoryid)::money as avg
from products inner join categories using(categoryid)
; 

-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
-- Agregando la diferencia entre el precio de cada producto 
-- y el promedio segun categoria
 
select
	categoryid,
	productid,
	productname,
	unitprice::money,
	avg(unitprice) over ()::money as avg,
	(unitprice - avg(unitprice) over ())::money as difference_with_avg,
	avg(unitprice) over (partition by categoryid)::money as avg_category
from products
order by 1;

-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
-- Agregando la diferencia entre el precio de cada producto 
-- y el promedio segun categoria
-- Agregando ranking de precios por categoria
select
	categoryname,
	productid,
	productname,
	unitprice::money,
	avg(unitprice) over ()::money as avg,
	(unitprice - avg(unitprice) over ())::money as difference_with_avg,
	avg(unitprice) over (partition by categoryid)::money as avg_category,
	dense_rank() over (partition by categoryid order by unitprice desc) as ranking
from products inner join categories using(categoryid)
order by 1;

select
	categoryname,
	productid,
	productname,
	last_value(unitprice) over (partition by categoryid order by categoryid,productid) as ultimo_valor,
	unitprice::money,
	avg(unitprice) over ()::money as avg,
	(unitprice - avg(unitprice) over ())::money as difference_with_avg,
	avg(unitprice) over (partition by categoryid)::money as avg_category,
	dense_rank() over (partition by categoryid order by unitprice desc) as ranking
from products inner join categories using(categoryid)
order by 1;

select count(orderid) from orders;

-- obtener 	customerid,	orderid, orderdate y la fecha de la primera orden que realizo es cliente
-- PREGUNTAR PORQUE DEVUELVEN LO MISMO
select 
	customerid,
	orderid,
	orderdate,
	min(orderdate) over (partition by customerid order by orderdate) as primera_orden
from orders
;

select 
	customerid,
	orderid,
	orderdate,
	first_value(orderdate) over (partition by customerid order by orderdate) as primera_orden
from orders
;