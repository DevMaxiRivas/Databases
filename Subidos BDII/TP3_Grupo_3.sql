-- Trabajo Práctico 1
-- Base de Datos II
-- Grupo 3:
    -- Rodrigo Kanchi Flores
    -- Maximiliano Ezequiel Rivas
    -- Ezequiel Lizandro Dzioba

-- 1) Insertar en la tabla region: Noroeste Argentino, con ID 5

insert into region (regionid, regiondescription)
values (5, 'Noroeste Argentino');

-- 2) Insertar en la tabla territories al menos 5 territorios de la nueva región
-- utilizando la sintaxis multirow de INSERT

insert into territories
    (territoryid, territorydescription, regionid)
values
    (4444, 'Salta', 5),
    (4600, 'Jujuy', 5),
    (4000, 'Tucuman', 5),
    (4700, 'Catamarca', 5),
    (5300, 'La Rioja', 5);

-- 3) Crear una tabla tmpterritories con los siguientes atributos
    -- territoryid
    -- territorydescription
    -- regionid
    -- regiondescription

create table
    tmpterritories (
        territoryid varchar(20),
        foreign key(territoryid) references territories,
        territorydescription varchar(50) not null,
        regionid int4,
        foreign key(regionid) references region,
        regiondescription varchar(50) not null
    );

-- 4) Mediante la sintaxis INSERT ... SELECT llenar la tabla del punto 3
-- combinando información de las tablas region y territories

insert into tmpterritories
select
    territoryid,
    territorydescription,
    regionid,
    regiondescription
from territories join region using(regionid);

-- 5) Agregar dos columnas a la tabla customers donde se almacene:
    -- ordersquantity: con la cantidad de órdenes del cliente en cuestión
    -- ordersamount: el importe total de las órdenes realizadas

alter table customers
add column ordersquantity int4,
add column ordersamount numeric(10, 2);

-- 5.a) Mediante sentencia UPDATE ... FROM actualizar las columnas agregadas

update customers c set
    ordersquantity = a.cantidad,
    ordersamount = b.monto
from (
    select
        count(o.orderid) as cantidad,
        ca.customerid
    from customers ca left join orders o using(customerid)
    group by ca.customerid
) a, (
    select
        coalesce(sum( (od.unitprice * od.quantity) - od.discount), 0) as monto,
        cb.customerid
    from customers cb
        left join orders o using(customerid)
        left join orderdetails od using(orderid)
    group by cb.customerid
) b
where
    c.customerid = a.customerid
    and c.customerid = b.customerid;

-- 5.b) Mediante sentencia UPDATE y subconsulta actualizar las col

update customers c
set ordersquantity = (
    select count(o.orderid)
    from customers ca left join orders o using(customerid)
    where ca.customerid = c.customerid
),
    ordersamount = (
    select coalesce(sum( (od.unitprice * od.quantity) - od.discount), 0)
    from customers cb
        left join orders o using(customerid)
        left join orderdetails od using(orderid)
    where cb.customerid = c.customerid
);

-- 6) Desarrollar las sentencias necesarias que permitan eliminar todo el
-- historial de òrdenes de un cliente cuyo dato conocido es companyname,
-- utilizando DELETE ... USING

-- Primero se eliminan los detalles, porque hacen referencia (FK) a las órdenes
-- que se quieren eliminar
delete from orderdetails od
using orders o, customers c
where
    od.orderid = o.orderid
    and o.customerid = c.customerid
    and c.companyname ilike ('nombre del cliente%')
;

-- Una vez eliminados los detalles, se eliminan las órdenes
delete from orders o
using customers c
where
    c.customerid = o.customerid
    and c.companyname ilike ('nombre del cliente%');
