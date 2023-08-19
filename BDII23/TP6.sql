-- Grupo 3, Integrantes: Ezequiel Lizandro Dzioba Maximiliano Ezequiel Rivas

--1) Rehacer las consultas del Trabajo Practico 5, cambiando todas las subconsultas que sean
-- posibles, por su correspondiente reunion.

--1 TP5
--Listado alfabetico con los nombres y domicilios de los clientes que realizaron compras durante
--el mes de octubre del anio 1997.

select c.customerid, c.companyname,	c.address
from  customers c inner join orders o on c.customerid = o.customerid
where date_part('month', o.orderdate) = 10	and date_part('year', o.orderdate) = 1997
group by c.customerid, c.companyname
order by c.companyname;

--2 TP5
--Nombre y domicilio del cliente a quien se le realiza el ultimo envio.

select c.customerid, c.companyname,	c.address
from customers c inner join orders o on c.customerid = o.customerid
where o.shippeddate = (
	select max(o2.shippeddate)
	from orders o2
					)
order by o.orderid desc
limit 1;


--3 TP5
--Listado con nombre de los clientes que alguna vez compraron el producto Queso Cabrales.

select c.customerid, c.companyname
from customers c inner join orders o using(customerid) inner join orderdetails od using(orderid) inner join products p using(productid)
where trim(p.productname) ilike 'queso cabrales'
group by c.customerid
order by c.customerid;


--4 TP5
--Numero de orden, Fecha de Orden, Fecha de envio, Total de la orden (considerando descuentos)
--de todas las ordenes del cliente Rancho grande.

select o.orderid, o.orderdate,	o.shippeddate, sum((od.unitprice * od.quantity) - od.discount) as TotalOrden
from orderdetails od inner join orders o using(orderid) inner join customers c using(customerid)
where trim(c.companyname) ilike 'rancho grande'
group by o.orderid
order by o.orderid;

--5 TP5
--Listado de productos que no se hayan vendido en octubre del anio 1997.

select p.productid, p.productname
from products p
where p.productid not in (
	select od.productid
	from orderdetails od inner join orders o using(orderid)
	where o.shippeddate between '19971001' and '19971101'		
	)
;

-- Contar cuantas ordenes hay por cada cliente en cada mes
select c.companyname, date_part('year', o.orderdate), date_part('month', o.orderdate), count(orderid)
from customers c inner join orders o using(customerid)
group by 1,2,3
order by 1,2,3
;

-- Contar cuantas ordenes hay por cada cliente en cada mes, mostrando el nombre del mes
select c.companyname, date_part('year', o.orderdate), to_char(orderdate, 'TMMonth'), count(orderid)
from customers c inner join orders o using(customerid)
group by 1, 2, 3, date_part('month', o.orderdate)
order by 1, 2, date_part('month', o.orderdate)
;

-- mostrar todos las ordenes de la fecha en la que se realizo la ultima orden
select customerid, orderdate
from orders
where to_char(orderdate,'YYYY-MM') = (
	select to_char(max(orderdate),'YYYY-MM')
	from orders
	)
order by orderdate
;


-- contar cuantas ordenes hay por cada cliente en cada mes, mostrando el nombre del mes
select c.companyname, o.orderdate, to_char(orderdate, 'TMMonth'), count(orderid)
from customers c inner join orders o using(customerid)
group by c.companyname, 
o.orderdate,
date_part('year', o.orderdate),
to_char(orderdate, 'TMMonth'),
date_part('month', o.orderdate)
order by
c.companyname,
date_part('year', o.orderdate),
date_part('month', o.orderdate);

--6 TP5
--Listado de productos que no se hayan vendido en el segundo semestre de 1997
					
select p.productid, p.productname
from products p
where p.productid not in (
	select od.productid
	from orderdetails od inner join orders o using(orderid)
	where o.shippeddate between '19970701' and '19971231'
	)
;

--7 TP5
--Listado alfabetico de proveedores cuyos productos no se hayan enviado en ninguna orden en el
--mes de mayo del anio 1998.

select s.supplierid, s.companyname
from suppliers s 
where s.supplierid not in (
	select p.supplierid
	from products p inner join orderdetails od using(productid) inner join orders o using(orderid)
	where o.shippeddate between '19980501' and '19980531'
	)
order by s.supplierid;

--8 TP5
--Listado alfabetico de los empleados que tengan al menos 2 subordinados.

select e.lastname, e.firstname
from employees e inner join employees e2 on e.employeeid = e2.reportsto
group by e.lastname, e.firstname, e.reportsto
having count (e2.reportsto)>= 2
order by e.lastname, e.firstname
;

--2) Mostrar el detalle de cada orden, id de la misma, fecha, identificacion 
-- de cada articulo (Id y Nombre), cantidad de articulos, importe unitario y subtotal de cada item.

select od.orderid, o.orderdate, p.productid, p.productname,	od.quantity, od.unitprice, sum(od.quantity * od.unitprice) as SubTotal
from orders o inner join orderdetails od using(orderid) inner join products p using(productid)
group by od.orderid, o.orderdate, p.productid, p.productname, od.quantity, od.unitprice;

--3) Mostrar todos los atributos de cada orden junto a id y nombre del cliente y el empleado que la confeccionen.

select c.customerid, c.companyname,	e.employeeid, e.lastname, e.firstname, o.*
from employees e  inner  join orders o using (employeeid) left join customers c using(customerid)
order by c.customerid, c.companyname, e.employeeid,	e.lastname,	e.firstname;

--4) Mostrar la cantidad total de productos vendidos por mes.

select date_part ('year',orderdate) as Anio, (
	case 
        when date_part ('month',orderdate)= 1 then 'enero'  
        when date_part ('month',orderdate)= 2 then 'febrero'
        when date_part ('month',orderdate)= 3 then 'marzo '
        when date_part ('month',orderdate)= 4 then 'abril'
        when date_part ('month',orderdate)= 5 then 'mayo'
        when date_part ('month',orderdate)= 6 then 'junio'
        when date_part ('month',orderdate)= 7 then 'julio'
        when date_part ('month',orderdate)= 8 then 'agosto'
        when date_part ('month',orderdate)= 9 then 'septiembre'
        when date_part ('month',orderdate)= 10 then 'octubre'
        when date_part ('month',orderdate)= 11 then 'noviembre'
        when date_part ('month',orderdate)= 12 then 'diciembre'
      	end)
	as mes,
    sum (od.quantity)
from orders o inner join orderdetails od  using(orderid) 
group by date_part ('year',orderdate), date_part ('month',orderdate) 
order by date_part ('year',orderdate), date_part ('month',orderdate);

--5) Mostrar nombre, id y domicilios de clientes, incluyendo la cantidad de ordenes acumuladas por cada mes.

select c.customerid, c.companyname,	c.address, date_part('year', o.orderdate) as Anio, (
	case
		when date_part('month', o.orderdate) = 1 then 'Enero'
		when date_part('month', o.orderdate) = 2 then 'Febrero'
		when date_part('month', o.orderdate) = 3 then 'Marzo'
		when date_part('month', o.orderdate) = 4 then 'Abril'
		when date_part('month', o.orderdate) = 5 then 'Mayo'
		when date_part('month', o.orderdate) = 6 then 'Junio'
		when date_part('month', o.orderdate) = 7 then 'Julio'
		when date_part('month', o.orderdate) = 8 then 'Agosto'
		when date_part('month', o.orderdate) = 9 then 'Septiembre'
		when date_part('month', o.orderdate) = 10 then 'Octubre'
		when date_part('month', o.orderdate) = 11 then 'Noviembre'
		when date_part('month', o.orderdate) = 12 then 'Diciembre'
		end) as Mes,
	count(*) as CantOrdenes 
from customers c inner join orders o using(customerid)
group by c.customerid, date_part('year', o.orderdate), date_part('month', o.orderdate)
order by c.customerid, date_part('year', o.orderdate), date_part('month', o.orderdate);

--6) Mostrar id, nombre y domicilio de los empleados junto a al monto total de ordenes de
--todos sus subordinados.

select j.employeeid, j.lastname, j.firstname, j.address, sum((od.unitprice * od.quantity) - od.discount) as MontoTotal
from orderdetails od inner join orders o using(orderid) inner join employees e on o.employeeid = e.employeeid inner join employees j on e.reportsto = j.employeeid
group by j.employeeid 
order by j.employeeid;

--7) Mostrar todos los productos (id y nombre) junto con las cantidades vendidas de cada uno
-- en el ultimo mes del que se tenga informacion. (Preferentemente no utilizar constantes de fechas).

select p.productid,	p.productname,	coalesce(sum(od.quantity), 0) as Cantidad
from orderdetails od inner join (
	select * from orders o 
	where to_char(o.orderdate, 'YYYYMM') = (select to_char(max(o2.orderdate), 'YYYYMM') from orders o2)) as o2
	on od.orderid = o2.orderid
	right join products p on od.productid = p.productid 
group by 1, 2
order by 1, 2;
