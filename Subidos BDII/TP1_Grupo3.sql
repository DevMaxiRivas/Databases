-- Trabajo Práctico 3
-- Base de Datos II
-- Grupo 3:
    -- Rodrigo Kanchi Flores
    -- Maximiliano Ezequiel Rivas
    -- Ezequiel Lizandro Dzioba

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
select orderid
from orders 
limit 1;


create or replace function update_stock()
returns trigger as
$$
declare 
begin
	case 
		when TG_OP = 'UPDATE' then -- Caso Update
		update products set unitsinstock = unitsinstock + old.quantity - new.quantity
		where productid = old.productid
		;
		when TG_OP = 'INSERT' then -- Caso Insert
		update products set unitsinstock = unitsinstock - new.quantity
		where productid = new.productid
		;
		when TG_OP = 'DELETE'then -- Caso Delete
		update products set unitsinstock = unitsinstock + old.quantity
		where productid = old.productid
		;
	end case;
	return new;
end;
$$
language plpgsql;

create trigger modify_orderdetails after insert or update or delete
on orderdetails for each row execute procedure update_stock();

-- Test
insert into orderdetails values (10248,1,14.00,10,0);
delete from orderdetails where orderid = 10248 and productid  = 1;
update orderdetails set quantity = '15' where orderid = '10248' and productid = '1';

update products set unitsinstock = 29 where productid = 1; 

select productid, unitsinstock
from products 
where productid = 1;

-- d. Realizar un disparador de auditoría sobre la actualización de datos de los clientes. Se 
-- debe almacenar el nombre del usuario la fecha en la que se hizo la actualización, la 
-- operación realizada (alta/baja/modificación) y el valor que tenía cada atributo al 
-- momento de la operación. 
drop table audits;
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
)
;

create or replace function user_auditing()
returns trigger as 
$$
begin -- Caso update
	case 
		when TG_OP = 'UPDATE' then
			insert into audits values
			(
			default,current_user,current_timestamp,TG_OP,
			old.customerid,old.companyname,old.contactname,old.contacttitle,old.address,old.city,old.region,old.postalcode,old.country,old.phone,old.fax,
			new.customerid,new.companyname,new.contactname,new.contacttitle,new.address,new.city,new.region,new.postalcode,new.country,new.phone,new.fax
			);
		when TG_OP = 'INSERT' then -- Caso Insert
			insert into audits values
			(
			default,current_user,current_timestamp,TG_OP,
			null,null,null,null,null,null,null,null,null,null,null,
			new.customerid,new.companyname,new.contactname,new.contacttitle,new.address,new.city,new.region,new.postalcode,new.country,new.phone,new.fax
			);
		when TG_OP = 'DELETE'then -- Caso Delete
			insert into audits values (default,current_user,current_timestamp,TG_OP,
			old.customerid,old.companyname,old.contactname,old.contacttitle,old.address,old.city,old.region,old.postalcode,old.country,old.phone,old.fax,
			null,null,null,null,null,null,null,null,null,null,null
			);
	end case;
	return new;
end;
$$
language plpgsql;

create trigger modify_customers after insert or update or delete
on customers for each row execute procedure user_auditing();

--Test
truncate audits;
select * from audits;

insert into customers values
('NEWUS','Alfreds Futterkiste','Maria Anders','Sales Representative','Obere Str. 57',
'Berlin','12209','Germany','030-0074321','030-0076545')
;
update customers set contactname = 'NEWCO' where customerid ilike '%NEWUS%';
delete from customers where customerid ilike '%NEWUS%';

-- e. Agregar atributos en el encabezado de la Orden que registren la cantidad de artículos 
-- del detalle y el importe total de cada orden. Realizar los triggers necesarios para 
-- mantener la redundancia controlada de los nuevos atributos.

alter table orders add column quantity int4 default '0';
alter table orders add column total numeric(10, 2) default '0'; 
alter table orders drop column total;

create or replace function subtotal_orders()
returns trigger as
$$
begin 
	case 
		when TG_OP = 'UPDATE' then
			if new.quantity != old.quantity then
				update orders 
				set quantity = quantity - old.quantity + new.quantity
				;
			end if;
			if new.unitprice != old.unitprice or new.quantity != old.quantity then
				update orders 
				set total = total - old.quantity * old.unitprice + new.quantity * new.unitprice
				;
			end if;	
		when TG_OP = 'INSERT' then 
			update orders 
			set quantity = quantity + new.quantity
			;
			update orders 
			set total = total + new.quantity * new.unitprice
			;
		when TG_OP = 'DELETE' then 
			update orders 
			set quantity = quantity - old.quantity
			;
			update orders 
			set total = total - old.unitprice * old.quantity
			;
	end case;
	return new;
end;
$$
language plpgsql;

create trigger total_orders after insert or update or delete
on orderdetails for each row execute procedure subtotal_orders();

select orderid,quantity,total from orders where orderid = 10248;
update orders set quantity = 0, total = 0 where orderid= 10248;

insert into orderdetails values (10248,1,14.00,10,0);
update orderdetails set unitprice = '20' where orderid = '10248' and productid = '1';
delete from orderdetails where orderid = 10248 and productid  = 1;


-- RESOLUCION CRISTIAN FRANCO

-- Primero agregamos al encabezado lo correspondiente
alter table orders add column productsquantity int;
alter table orders add column amountstotal money;

create or replace function contar_calcular_orders(pi_orderid int)
returns record as
$$
declare
	lr_aux record;
begin
	--select count(orderid) quantity, sum(quantity * unitprice) amount
	select sum(quantity) quantity, sum(quantity * unitprice) amount
	from orderdetails o
	where o.orderid = pi_orderid 
	into lr_aux;
	return lr_aux;
end;
$$language plpgsql;

create or replace function modifica_orders()
returns void as
$$
declare
	lr_aux record;
	lr_aux_2 record;
begin 
	for lr_aux in 
		select orderid 
		from orders
	loop
		lr_aux_2 = contar_calcular_orders(lr_aux.orderid);
		update orders 
			set 
				productsquantity = lr_aux_2.quantity,
				amountstotal = lr_aux_2.amount
		where orderid = lr_aux.orderid;
	end loop;
end;
$$
language plpgsql;

select * from orderdetails o order by orderid;
select modifica_orders();
select orderid, productsquantity, amountstotal from orders order by orderid;

create or replace function f_mantener_redundancia()
returns trigger as 
$$
declare
	lr_aux record;
	lr_op record;
begin
	if tg_op = 'DELETE' then
		lr_op = old;
	else
		lr_op = new;
	end if;
	lr_aux = contar_calcular_orders(lr_op.orderid);
	update orders 
	set 
		productsquantity = lr_aux.quantity,
		amountstotal = lr_aux.amount
	where orderid = lr_op.orderid;
	raise notice 'Se actualizo productquantity: % y amount: % , de la orden: %',lr_aux.quantity, lr_aux.amount, lr_op.orderid;
	return lr_op;
end;
$$
language plpgsql;

-- F) Realizar triggers a elección para probar las siguientes combinaciones y
-- situaciones respondiendo las siguientes consultas:

-- BEFORE - FOR STATEMENT ------------------------------------------------------

CREATE OR REPLACE FUNCTION before_for_statement()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE '[BEFORE STMT] NEW = %', NEW; -- (i)
    IF 0 < (SELECT COUNT(*) FROM countries WHERE country = 'URU')
    AND TG_OP != 'DELETE' THEN
        RAISE EXCEPTION '[BEFORE STMT] Uruguay existe :O' -- (iii)
        USING HINT = 'Elimina a Uruguay ;)';
    END IF;
    RETURN NULL; -- (ii)
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER before_for_statement BEFORE INSERT OR UPDATE OR DELETE
ON countries FOR STATEMENT
EXECUTE FUNCTION before_for_statement();

-- i. ¿Qué sucede con la variable NEW?

-- NEW es NULL.
DELETE FROM countries
WHERE country = 'CAN'; -- NEW = <NULL>

-- ii. ¿Qué sucede ante un RETURN NULL?

-- La ejecución de la función finaliza, por lo que el trigger y la transacción
-- también finalizan y los cambios se ven aplicados.
INSERT INTO countries VALUES ('Canada', 'CAN');

-- iii. ¿Qué sucede ante un RAISE EXCEPTION?

-- La transacción se interrumpe y todos los cambios se deshacen (rollback).
INSERT INTO countries VALUES ('Uruguay', 'URU');
UPDATE countries SET descripcountry = 'uruguay' WHERE country = 'URU';
DELETE FROM countries WHERE country = 'URU';
INSERT INTO countries VALUES
    ('emiratos árabes unidos', 'ARE'),
    ('Bolivia', 'BOL');

-- AFTER - FOR EACH ROW --------------------------------------------------------

CREATE OR REPLACE FUNCTION after_for_each_row()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    RAISE NOTICE '[AFTER ROW] NEW = %', NEW; -- (iv)
    IF TG_OP != 'DELETE' THEN
        NEW.descripcountry := UPPER(NEW.descripcountry); -- (v)
        RAISE NOTICE '[AFTER ROW] NEW* = %', NEW;
    END IF;
    CASE NEW.country
        WHEN 'ARE', 'USA' THEN RETURN NEW; -- (v)
        WHEN 'ERR' THEN RAISE EXCEPTION '[AFTER ROW] Algo salió mal.'; -- (vii)
        ELSE RETURN NULL; -- (vi)
    END CASE;
END
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER after_for_each_row AFTER INSERT OR UPDATE OR DELETE
ON countries FOR EACH ROW
EXECUTE FUNCTION after_for_each_row();

-- iv. ¿Qué sucede con la variable NEW?

-- INSERT: toma los valores de la fila a insertar.
INSERT INTO countries VALUES ('Nombre', 'Cod'); -- NEW = (Nombre,Cod)

-- UPDATE: toma los valores de la fila a actualizar y sus correspondientes
-- modificaciones.
UPDATE countries SET descripcountry = 'bolivia'
WHERE country = 'BOL'; -- NEW = (bolivia,BOL)

-- DELETE: es NULL.
DELETE FROM countries WHERE country = 'CHI'; -- NEW = <NULL>

-- v. ¿Qué sucede ante una modificación de valores de NEW y RETURN NEW?

-- A diferencia de BEFORE (FOR EACH ROW), los cambios hechos a NEW solo existen
-- durante la ejecución de la funcióm y no persisten luego de la transacción al
-- usar RETURN NEW.
UPDATE countries SET descripcountry = 'United States'
WHERE country = 'USA'; -- NEW* = ("UNITED STATES",USA)
SELECT descripcountry FROM countries WHERE country = 'USA'; -- United States

-- vi. ¿Qué sucede ante un RETURN NULL?

-- A diferencia de BEFORE (FOR EACH ROW), RETURN NULL no evita el INSERT, UPDATE
-- o DELETE y simplemente finaliza la ejecución de la función para la fila
-- actual.
DELETE FROM countries WHERE country = 'Cod';

-- vii. ¿Qué sucede ante un RAISE EXCEPTION?

-- La transacción se interrumpe y todos los cambios se deshacen (rollback).
INSERT INTO countries VALUES ('Error', 'ERR');
