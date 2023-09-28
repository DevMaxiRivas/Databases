-- 1. Listar id, apellido y nombre de los cliente ordenados en un ranking decreciente, según la 
-- función del contacto (dentro de la empresa) contacttitle.
-- CORREGIR
select
    customerid,
    companyname,
    contacttitle,
    dense_rank() over (order by contacttitle desc) as ranking
from customers
order by ranking asc;

	
-- 2. Mostrar, por cada mes del año 1997, la cantidad de ordenes generadas, junto a la cantidad de 
-- ordenes acumuladas hasta ese mes (inclusive). El resultado esperado es el mismo que el 
-- obtenido en el ejercicio 2.g del trabajo práctico 1.
select
	to_char(orderdate,'TMMonth') as month,
	count(orderid) as quantity,
    sum(count(orderid)) over (order by date_part('month',orderdate)) as accumulated_orders 
from orders
where date_part('year',orderdate) = '1997'
group by date_part('month',orderdate),1
;

-- 3. Listar todos los empleados agregando las columnas: salario, salario promedio, ranking según 
-- salario del empleado, ranking según salario del empleado en la ciudad. Utilizando la definición 
-- explícita de ventanas
select 
    employeeid,
    concat(lastname,' ', firstname) as name,
    salary,
    avg(salary) over () as average,
    dense_rank() over (order by salary desc) as salary_ranking,
    country,
    dense_rank() over (partition by country order by salary desc) as country_salary_ranking
from employees 
order by country, salary desc;

-- 4. Listar los mismos datos del punto anterior agregando una columna con la diferencia de salario 
-- con el promedio. Utilizando la definición explícita de ventanas
select 
    employeeid,
    concat(lastname,' ', firstname) as name,
    salary,
    avg(salary) over () as average,
    dense_rank() over (order by salary desc) as salary_ranking,
    dense_rank() over (partition by country order by salary desc) as country_salary_ranking,
    salary - avg(salary) over () as difference_from_the_average
from employees 
order by salary desc;

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
		productid,
		row_number() over (partition by productid order by orderdate) as operationorder,
		orderdate,
		companyname,
		quantity
	from 
		customers
		inner join orders using(customerid)
		inner join orderdetails using(orderid)
	order by 1,2
;

--Test
select * from movements;	

-- 6. Listar apellido, nombre, ciudad y salario de los empleados acompañado de la resta del salario 
-- con el salario de la fila anterior de la misma ciudad. El resultado esperado es similar a:

select 
	lastname,
	firstname,
	city,
	salary,
	salary - lag(salary) over (partition by city order by salary) as difference
from
	employees
;


-- Muestra todos los productos agregando el promedio de precios y cantidad por categoria
select count(productid) from products;
select
	c. categoryname, p. productid, p. productname, p. unitprice,
	count(*) over (partition by c. categoryname) as cantidad, 
	avg(p.unitprice ) over (partition by c.categoryname) as promedioporcategoria
from
	categories c
	inner join products p using(categoryid)
order by c.categoryname, p. productname
;
-- Define una ventana "particionando" por nombre de la categoria y por el nombre del producto
select
c.categoryname, p. productid, p. productname, p. unitprice,
rank() over (order by c. categoryname, p. productname) as orden
from
categories c
inner join products p using(categoryid)
order by c. categoryname, p. productname
;

-- Define una ventana "particionando" por nombre de la categoria y "ordenamos" por el nombre del producto
 select
	c. categoryname, p. productid, p. productname, p. unitprice,
	rank() over (partition by c. categoryname order by p. productname) as orden
from
	categories c
	inner join products p using(categoryid)
orde r by c. categoryname, p. productname
;

-- Muestra todos los productos repitiendo en cada fila el promedio general
select
	c.categoryname, p.productid, p.productname, p. unitprice,
avg(unitprice) over() as avg
from 
	categories c
	inner join products p using(categoryid)
order by c. categoryname,p. productname
;

-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
select
	c.categoryname, p.productid, p. productname, p.unitprice,
	avg(unitprice) over( ) as preciopromediogeneral,
	avg(unitprice) over(partition by c.categoryname) as preciopromediocategoria
from
	categories c 
	inner join products p using(categoryid)
order by c. categoryname, p. productname
;

-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
-- Agregando la diferencia entre el precio de cada producto 
-- y el promedio segun categoria
 
select
c. categoryname, p. productid, p. productname, p. unitprice,
avg(unitprice) over ( ) as preciopromediogeneral,
avg(unitprice) over (partition by c. categoryname) as preciopromediocategoria,
p. unitprice - avg(unitprice) over (partition by c. categoryname) as diferenciapromedio
from
categories c
inner join products p using(categoryid)
order by c.categoryname, p.productname
;

-- Muestra todos los productos repitiendo en cada fila el promedio general
-- Agregando el promedio por categoria
-- Agregando la diferencia entre el precio de cada producto 
-- y el promedio segun categoria
-- Agregando ranking de precios por categoria
select
	c. categoryname, p. productid, p. productname, p. unitprice,
	avg(unitprice) over ( ) as preciopromediogeneral,
	avg(unitprice) over (partition by c.categoryname) as preciopromediocategoria,
	p. unitprice - avg(unitprice) over (partition by c. categoryname) as diferenciapromedio,
	rank() over(partition by c. categoryname order by p. unitprice)
from
	categories c
	inner join products p using(categoryid)
order by c.categoryname, p.unitprice
;
-- Diferencia entre dense_rank() y rank() 
-- Por ejemplo rank() si se tiene dos filas con rank 3 el siguiente en el ranking sera 5
-- Por ejemplo dense_rank() si se tiene dos filas con rank 3 el siguiente en el ranking sera 4

select
	c. categoryname, p. productid, p. productname, p. unitprice,
	avg(unitprice) over ( ) as preciopromediogeneral,
	avg(unitprice) over (partition by c.categoryname) as preciopromediocategoria,
	p. unitprice - avg(unitprice) over (partition by c. categoryname) as diferenciapromedio,
	dense_rank() over(partition by c. categoryname order by p. unitprice)
from
	categories c
	inner join products p using(categoryid)
order by c.categoryname, p.unitprice
;