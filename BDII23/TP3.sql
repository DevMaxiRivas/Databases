-- 1)Crear la base de datos: Ventas

create database ventas;

-- 2)Crear las siguientes tablas dentro de la base de datos Ventas:
-- a)clientes{cli_id, cli_apellido, cli_nombre}
-- b)ventas{ven_id, cli_id FK(clientes), ven_importe}
-- c)productos{pro_id, pro_nombre, pro_precio_unitario}
-- d)detventas{ven_id FK(ventas), pro_id FK(productos), dv_cantidad}

create table ciudades(
    ciu_codigo text primary key,
    ciu_nombre text not null
);
create table clientes(
    cli_id serial primary key,
    cli_nombre text not null,
    cli_apellido text not null,
    ciu_codigo text, foreign key (ciu_codigo) references ciudades
);

create table ventas(
	ven_id serial primary key,
	cli_id serial, foreign key (cli_id) references clientes,
	ven_importe real not null
);

create table productos(
	pro_id serial primary key,
	pro_nombre text not null,
	pro_precio_unitario real not null
);
create table detventas(
	ven_id serial, foreign key (ven_id) references ventas,
	pro_id serial, foreign key (pro_id) references productos,
	dv_cantidad int not null
	);
-- 3)Agregar a la tabla clientes la columna cli_domicilio.

alter table clientes add column cli_domicilio text not null;

-- 4)Agregar a la tabla detventas la columna dv_precio_unitario.

alter table detventas add column dv_precio_unitario real not null;

-- 5)Eliminar de la tabla ventas la columna ven_importe.

alter table ventas drop column ven_importe;

-- 6)Crear un índice para la tabla productos según la columna pro_nombre.

create index nom_index
on productos (pro_nombre);

-- 7)Crear un índice para la tabla clientes según las columnas cli_apellido y cli_nombre.

create index ape_nom_index
on clientes (cli_apellido, cli_nombre);

-- 8)Crear una tabla marcas{mar_id, mar_nombre}

create table marcas(
	mar_id serial primary key, 
	mar_nombre text not null
);

-- 9)Investigar la resolución de este punto. Existiendo la tabla productos, establecer la clave foránea 
-- relacionándola con la tabla marcas a través de la columna mar_id. 

alter table productos add column mar_id serial not null;

alter table productos
add constraint mar_id
foreign key (mar_id)
references marcas (mar_id);

-- 10) Modificar el tipo de datos de la columna mar_nombre de la tabla marcas (por ejemplo dándole 
-- mayor tamaño máximo).

alter table marcas alter column mar_nombre type character(10);