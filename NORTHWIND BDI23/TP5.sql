
--1)Listado alfabatico con los nombres y domicilios de los clientes que realizaron compras durante
--	el mes de octubre del anio 1997.
select companyname, address
from customers c
where exists (
	select companyname from orders o
	where 	date_part('month', orderdate)= 10
			and date_part('year', orderdate)= 1997
			and o.customerid = c.customerid 
	)
order by companyname;

--2) Nombre y domicilio del cliente a quien se le realizo el ultimo envio.

select companyname, address
from customers c
where customerid = (
	select customerid
	from orders o
	where o.shippeddate = (
		select max(o2.shippeddate)
		from orders o2)
	order by orderid desc
	limit 1);

select companyname, address
from customers c
where customerid = (
	select customerid
	from orders
	where shippeddate is not null
	order by (shippeddate, orderid) desc
	limit 1);	

--3) Listado con nombre de los clientes que alguna vez compraron el producto Queso Cabrales
 			
select companyname 
from customers as c
where exists (
	select companyname  
	from orders as o
	where 
		c.customerid = o.customerid and exists(
			select companyname	
			from orderdetails as od
			where			 
				o.orderid = od.orderid and od.productid =(	 
					select p.productid	
					from products as p
					where p.productname ilike '%queso cabrales%'
				)
		)
);
				

--4) Numero de orden, Fecha de Orden, Fecha de envio, Total de la orden (considerando descuentos)
--   de todas las ordenes del cliente Rancho grande.

select orderid, customerid, orderdate,	shippeddate, (
	select sum(quantity * unitprice- discount) as total
	from orderdetails od
	where od.orderid = o1.orderid
	)
from orders o1
where exists (
	select orderid
	from customers c1
	where 
		c1.customerid = o1.customerid
		and companyname ilike  '%rancho grande%') 
;
-- 5. Listado de productos que no se hayan vendido en octubre del anio 1997.

select productname
from products as p
where p.productid not in (
	select productid
	from orderdetails as od
	where od.orderid in (
		select orderid
		from orders
		where shippeddate between '19971001' and '19971031'
	)
)
;

--6) Listado de productos que no se hayan vendido en el segundo semestre de 1997
select productid, productname
from products p
where productid not in (
	select od.productid
	from orderdetails od
	where od.orderid in (
		select o.orderid
		from orders o
		where o.orderdate between '1997-07-01' and '1997-12-31'
	)
)
order by productid;

--7) Listado alfabetico de proveedores cuyos productos no se hayan enviado en ninguna orden en el
--   mes de mayo del anio 1998.

select companyname  
from suppliers s
where not exists (
	select p.productid,	p.productname
	from products p
	where
		p.supplierid = s.supplierid
		and p.productid in (
			select od.productid
			from orderdetails od
			where od.orderid in (
				select o.orderid
				from orders o
				where o.shippeddate between '1998-05-01' and '1998-05-31'
			)
		)
)
order by companyname;

--8. Listado alfabatico de los empleados que tengan al menos 2 subordinados.

select *
from employees as e
where (
	select count(reportsto)
	from employees
	where e.employeeid = reportsto
) >= 2
order by lastname,	firstname
;

select lastname,firstname, employeeid, reportsto
from employees e
where e.reportsto >= 2
order by lastname,	firstname
;