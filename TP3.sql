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


alter table customers
add column ordersquantity int4 default 0,
add column ordersamount numeric(10, 2) default 0;

alter table customers drop column ordersamount;
select customerid, ordersquantity, ordersamount
from customers
;
update customers c
set ordersquantity = (
    select count(o.orderid)
    from orders o
    where o.customerid = c.customerid
),
    ordersamount = (
    select coalesce(sum( (od.unitprice * od.quantity) - od.discount), 0)
    from 
    	orders o 
        left join orderdetails od using(orderid)
    where o.customerid = c.customerid
);



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