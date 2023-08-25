/* 
 * Integrantes: Ezequiel Lizandro Dzioba, Maximiliano Ezequiel Rivas
 * Grupo: 3
*/

-- 1)Apellidos Nombres de los empleados, ordenados en forma alfabética

select lastname, firstname
from employees
order by lastname, firstname;

-- 2)Listado alfabético de los empleados que tengan 30 años de edad o más, de la forma “Sr. Perez, Juan”.

select concat(titleofcourtesy, ' ', lastname, ', ', firstname) as empleados
from employees
where (date_part('year', age(birthdate)) >= 30)
order by lastname;

-- 3)Fecha y dirección de los primeros 20 envíos realizados en el año 1996

select shippeddate,	shipaddress
from orders
where date_part('year', shippeddate) = '1996'
order by shippeddate
limit 20;

-- 4)País, Nombre, Dirección, Teléfono y Fax de los clientes ordenados por país y sólo para aquellos 
-- clientes que tienen fax.

select country,	contactname, address, phone, fax
from customers
where fax is not null
order by country;

-- 5)Nombre de los clientes que residan en ciudades cuyo código postal comience con letra.

select contactname, postalcode
from customers
where postalcode between 'A' and 'z';
--MAL

select contactname, postalcode
from customers
where lower(postalcode) between 'a' and 'z'
;
--CORRECTO

-- 6)Nombre y teléfono de los clientes donde se realza contacto directo con el propietario, ordenado 
-- en forma alfabético.

select contactname,	phone
from customers 
where contacttitle ilike '%Owner%' 
order by contactname;

-- 7)Todos los datos de la última orden realizada.

select *
from orders
order by orderdate, orderid desc
limit 1;

-- 8)Apellidos, Nombre y Edad de los empleados que cumplen años en el mes en curso (sin usar 
-- constantes de fecha).

select lastname, firstname,
	date_part('year', age(birthdate)) 
from employees
where date_part('month', birthdate) = date_part('month', current_date);

-- 9)Cantidad de empleados por cada país.

select country, count(employeeid)	--No se pudo haber usado distinct
from employees
group by country;

-- 10) Cantidad de clientes por cada país

select country,	count(customerid)
from customers
group by country;

-- 11) Ciudades que tengan al menos 2 empleados (teniendo en cuenta los países).

select city
from employees 
group by country, city
having count(city) >= 2;

-- 12) Cantidad de órdenes realizadas durante el año 1998.

select count(orderid)
from orders
where date_part('year', orderdate) = '1998';

-- 13) Listado alfabético con el nombre del destinatario del envío y la cantidad de órdenes realizadas 
-- en el año 1997 por cada destinatario (ShipName).

select shipname, count(shipname) 
from orders
where date_part('year', shippeddate) = '1997'
group by shipname
order by shipname;

-- 14) Nombre, Ciudad y País de todas las calles a las que se le realizaron envíos y que sean avenidas.

select shipaddress, shipcity, shipcountry
from orders
where shipaddress ilike 'Av%'
group by shipaddress, shipcity, shipcountry;

-- 15) Ranking de envíos por cada embarcación, durante el año 1997.

select shipname, count(shipname) as envios 
from orders
where date_part('year', shippeddate) = '1997'
group by shipname
order by envios desc;

-- 16) Cantidad de órdenes realizada en cada mes del año 1998, de la forma siguiente:
-- Enero XX
-- Febrero XX
-- Marzo XX…

select
	case when date_part('month', orderdate) = 1 then 'Enero'
		when date_part('month', orderdate) = 2 then 'Febrero'
		when date_part('month', orderdate) = 3 then 'Marzo'
		when date_part('month', orderdate) = 4 then'Abril'
		when date_part('month', orderdate) = 5 then 'Mayo'
		when date_part('month', orderdate) = 6 then 'Junio'
		when date_part('month', orderdate) = 7 then 'Julio'
		when date_part('month', orderdate) = 8 then 'Agosto'
		when date_part('month', orderdate) = 9 then 'Septiembre'
		when date_part('month', orderdate) = 10 then 'Octubre'
		when date_part('month', orderdate) = 11 then 'Noviembre'
		when date_part('month', orderdate) = 12 then 'Diciembre'
		end
	as mes,	count(orderdate)
from orders
where date_part('year', orderdate) = '1998'
group by date_part('month', orderdate);
-- No pedian ordenado pero habria sido un error poner order by mes pues ordenaria por las cadenas abril, enero...

select to_char(orderdate,'TMMonth') as mes,	count(orderdate)
from orders
where date_part('year', orderdate) = '1998'
group by date_part('month', orderdate), to_char(orderdate,'TMMonth')  
;

select date_part('month', orderdate),count(orderdate)
from orders
where date_part('year', orderdate) = '1998'
group by date_part('month', orderdate)
;

-- select date_part('month', orderdate) obten todos los meses de las tuplas en ordenes
-- de ordenes
--donde se cumpla que la fecha del año es igual a 1998
--a esos resultados agrupalos por mes y contalos count
--y asocialos junto con el mes