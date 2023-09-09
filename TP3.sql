-- a. Crear un disparador para impedir que ingresen dos proveedores en el mismo 
-- domicilio. (tener en cuenta la ciudad y país).

create function supplier_address_verification()
returns trigger as
$$
declare ls_result smallint;
begin
	ls_result = (
		select coalesce(count(supplierid),0)
		from suppliers
		where 
			trim(address) ilike trim(new.address)
			and trim(country) ilike trim(new.country)
			and trim(city) ilike trim(new.city) 
	);
	if ls_result > 0 then 
		raise notice 'There is a supplier with this address';
		return NULL;
	else 
		return NEW;
	end if;
end;
$$
language plpgsql;

insert into suppliers values 
(145,'Prueba','MR','MR','49 Gilbert St.','London','Alguna','AAAA','UK','654646','FAX','www.pag.com');

create trigger add_supplier before insert or update on suppliers
for each row execute procedure supplier_address_verification();

-- b. Realizar un disparador que impida incluir en un detalle de orden, cantidades no 
-- disponibles. 
create or replace function stock_revision()
returns trigger as
$$
declare li_current_stock int4;
begin
	li_current_stock := (
		select unitsinstock
		from products
		where productid = new.productid
	);
	if li_current_stock > new.quantity then
		return new;
	else 
		raise notice 'Insufficient units';
		return null;
	end if;
end;
$$
language plpgsql;

create trigger new_orderdetails before insert or update on orderdetails
	for each row execute procedure stock_revision();

insert into orderdetails values (10251,1,'123','1000','20');

-- c. Realizar un disparador que actualice el nivel de stock cuando se crean, modifican o 
-- eliminan órdenes (y sus detalles). 

create or replace function 


-- d. Realizar un disparador de auditoría sobre la actualización de datos de los clientes. Se 
-- debe almacenar el nombre del usuario la fecha en la que se hizo la actualización, la 
-- operación realizada (alta/baja/modificación) y el valor que tenía cada atributo al 
-- momento de la operación. 



-- e. Agregar atributos en el encabezado de la Orden que registren la cantidad de artículos 
-- del detalle y el importe total de cada orden. Realizar los triggers necesarios para 
-- mantener la redundancia controlada de los nuevos atributos.



-- f. Realizar triggers a elección para probar las siguientes combinaciones y situaciones 
-- respondiendo las siguientes consultas
-- BEFORE - FOR STATEMENT
-- i. ¿Qué sucede con la variable NEW?
--	La variable new queda en estado NULL

-- ii. ¿Qué sucede ante un RETURN NULL?
-- Postgres no realiza lo que tiene en el
-- trigger y termina la ejecucion.

-- iii. ¿Qué sucede ante un RAISE EXCEPTION?
-- Cuando ocurre un RAISE EXCEPTION se para la
-- ejecucion de la consulta y se hace un rollback
-- del estado anterior de la base de datos

-- AFTER - FOR EACH ROW
-- iv. ¿Qué sucede con la variable NEW?
-- La variable NEW queda en estado NULL

-- v. ¿Qué sucede ante una modificación de valores de NEW y RETURN NEW?
-- vi. ¿Qué sucede ante un RETURN NULL?
-- vii. ¿Qué sucede ante un RAISE EXCEPTION?