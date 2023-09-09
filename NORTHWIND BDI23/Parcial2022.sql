--Segundo Examen Parcial
--Alumno: Rodriguez, Angelo Uriel
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
alter table customers add custcatid integer;

alter table customers add constraint custcatid 
foreign key(custcatid) references custcategory;

--Pregunta 2
--Cantidad de clientes por cada ciudad.
select c.city, count(c.city) as Cantidad
from customers c
group by c.city
order by c.city
;

--Pregunta 3
--Listado alfab�tico de productos que fueron comprados por el cliente 
--Ana Trujillo Emparedados y helados
select p.productid,	p.productname,c.companyname
from products p inner join orderdetails od using(productid) inner join orders o using(orderid)	inner join customers c using(customerid)
where c.companyname ilike '%ana trujillo emparedados y helados%'
order by p.productname;

select p.productid,	p.productname,o.customerid 
from products p inner join orderdetails od using(productid) inner join orders o using(orderid)	
where o.customerid = (
	select  c1.customerid
	from customers c1
	where c1.companyname ilike '%ana trujillo emparedados y helados%'
	)
order by p.productname;

--Pregunta 4
--Listado cronol�gico de ordenes junto al nombre del cliente.
select o.orderdate,	c.companyname, o.orderid
from orders o inner join customers c using(customerid)
order by o.orderdate;

-- Listado cronologico de ordenes por cada cliente
select companyname, orderdate, orderid
from orders inner join customers using(customerid)
order by customerid, orderdate
;
-- Listado cronologico de ordenes por cada idd de cliente
select customerid, orderdate, orderid
from orders 
order by customerid, orderdate
;

--Pregunta 5
--Listado alfab�tico de clientes que no realizaron compras en 1998, 
--junto con los importes acumulados de compras y la fecha de la �ltima compra.
select c.companyname, c.customerid,	sum((od.unitprice * od.quantity) - od.discount) as Importes_Acumulados, max(o.orderdate) Fecha_Ultima_Compra
from customers c inner join orders o using(customerid)	inner join orderdetails od using(orderid)
where c.customerid not in (select distinct o2.customerid 
							from orders o2
							where date_part('year',o2.orderdate) = '1998'
							)
group by c.companyname,	c.customerid
order by c.companyname;

-- Recordar que el group by agrupa por cada atributo y en la parte select utiliza todos los datos agrupados para hacer la funcion
-- de agregacion sin inporte que se utilize join

select *
from customers c inner join orders o using(customerid)	inner join orderdetails od using(orderid)
where c.customerid not in (select distinct o2.customerid 
							from orders o2
							where date_part('year',o2.orderdate) = '1998'
							)
order by c.companyname;
 
