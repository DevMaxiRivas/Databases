-- Trabajo Práctico 1
-- Base de Datos II

-- 1) Insertar en la tabla region: Noroeste Argentino, con ID 5
INSERT INTO region VALUES
(5,'Noroeste Argentino')
;

SELECT * FROM region;

-- 2) Insertar en la tabla territories al menos 5 territorios de la nueva región
-- utilizando la sintaxis multirow de INSERT
select * from territories;
insert into territories values
(1,'Salta',5),
(2,'Cordoba',5),
(3,'Chaco',5),
(4,'Jujuy',5),
(5,'Tucuman',5)
;

-- 3) Crear una tabla tmpterritories con los siguientes atributos
    -- territoryid
    -- territorydescription
    -- regionid
    -- regiondescription
create table tmpterritories(
	territoryid varchar(20),foreign key (territoryid) references territories,
    territorydescription varchar(50),
    regionid int4, foreign key (regionid) references region,
    regiondescription varchar(50)
);

-- 4) Mediante la sintaxis INSERT ... SELECT llenar la tabla del punto 3
-- combinando información de las tablas region y territories
insert into tmpterritories
	select 
    	territoryid,
    	territorydescription,
    	regionid,
    	regiondescription
    from territories inner join region using(regionid)
;

-- 5) Agregar dos columnas a la tabla customers donde se almacene:
    -- ordersquantity: con la cantidad de órdenes del cliente en cuestión
    -- ordersamount: el importe total de las órdenes realizadas
alter table customers add column quantity bigint default 0;
alter table customers add column amount money default 0;

-- 5.a) Mediante sentencia UPDATE ... FROM actualizar las columnas agregadas
update customers c set 
	quantity = a.cantidad, 
	amount = b.monto
from (
	select 
		count(O.orderid)::bigint as cantidad,
		o.customerid
	from orders o
	group by o.customerid
	) as a, (
	select 
		o.customerid,
		sum(od.unitprice * od.quantity - od.discount)::money as monto
	from orders o inner join orderdetails od using(orderid)
	group by o.customerid
	) as b
where 
	c.customerid = a.customerid 
	and c.customerid = b.customerid 
;

select customerid, quantity, amount from customers;

-- 5.b) Mediante sentencia UPDATE y subconsulta actualizar las col

update customers c
set
	quantity = (
		select count(orderid)
		from orders o
		where c.customerid = o.customerid
	),
	amount = (
		select coalesce(sum(od.quantity * od.unitprice - od.discount),0)::money as monto
		from orders o inner join orderdetails od using(orderid)
		where c.customerid = o.customerid
	)
;
update customers set quantity = 0, amount = 0;

-- 6) Desarrollar las sentencias necesarias que permitan eliminar todo el
-- historial de òrdenes de un cliente cuyo dato conocido es companyname,
-- utilizando DELETE ... USING

delete from orderdetails od
using orders o,customerid c
where 
	o.customerid = c.customerid
	and o.orderid = od.orderid
	and trim(c.companyname) ilike '%companyname%'
;

delete from orders o
using customerid c
where 
	o.customerid = c.customerid
	and trim(c.companyname) ilike '%companyname%'
;

--
-- Trabajo Práctico 2
-- Base de Datos II

-- A) Crear una función que permita eliminar espacios en blanco innecesarios
-- (trim) de una columna de una tabla. Los nombres de columna y tabla deben ser
-- pasados como parámetros y la función deberá devolver como resultado la
-- cantidad de filas afectadas.
create or replace function delete_trim(pt_table text, pl_column text)
returns bigint as
$$
declare pb_count bigint;
begin
	execute
		format(
		'
		update %1$I
		set %2$I = trim(%2$I)
		where %2$I != trim(%2$I)
		',pt_table,pt_column)
	;
	get diagnostics pb_count := ROW_COUNT;
	return pb_count;
end;
$$
language plpgsql;


-- B) Programar una función que reciba como parámetro un orderid y devuelva una
-- cadena de caracteres (resumen) con el id, nombre, precio unitario y cantidad
-- de todos los productos incluidos en la orden en cuestión.
create or replace function retorna_detalle(pi_orderid int4)
returns text as 
$$
declare lr_fila RECORD;
declare lt_cad text := '';
begin
	for lr_fila in (
		select 
			p.productid,
			p.productname,
			od.unitprice,
			od.quantity
		from orderdetails od inner join products p using(productid)
		where od.orderid = pi_orderid
		order by p.productid
	) loop 
		lt_cad := format(
			E'%s\n %s - %s - %s - %s',
			lt_cad, lr_fila.productid, trim(lr_fila.productname),
			lr_fila.unitprice::money, lr_fila.quantity
		);
	end loop;
	return lt_cad;	
end;
$$
language plpgsql;

SELECT * from retorna_detalle(11077);
-- C) Prueba con orderid = 11077


-- D) Crear una función que muestre por cada detalle de orden: el nombre del
-- cliente, la fecha, la identificación de cada artículo (id y nombre),
-- cantidad, importe unitario y subtotal de cada ítem para un intervalo de
-- tiempo dado por parámetros.
create or replace function detalle_intervalo(pd_desde date, pd_hasta date)
returns table(
	nombre text,
	fecha date,
	idproducto integer,
	nombproduc text,
	cantidad integer,
	preciounit money,
	subtotal money	
)as
$$
begin
	return query
		select
			c.companyname::text,
			o.orderdate,
			p.productid::integer,
			p.productname::text,
			od.quantity::integer,
			od.unitprice::money,
			(od.quantity * od.unitprice - od.discount)::money
		from
			customers c
			inner join orders o using(customerid)
			inner join orderdetails od using(orderid)
			inner join products p using(productid)
		where o.orderdate between pd_desde and pd_hasta
		order by o.orderid
	;
end;
$$
language plpgsql;

SELECT * FROM detalle_intervalo('1996-07-04', '1997-01-01');

-- E) Función para el devolver el total de una orden dada por parámetro.

create or replace function total_orden(pi_orderid int4)
returns money as 
$$
begin
	return (
		select sum(unitprice * quantity - discount)::money
		from orderdetails
		where orderid = pi_orderid
	);
end;
$$
language plpgsql;

SELECT total_orden(10248);

-- F) Crear una función donde se muestren todos los atributos de cada Orden
-- junto a Id y Nombre del Cliente y el Empleado que la confeccionó. Mostrar el
-- total utilizando la función del punto anterior.
create or replace function detalla_ordenes()
returns table(
	orden int4,
	name text,
	empleado text,
	total money
)as 
$$
begin
	return query
		select
			o.orderid::int4,
			c.companyname::text,
			concat(e.lastname,' ',e.firstname),
			total_orden(o.orderid)
		from 
			customers c
			inner join orders o using(customerid)
			inner join employees e using(employeeid)
		order by 1
		;
end;
$$
language plpgsql;

SELECT * FROM detalla_ordenes();

-- G) Crear una función que muestre, por cada mes del año ingresado por
-- parámetro, la cantidad de órdenes generada, junto a la cantidad de órdenes
-- acumuladas hasta ese mes (inclusive).

create or replace function detalla_anio(pi_anio int4)
returns table(
	mes text,
	cantidad bigint,
	acumuladas bigint
)as
$$
declare lr_fila RECORD;
begin
	acumuladas := 0;
	for mes, cantidad in (
		select
			to_char(o.orderdate,'TMMonth'),
			count(o.orderid)
		from orders o
		where date_part('year',o.orderdate) = pi_anio
		group by date_part('month',o.orderdate),1 
		order by date_part('month',o.orderdate)
	) loop 
		acumuladas := acumuladas + cantidad;
		return next;
	end loop;
end;
$$
language plpgsql;

SELECT * FROM detalla_anio('1997');

-- H) Crear una función que permita generar las órdenes de compra necesarias
-- para todos los productos que se encuentran por debajo del nivel de stock,
-- para esto deberá crear una tabla de órdenes de compra y su correspondiente
-- tabla de detalles.
CREATE TABLE supplier_orders (
    orderid SERIAL PRIMARY KEY,
    orderdate DATE NOT NULL,
    supplierid INTEGER NOT NULL REFERENCES suppliers
);

CREATE TABLE supplier_orderdetails (
    orderid INTEGER NOT NULL REFERENCES supplier_orders,
    productid INTEGER NOT NULL REFERENCES products,
    quantity INTEGER,
    PRIMARY KEY (orderid, productid)
);

create or replace function genera_ordenes()
returns void as
$$
declare li_orderid int4;
declare li_supplierid int4 := '000';
declare lr_fila RECORD;
begin 
	for lr_fila in (
		select 
			p.productid,
			p.supplierid,
			p.unitsonorder - p.unitsinstock as quantity
		from products p
		where 
			not p.discontinued
			and p.unitsinstock < p.reorderlevel
			and p.unitsonorder - p.unitsinstock > 0
		order by 1
	) loop 
		if li_supplierid != lr_fila.supplierid then 
			li_supplierid := lr_fila.supplierid;
			insert into supplier_orders values
			(default,current_date,li_supplierid)
			returning orderid into li_orderid;
		end if;
		insert into supplier_orderdetails values
		(li_orderid,lr_fila.productid,lr_fila.quantity)
		;
	end loop;
end;
$$
language plpgsql;

SELECT * from genera_ordenes();

select * from supplier_orders inner join supplier_orderdetails using(orderid)
inner join products using(productid);

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
create or replace function periodo_ventas(pd_desde date, pd_hasta date)
returns table(
	shipcountry text,
	productos bigint,
	clientes bigint
)as
$$
begin
	return query
		select
			o.shipcountry::text,
			count(distinct od.productid),
			count(distinct o.customerid)
		from
			orders o
			inner join orderdetails od using(orderid)
		where o.orderdate between pd_desde and pd_hasta
		group by 1
		order by 1
	;
end;
$$
language plpgsql;
SELECT * FROM periodo_ventas('1997-01-01', '1997-12-31');

-- J) Inventar una única función que combine RETURN QUERY, recorrido de
-- resultados de SELECT y RETURN NEXT. Indicar, además del código, qué se espera
-- que devuelva la función inventada.
create or replace function muestra_companias()
returns table(
	companyname text,
	country text
)as
$$
declare lr_fila RECORD;
begin
	return query
		select 
			c.companyname::text,
			c.country::text
		from customers c
		order by 1
	;
	for lr_fila in (
		select
			s.companyname,
			s.phone
		from shippers s
	) loop
		companyname := lr_fila.companyname;
		if trim(lr_fila.phone) ilike '%(50%' then
			country := 'USA';
		end if;
		return next;
	end loop;
end;
$$
language plpgsql;

SELECT * FROM muestra_companias();

-- Trabajo Práctico 2

-- a. Crear un disparador para impedir que ingresen dos proveedores en el mismo 
-- domicilio. (tener en cuenta la ciudad y país).

create or replace function verifica_dom()
returns trigger as 
$$
declare li_supp int4;
begin
	li_supp := (
		select s.supplierid
		from suppliers s
		where 
			trim(s.address) ilike trim(new.address)
			and trim(s.city) ilike trim(new.city)
			and trim(s.country) ilike trim(new.country)
		limit 1
	);
	if li_supp is not null then
		raise notice 'El domicilio ya se encuentra registrado';
		return null
	end if;
	return new;
end;
$$
language plpgsql;

create or replace trigger verificacion_domicilio before update or insert on suppliers
for each row execute procedure verifica_dom();

-- b. Realizar un disparador que impida incluir en un detalle de orden, cantidades no 
-- disponibles. 
create or replace function verifica_stock()
returns trigger as 
$$
declare li_quantity int4;
begin
	li_quantity  := (
		select p.quantity
		from products p
		where p.productid = new.productid
	);
	if li_quantity < new.quantity then 
		raise notice 'Sock insuficiente';
		return null;
	end if;
	return new;
end;

$$
language plpgsql;

create or replace trigger verificacion_stock before insert or update on orderdetails
for each row execute procedure verifica_stock();

-- c. Realizar un disparador que actualice el nivel de stock cuando se crean, modifican o 
-- eliminan órdenes (y sus detalles). 
create or replace function update_stock()
returns trigger as 
$$
begin
	case
		when TG_OP = 'UPDATE' then
			if new.productid = old.productid then
				update products p
				set unitsinstock = unitsinstock + old.quantity - new.quantity
				where new.productid = p.productid
				;
			else 
				update products p
				set unitsinstock = unitsinstock + old.quantity
				where new.productid = p.productid
				;
				update products p
				set unitsinstock = unitsinstock - new.quantity
				where new.productid = p.productid
				;
			end if;
		when TG_OP = 'INSERT' then
			update products p
			set unitsinstock = unitsinstock - new.quantity
			where new.productid = p.productid
			;
		when TG_OP = 'DELETE' then
			update products p
			set unitsinstock = unitsinstock + old.quantity 
			where new.productid = p.productid
			;
	end case;
end;
$$
language plpgsql;

create or replace trigger actualiza_stock after update or insert or delete on orderdetails
for each row execute procedure update_stock();


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
	auditid serial,
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
	before_fax,
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

create or replace function audit()
returns trigger as
$$
begin 
	case
		when TG_OP = 'UPDATE'
			insert into audits values
			(default,current_user,now(),'MODIFICACION',
			 old.*,new.*);
		when TG_OP = 'INSERT'
			insert into audits (
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
			(default,current_user,now(),'ALTA',
			 new.*);
		when TG_OP = 'DELETE'
			insert into audits (
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
			)values
			(default,current_user,now(),'BAJA',
			 old.*);
	end case;
end;
$$
language plpgsql;

create or replace trigger auditoria after update or insert or delete on customers
for each row execute function audit();

-- e. Agregar atributos en el encabezado de la Orden que registren la cantidad de artículos 
-- del detalle y el importe total de cada orden. Realizar los triggers necesarios para 
-- mantener la redundancia controlada de los nuevos atributos.
alter table orders add column quantity bigint default 0;
alter table orders add column amount money default 0;

create or replace function upd_orders(pi_orderid int4)
returns table (
	cantidad bigint,
	monto money
)as
$$
begin 
	return query
		select
			count(od.orderid),
			(coalesce(sum(od.quantity * od.unitprice - od.discount),0))::money
		from orderdetails od
		where od.orderid = pi_orderid
	;
end;
$$
language plpgsql;

create or replace function upd_od()
returns trigger as 
$$
declare cantidad bigint;
declare	monto money;
begin
	case
		when TG_OP = 'UPDATE' or TG_OP = 'INSERT'
			select * into cantidad,monto from upd_orders(new.orderid);
			update orders 
			set 
				quantity = cantidad,
				amount = monto
			where orderid = new.orderid
			;
		when TG_OP = 'DELETE' 
			select * into cantidad,monto from upd_orders(old.orderid);
			update orders 
			set 
				quantity = cantidad,
				amount = monto
			where orderid = old.orderid
			;
	end case;
	if cantidad = 0 then
		delete from orderdetails od
		where 
			od.orderid = new.orderid 
			or od.orderid = old.orderid
		;
		delete from orders o
		where 
			o.orderid = new.orderid 
			or o.orderid = old.orderid
		;
	end if;
end;
$$
language plpgsql;

create or replace trigger modifica_od after insert or delete or update on orderdetails
for each row execute procedure upd_od();

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

select 
	customerid,
	contactname,
	contacttitle,
	dense_rank() over (partition by contacttitle order by contacttitle,contactname desc) as rank
from customers
order by contacttitle 
;
	
-- 2. Mostrar, por cada mes del año 1997, la cantidad de ordenes generadas, junto a la cantidad de 
-- ordenes acumuladas hasta ese mes (inclusive). El resultado esperado es el mismo que el 
-- obtenido en el ejercicio 2.g del trabajo práctico 1.
select
	to_char(orderdate,'TMMonth') as mes,
	count(orderid) as cantidad,
	sum(count(orderid)) over (order by date_part('month',orderdate)) as acumulada
from orders
where date_part('year',orderdate) = '1997'
group by date_part('month',orderdate),1
order by date_part('month',orderdate)
;

-- 3. Listar todos los empleados agregando las columnas: salario, salario promedio, ranking según 
-- salario del empleado, ranking según salario del empleado en la ciudad. Utilizando la definición 
-- explícita de ventanas
select 
	employeeid,
	salary,
	avg(salary) over ()::money as avg,
	dense_rank() over (order by salary desc) as ranking,
	city,
	avg(salary) over (x_city)::money as avg_city,
	dense_rank() over (x_city order by salary desc) as ranking_city
from employees 
window x_city as(
	partition by city
)
order by 7
;
	

-- 4. Listar los mismos datos del punto anterior agregando una columna con la diferencia de salario 
-- con el promedio. Utilizando la definición explícita de ventanas
select 
	employeeid,
	salary,
	avg(salary) over ()::money as avg,
	(salary - avg(salary) over ())::money as difference,
	dense_rank() over (order by salary desc) as ranking,
	city,
	avg(salary) over (x_city)::money as avg_city,
	dense_rank() over (x_city order by salary desc) as ranking_city
from employees 
window x_city as(
	partition by city
)
order by 7
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
	productid int4, foreign key(productid) references products,
	operationorder int4,
	orderdate date,
	companyname varchar(40),
	quantity int4
);

insert into movements 
	select
		od.productid,
		row_number() over (partition by od.productid order by o.orderdate,od.orderid) as operationorder,
		o.orderdate,
		c.companyname,
		od.quantity
	from
		customers c
		inner join orders o using(customerid)
		inner join orderdetails od using(orderid)
	order by 1
;
		
-- 6. Listar apellido, nombre, ciudad y salario de los empleados acompañado de la resta del salario 
-- con el salario de la fila anterior de la misma ciudad. El resultado esperado es similar a:
select 
	concat(lastname,' ',firstname) name,
	city,
	salary,
	salary - lag(salary) over (partition by city order by salary) as difference
from employees;


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
