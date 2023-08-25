-----------------------------------------------------------------------------------------------------------
-- TP1
-- 1)Crear la base de datos: Ventas

create database ventas;

-- 2)Crear las siguientes tablas dentro de la base de datos Ventas:
-- a)clientes{cli_id, cli_apellido, cli_nombre}
-- b)ventas{ven_id, cli_id FK(clientes), ven_importe}
-- c)productos{pro_id, pro_nombre, pro_precio_unitario}
-- d)detventas{ven_id FK(ventas), pro_id FK(productos), dv_cantidad}

create table clientes(
	cli_id text primary key,
	cli_apellido text not null,
	cli_nombre text not null
)
create table ventas(
	ven_id serial primary key,
	cli_id integer, foreign key (cli_id) references clientes, 
	ven_importe money not null
);
create table productos(
	pro_id serial primary key,
	pro_nombre text not null, 
	pro_precio_unitario money not null
);
create table detventas(
	ven_id integer, foreign key(ven_id) references ventas,
	pro_id integer, foreign key(pro_id) references productos, 
	dv_cantidad smallint not null
);

-- 3)Agregar a la tabla clientes la columna cli_domicilio.

alter table clientes add column cli_domicilio text not null;

-- 4)Agregar a la tabla detventas la columna dv_precio_unitario.

alter table detventas add column dv_precio_unitario ;


-- 5)Eliminar de la tabla ventas la columna ven_importe.

alter table ventas drop column ven_importe;


-- 6)Crear un índice para la tabla productos según la columna pro_nombre.

create index ind_pro_nom
on productos(pro_nombre)
;

-- 7)Crear un índice para la tabla clientes según las columnas cli_apellido y cli_nombre.

create index ind_nom_ape
on clientes(cli_apellido,cli_nombre)
;

-- 8)Crear una tabla marcas{mar_id, mar_nombre}

create table marcas(
	mar_id serial primary key,
	mar_nombre text not null
);
-- 9)Investigar la resolución de este punto. Existiendo la tabla productos, establecer la clave foránea 
-- relacionándola con la tabla marcas a través de la columna mar_id. 

alter table productos add column mar_id integer;
alter table productos
add constraint mar_id
foreign key(mar_id)
references marcas
;

-- 10) Modificar el tipo de datos de la columna mar_nombre de la tabla marcas (por ejemplo dándole 
-- mayor tamaño máximo).

alter table marcas alter column mar_nombre type varchar(5);

-----------------------------------------------------------------------------------------------------------
--	TP4

/* 
 * Integrantes: Ezequiel Lizandro Dzioba, Maximiliano Ezequiel Rivas
 * Grupo: 3
*/

-- 1)Apellidos Nombres de los empleados, ordenados en forma alfabética

select lastname, firstname
from employees
order by 1,2
;

-- 2)Listado alfabético de los empleados que tengan 30 años de edad o más, de la forma “Sr. Perez, Juan”.

select concat(titleofcourtesy,' ',lastname,' ',firstname)
from employees
where date_part('year',age(birthdate)) >= 30
order by 1
;

-- 3)Fecha y dirección de los primeros 20 envíos realizados en el año 1996

select shippeddate, shipaddress
from orders
where date_part('year',shippeddate) = '1996'
order by (shippeddate, orderid) asc 
limit 20
;

-- 4)País, Nombre, Dirección, Teléfono y Fax de los clientes ordenados por país y sólo para aquellos 
-- clientes que tienen fax.

select country, companyname, address, fax
from customers
where fax is not null
order by 1,2,3,4
;


-- 5)Nombre de los clientes que residan en ciudades cuyo código postal comience con letra.

select companyname
from customers 
where lower(postalcode) between 'a' and 'z'
order by 1
;


-- 6)Nombre y teléfono de los clientes donde se realza contacto directo con el propietario, ordenado 
-- en forma alfabético.

select companyname, phone
from customers 
where trim(contacttitle) ilike '%Owner%'
order by 1
;

-- 7)Todos los datos de la última orden realizada.

select *
from orders 
where shippeddate is not null
order by (orderdate, orderid) desc
limit 1
;

-- 8)Apellidos, Nombre y Edad de los empleados que cumplen años en el mes en curso (sin usar 
-- constantes de fecha).

select lastname, firstname, date_part('year',age(birthdate)) as anios
from employees 
where date_part('month',birthdate) = date_part('month',current_date)
order by 1,2,3
;


-- 9)Cantidad de empleados por cada país.

select country, count(employeeid) as cant
from employees
group by 1
order by 1
;

-- 10) Cantidad de clientes por cada país

select country, count(customerid) as cant
from customers 
group by 1
order by 1
;


-- 11) Ciudades que tengan al menos 2 empleados (teniendo en cuenta los países).

select city
from employees
group by 1
having count(employeeid) >= '2'
order by 1
;

-- 12) Cantidad de órdenes realizadas durante el año 1998.

select count(orderid)
from orders
where date_part('year',orderdate) = '1998'
;

-- 13) Listado alfabético con el nombre del destinatario del envío y la cantidad de órdenes realizadas 
-- en el año 1997 por cada destinatario (ShipName).

select shipname, count(orderid)
from orders
where date_part('year',orderdate) = '1997'
group by 1
order by 1
;

-- 14) Nombre, Ciudad y País de todas las calles a las que se le realizaron envíos y que sean avenidas.

select distinct shipaddress, shipcity, shipcountry
from orders
where trim(shipaddress) ilike '%Av.%'
order by 1,2,3
;

-- 15) Ranking de envíos por cada embarcación, durante el año 1997.

select shipname, count(orderid) as cant
from orders 
where date_part('year',orderdate) = '1997'
group by 1
order by 2 desc 
;

-- 16) Cantidad de órdenes realizada en cada mes del año 1998, de la forma siguiente:
-- Enero XX
-- Febrero XX
-- Marzo XX…

select to_char(orderdate,'TMMonth'), count(orderid) as cant
from orders 
where date_part('year',orderdate) = '1998'
group by date_part('month',orderdate), 1
order by date_part('month',orderdate)
;

-----------------------------------------------------------------------------------------------------------
-- TP5


--1)Listado alfabatico con los nombres y domicilios de los clientes que realizaron compras durante
--	el mes de octubre del anio 1997.

select c.companyname, c.address
from customers c
where c.customerid in (
	select distinct o.customerid 
	from orders o
	where to_char(orderdate,'YYYYMM') = '199710' 
	)
order by 1
;

--2) Nombre y domicilio del cliente a quien se le realizo el ultimo envio.

select c.companyname, c.address
from customers c
where c.customerid = (
	select o.customerid
	from orders o 
	where o.shippeddate = (
		select max(o2.shippeddate)
		from orders o2 
		where shippeddate is not null
		)
	order by o.orderid desc
	limit 1
	)
;
--3) Listado con nombre de los clientes que alguna vez compraron el producto Queso Cabrales

select c.companyname
from customers c 
where c.customerid in (
	select distinct o.customerid
	from orders o 
	where o.orderid in (
		select od.orderid
		from orderdetails od
		where od.productid = (
			select p.productid
			from products p 
			where trim(p.productname) ilike '%Queso Cabrales%'
			)
		)
	)
order by 1
;
--4) Numero de orden, Fecha de Orden, Fecha de envio, Total de la orden (considerando descuentos)
--   de todas las ordenes del cliente Rancho grande.

select o.orderid, o.orderdate, o.shippeddate, (select sum(od.unitprice * od.quantity - od.discount)
												from orderdetails od
												where o.orderid = od.orderid 
												)
from orders o 
where o.customerid = (
	select c.customerid
	from customers c 
	where trim(c.companyname) ilike '%Rancho Grand%'
	)
order by 1
;
-- 5. Listado de productos que no se hayan vendido en octubre del anio 1997.

select p.productid, p.productname
from products p 
where p.productid not in(
	select distinct od.productid
	from orderdetails od
	where od.orderid in(
		select o.orderid
		from orders o 
		where to_char(o.orderdate,'YYYYMM') = '199710' 
		)
	)
order by 1,2
;

--6) Listado de productos que no se hayan vendido en el segundo semestre de 1997

select p.productid, p.productname
from products p 
where p.productid not in(
	select distinct od.productid
	from orderdetails od
	where od.orderid in(
		select o.orderid
		from orders o 
		where o.orderdate between '19970701' and '19971231' 
		)
	)
order by 1,2
;

--7) Listado alfabetico de proveedores cuyos productos no se hayan enviado en ninguna orden en el
--   mes de mayo del anio 1998.

select s.companyname 
from suppliers s 
where s.supplierid not in(
	select p.supplierid
	from products p 
	where p.productid in(
		select distinct od.productid
		from orderdetails od
		where od.orderid in(
			select o.orderid
			from orders o 
			where to_char(o.orderdate,'YYYYMM') = '199710' 
			)
		)
		group by p.supplierid
	)

--8. Listado alfabatico de los empleados que tengan al menos 2 subordinados.

select j.lastname, j.firstname
from employees j
where j.employeeid in (
	select e.reportsto
	from employees e
	group by 1
	having count(e.employeeid) >= '2'
	)
order by 1,2
;

-----------------------------------------------------------------------------------------------------------
-- TP6
-- Grupo 3, Integrantes: Ezequiel Lizandro Dzioba Maximiliano Ezequiel Rivas

--1) Rehacer las consultas del Trabajo Practico 5, cambiando todas las subconsultas que sean
-- posibles, por su correspondiente reunion.

--1 TP5
--Listado alfabetico con los nombres y domicilios de los clientes que realizaron compras durante
--el mes de octubre del anio 1997.

select companyname, address
from customers inner join orders using(customerid)
where to_char(orderdate,'YYYYMM') = '199710'
group by customerid
order by 1,2
;

--2 TP5
--Nombre y domicilio del cliente a quien se le realiza el ultimo envio.

select companyname, address
from customers inner join orders using(customerid)
where shippeddate is not null
order by (shippeddate,orderid) desc 
limit 1
;

--3 TP5
--Listado con nombre de los clientes que alguna vez compraron el producto Queso Cabrales.

select companyname
from customers inner join orders using(customerid) inner join orderdetails using(orderid)
where productid = (
	select p.productid
	from products p 
	where trim(p.productname) ilike '%Queso Cabrales%'
	)
group by customerid
order by 1
;
--4 TP5
--Numero de orden, Fecha de Orden, Fecha de envio, Total de la orden (considerando descuentos)
--de todas las ordenes del cliente Rancho grande.

select orderid, orderdate, shippeddate, sum(unitprice * quantity - discount)
from orders inner join orderdetails using(orderid)
where customerid = (
	select c.customerid
	from customers c 
	where trim(c.companyname) ilike '%Rancho Grande%'
	)
group by orderid
order by 1,2,3
;

--5 TP5
--Listado de productos que no se hayan vendido en octubre del anio 1997.

select productid, productname
from products 
where productid not in(
	select distinct od.productid
	from orderdetails od inner join orders o using(orderid) 
	where to_char(o.orderdate,'YYYYMM') = '199710' 
	)
order by 1,2
;

--6 TP5
--Listado de productos que no se hayan vendido en el segundo semestre de 1997
					
select productid, productname
from products 
where productid not in(
	select distinct od.productid
	from orderdetails od inner join orders o using(orderid) 
	where o.orderdate between '19970701' and '19971201'
	)
order by 1,2
;

--7 TP5
--Listado alfabetico de proveedores cuyos productos no se hayan enviado en ninguna orden en el
--mes de mayo del anio 1998.
select s.companyname
from suppliers s 
where s.supplierid not in(
	select distinct p.supplierid
	from products p inner join orderdetails od using (productid) inner join orders o using(orderid) 
	where to_char(o.orderdate,'YYYYMM') = '199810' 
	)
order by 1
;

--8 TP5
--Listado alfabetico de los empleados que tengan al menos 2 subordinados.

select j.lastname, j.firstname
from employees j inner join employees e on j.employeeid = e.reportsto 
group by j.employeeid 
having count(e.employeeid) >= 2
;

--2) Mostrar el detalle de cada orden, id de la misma, fecha, identificacion 
-- de cada articulo (Id y Nombre), cantidad de articulos, importe unitario y subtotal de cada item.

select o.orderid, o.orderdate, p.productid, p.productname, sum(od.unitprice * od.quantity - od.discount) as subt
from products p inner join orderdetails od using(productid) inner join orders o using(orderid)
group by 1,3
order by 1,3
;
--3) Mostrar todos los atributos de cada orden junto a id y nombre del cliente y el empleado 
-- que la confeccionen.

select o.orderid, c.companyname, concat(e.lastname,' ',e.firstname) as employee, o.*
from customers c inner join orders o using(customerid) inner join employees e using(employeeid) 
group by o.orderid, c.customerid, e.employeeid 
order by 1,2,3
;

--4) Mostrar la cantidad total de productos vendidos por mes.

select date_part('year',o.orderdate) as anio, to_char(o.orderdate,'TMMonth') as mes, sum(od.quantity) as cant
from orderdetails od inner join orders o using(orderid)
group by 1,date_part('month',o.orderdate),2
order by 1,date_part('month',o.orderdate)
;

--5) Mostrar nombre, id y domicilios de clientes, incluyendo la cantidad de ordenes acumuladas por cada mes.

select c.companyname, c.customerid, c.address, date_part('year',o.orderdate) as anio, to_char(o.orderdate,'TMMonth') as mes, count(o.orderid) as cant
from customers c inner join orders o using(customerid)
group by 2,4,date_part('month',o.orderdate),5
order by 2,1,4,date_part('month',o.orderdate)
;

--6) Mostrar id, nombre y domicilio de los empleados junto a al monto total de ordenes de
--todos sus subordinados.

select j.employeeid, j.lastname, j.firstname, sum(od.unitprice * od.quantity - od.discount) as total
from orderdetails od inner join orders o using(orderid) inner join employees e using(employeeid) inner join employees j on j.employeeid = e.reportsto 
group by 1
order by 2,3
;

--7) Mostrar todos los productos (id y nombre) junto con las cantidades vendidas de cada uno
-- en el ultimo mes del que se tenga informacion. 
-- (Preferentemente no utilizar constantes de fechas).

select p.productid, p.productname, coalesce(sum(od.quantity),0)
from products p left join (
	select *
	from orderdetails od1 inner join orders o using(orderid)
	where to_char(o.orderdate,'YYYYMM') = (select to_char(max(o2.orderdate),'YYYYMM') from orders o2)
	) as od using(productid)
group by 1
order by 1
;


--------------------------------------------------------------------------------------------------------------
--Segundo Examen Parcial
--Alumno: Rivas Maximiliano Ezequiel
--Base de Datos I

--Pregunta 1
--Crear una tabla llamada custcategory con dos columnas
--	1. custcatid autounumerado y clave primaria.
--	2. custcatdiscount entero corto.
--Modificar la estructura de customers, agregando la columna custcatid
--como clave for�nea a tabla custcategory.

create table custcategory(
	custcatid serial primary key,
	custcatdiscount smallint not null
);

alter table customers add column custcatid integer;
alter table customers 
add constraint custcatid
foreign key (custcatid)
references custcategory
;
--Pregunta 2
--Cantidad de clientes por cada ciudad.

select city, count(customerid) as cant
from customers 
group by 1
order by 1
;

--Pregunta 3
--Listado alfab�tico de productos que fueron comprados por el cliente 
--Ana Trujillo Emparedados y helados

select productid, productname
from products inner join orderdetails using(productid) inner join orders using(orderid) inner join customers using(customerid)
where trim(companyname) ilike '%Ana Trujillo Emparedados y helados%'
group by productid
order by 1
;
	
--Pregunta 4
--Listado cronol�gico de ordenes junto al nombre del cliente.

select orderid, orderdate, companyname
from orders inner join customers using(customerid)
order by (2,1) desc
;


--Pregunta 5
--Listado alfab�tico de clientes que no realizaron compras en 1998, 
--junto con los importes acumulados de compras y la fecha de la �ltima compra.

select c.companyname, c.customerid, sum(od.unitprice * od.quantity - od.discount) as total, max(o.orderdate) as ult_fec
from orderdetails od inner join orders o using(orderid) inner join customers c using(customerid)
where c.customerid not in (
	select distinct o2.customerid 
	from orders o2
	where date_part('year',orderdate) = '1998' 
	)
group by 2
order by 1,2
;
