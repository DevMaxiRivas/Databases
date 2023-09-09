-- Listado cronológico de las órdenes enviadas a ciudades de Francia

select orderid, shippeddate, shipcity
from orders
where lower(shipcountry) ilike '%France%' and shippeddate is not null
order by (2,1,3) asc 
;

select orderid, shippeddate, shipcity
from orders
where lower(shipcountry) ilike '%France%' and shippeddate is not null
order by (shippeddate,orderid) asc 
;

-- Ranking de la cantidad de productos en cada orden

select o.orderid, p.productid, p.productname, od.quantity
from products p inner join orderdetails od using(productid) inner join orders o using(orderid)
order by o.orderid, od.quantity desc
;

-- Listado alfabético de clientes que hayan comprado 
-- productos del proveedor Exotic Liquids

select c.companyname, c.customerid 
from customers c inner join orders o using(customerid) inner join orderdetails od using(orderid) inner join products p using(productid)
where p.supplierid = (
	select s.supplierid
	from suppliers s 
	where trim(s.companyname) ilike '%Exotic Liquids%'
	)
group by c.customerid 
order by 1
;

select distinct c.companyname, c.customerid
from customers c inner join orders o using(customerid) inner join orderdetails od using(orderid) inner join products p using(productid)
where p.supplierid = (
	select s.supplierid
	from suppliers s 
	where trim(s.companyname) ilike '%Exotic Liquids%'
	)
order by 1
;


-- Listado alfabético de Clientes que hayan comprado más de 
-- 3 productos en una misma orden en el primer trimestre de 1997

select c.companyname, c.customerid
from orderdetails od inner join orders o using(orderid) inner join customers c using(customerid)
where o.shippeddate between '19970101' and '19970331'
group by c.customerid, o.orderid
having count(od.productid) > '3'
order by c.companyname
;

select *
from orderdetails od inner join orders o using(orderid) inner join customers c using(customerid)
where o.shippeddate between '19970101' and '19970630'
order by c.companyname
;

-- Productos que se hayan vendido al menos 200 unidades ordenados alfabéticamente
select p.productid, p.productname,sum(od.quantity) as cantidad
from products p inner join orderdetails od using(productid) inner join orders o using(orderid)
where shippeddate is not null
group by p.productid 
having sum(od.quantity) >= '200'
order by p.productname
;

-- Listado alfabético de los vendedores, junto con los montos totales 
-- vendidos en 1998 y la fecha en que se hizo la última venta.

select e.lastname, e.firstname, e.employeeid, sum(od.unitprice * od.quantity - od.discount) as total, max(o.shippeddate) as ult_vent
from employees e inner join orders o using(employeeid) inner join orderdetails od using(orderid)
where shippeddate is not null and date_part('year',shippeddate) = '1998'
group by e.employeeid 
order by e.lastname, e.firstname
;


