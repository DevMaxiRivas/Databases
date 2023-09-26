-- 1. Listar id, apellido y nombre de los cliente ordenados en un ranking decreciente, según la 
-- función del contacto (dentro de la empresa) contacttitle.
select 
	customerid,
	companyname,
	contacttitle,
	dense_rank() over (partition by contacttitle)
from customers
;
select distinct contacttitle from customers c ;

	
-- 2. Mostrar, por cada mes del año 1997, la cantidad de ordenes generadas, junto a la cantidad de 
-- ordenes acumuladas hasta ese mes (inclusive). El resultado esperado es el mismo que el 
-- obtenido en el ejercicio 2.g del trabajo práctico 1.
sele

-- 3. Listar todos los empleados agregando las columnas: salario, salario promedio, ranking según 
-- salario del empleado, ranking según salario del empleado en la ciudad. Utilizando la definición 
-- explícita de ventanas
select 
    employeeid,
    concat(lastname,' ', firstname) as name,
    salary,
    avg(salary) over () as average,
    dense_rank() over (order by salary desc) as salary_ranking,
    dense_rank() over (partition by country order by salary desc) as country_salary_ranking
from employees 
order by salary desc;

-- 4. Listar los mismos datos del punto anterior agregando una columna con la diferencia de salario 
-- con el promedio. Utilizando la definición explícita de ventanas
select 
    employeeid,
    concat(lastname,' ', firstname) as name,
    salary,
    avg(salary) over () as average,
    dense_rank() over (order by salary desc) as salary_ranking,
    dense_rank() over (partition by country order by salary desc) as country_salary_ranking
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
-- productid operationorder orderdate Companyname Quantity
-- 1 1 1996-08-20 QUICK-Stop 45
-- 1 2 1996-08-30 Rattlesnake Canyon Grocery 18
-- 1 3 1996-09-30 Lonesome Pine Restaurant 20


-- 6. Listar apellido, nombre, ciudad y salario de los empleados acompañado de la resta del salario 
-- con el salario de la fila anterior de la misma ciudad. El resultado esperado es similar a:

-- "HOLA MUNDO"