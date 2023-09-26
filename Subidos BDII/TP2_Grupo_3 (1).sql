-- Trabajo Práctico 2
-- Base de Datos II
-- Grupo 3:
    -- Rodrigo Kanchi Flores
    -- Maximiliano Ezequiel Rivas
    -- Ezequiel Lizandro Dzioba

-- A) Crear una función que permita eliminar espacios en blanco innecesarios
-- (trim) de una columna de una tabla. Los nombres de columna y tabla deben ser
-- pasados como parámetros y la función deberá devolver como resultado la
-- cantidad de filas afectadas.

CREATE OR REPLACE FUNCTION custom_trim(pt_columna TEXT, pt_tabla TEXT)
RETURNS INT AS $$
DECLARE li_filas INT := 0;
BEGIN
    EXECUTE FORMAT('
        UPDATE %1$I
        SET %2$I = TRIM(%2$I)
        WHERE %2$I != TRIM(%2$I);',
        pt_tabla, pt_columna
    );
    GET DIAGNOSTICS li_filas = ROW_COUNT;
    RETURN li_filas;
END;
$$ LANGUAGE PLPGSQL;

-- Prueba:
SELECT custom_trim('companyname','customers');

-- B) Programar una función que reciba como parámetro un orderid y devuelva una
-- cadena de caracteres (resumen) con el id, nombre, precio unitario y cantidad
-- de todos los productos incluidos en la orden en cuestión.

CREATE OR REPLACE FUNCTION detalle_orden(pi_orderid INTEGER)
RETURNS TEXT AS $$
DECLARE
    lr_fila RECORD;
    lt_texto TEXT := FORMAT(
        '%-2s %-35s %10s %8s',
        'ID', 'Nombre', 'Precio (u)', 'Cantidad'
    );
BEGIN
    FOR lr_fila IN
        SELECT p.productid, p.productname, od.unitprice, od.quantity
        FROM products p JOIN orderdetails od USING(productid)
        WHERE orderid = pi_orderid
    LOOP
        lt_texto := FORMAT(
            E'%s\n%-2s %-35s %10s %8s',
            lt_texto,
            lr_fila.productid,
            TRIM(lr_fila.productname),
            lr_fila.unitprice,
            lr_fila.quantity
        );
    END LOOP;
    RETURN lt_texto;
END;
$$ LANGUAGE PLPGSQL;

-- C) Prueba con orderid = 11077

SELECT detalle_orden(11077);

-- D) Crear una función que muestre por cada detalle de orden: el nombre del
-- cliente, la fecha, la identificación de cada artículo (id y nombre),
-- cantidad, importe unitario y subtotal de cada ítem para un intervalo de
-- tiempo dado por parámetros.

CREATE OR REPLACE FUNCTION detalle_ordenes(pd_desde DATE, pd_hasta DATE)
RETURNS TABLE (
    companyname VARCHAR(40),
    orderdate DATE,
    productid INTEGER,
    productname VARCHAR(40),
    quantity INTEGER,
    unitprice NUMERIC(10, 2),
    subtotal NUMERIC(10, 2)
) AS $$
BEGIN
    RETURN QUERY
        SELECT
            c.companyname,
            o.orderdate,
            p.productid,
            p.productname,
            od.quantity,
            od.unitprice,
            od.unitprice * od.quantity AS subtotal
        FROM orders o
            JOIN orderdetails od USING(orderid)
            JOIN products p USING(productid)
            JOIN customers c USING(customerid)
        WHERE o.orderdate BETWEEN pd_desde AND pd_hasta;
END;
$$ LANGUAGE PLPGSQL;

-- Prueba (Hay órdenes desde 1996-07-04 hasta 1998-05-06):
SELECT * FROM detalle_ordenes('1996-07-04', '1997-01-01');

-- E) Función para el devolver el total de una orden dada por parámetro.

CREATE OR REPLACE FUNCTION total_orden(pi_orderid INTEGER)
RETURNS NUMERIC(10, 2) AS $$
DECLARE li_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(od.unitprice * od.quantity - od.discount), 0)
        INTO li_total
        FROM orders o JOIN orderdetails od USING(orderid)
        WHERE orderid = pi_orderid;
    RETURN li_total;
END;
$$ LANGUAGE PLPGSQL;

-- Prueba:
SELECT total_orden(10248);

-- F) Crear una función donde se muestren todos los atributos de cada Orden
-- junto a Id y Nombre del Cliente y el Empleado que la confeccionó. Mostrar el
-- total utilizando la función del punto anterior.

CREATE OR REPLACE FUNCTION ordenes()
RETURNS TABLE (
    orderid INTEGER,
    customerid VARCHAR(5),
    employeeid INTEGER,
    orderdate DATE,
    requireddate DATE,
    shippeddate DATE,
    shipvia INTEGER,
    freight NUMERIC(10, 2),
    shipname VARCHAR(40),
    shipaddress VARCHAR(60),
    shipcity VARCHAR(15),
    shipregion VARCHAR(15),
    shippostalcode VARCHAR(10),
    shipcountry VARCHAR(15),
    cliente VARCHAR(40), -- nuevo
    empleado TEXT, -- nuevo
    total NUMERIC(10, 2) -- nuevo
) AS $$
BEGIN
    RETURN QUERY
        SELECT
            o.*,
            c.companyname AS cliente,
            CONCAT(e.lastname, ', ', e.firstname) AS empleado,
            total_orden(o.orderid)
        FROM orders o
            JOIN customers c USING(customerid)
            JOIN employees e USING(employeeid);
END;
$$ LANGUAGE PLPGSQL;

-- Prueba
SELECT * FROM ordenes();


-- G) Crear una función que muestre, por cada mes del año ingresado por
-- parámetro, la cantidad de órdenes generada, junto a la cantidad de órdenes
-- acumuladas hasta ese mes (inclusive).

CREATE OR REPLACE FUNCTION ordenes_por_mes(pi_anio VARCHAR(4))
RETURNS TABLE (
    mes TEXT,
    ord_gen BIGINT, -- tipo que devuelve COUNT()
    ord_ac BIGINT
) AS $$
BEGIN
    ord_ac := 0;
    FOR mes, ord_gen IN
        SELECT
            TO_CHAR(orderdate, 'TMMonth'),
            COUNT(orderid)
        FROM orders
        WHERE TO_CHAR(orderdate, 'YYYY') = pi_anio
        GROUP BY
            DATE_PART('month', orderdate),
            TO_CHAR(orderdate, 'TMMonth')
        ORDER BY DATE_PART('month', orderdate)
    LOOP
        ord_ac := ord_ac + ord_gen;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

-- Prueba
SELECT * FROM ordenes_por_mes('1997');

-- H) Crear una función que permita generar las órdenes de compra necesarias
-- para todos los productos que se encuentran por debajo del nivel de stock,
-- para esto deberá crear una tabla de órdenes de compra y su correspondiente
-- tabla de detalles.

CREATE TABLE supplier_orders (
    orderid SERIAL PRIMARY KEY,
    orderdate DATE NOT NULL,
    supplierid INTEGER NOT NULL REFERENCES suppliers
);

CREATE TABLE supplier_orderdetails (
    orderid INTEGER NOT NULL REFERENCES supplier_orders,
    productid INTEGER NOT NULL REFERENCES products,
    quantity INTEGER,
    PRIMARY KEY (orderid, productid)
);

-- Se interpreta 'unitsonorder' como la cantidad que fue pedida a proveedores
-- pero todavía no "llegó" y que en algún momento será sumado a 'unitsinstock'.

-- Otras interpretaciones:
-- - Cantidad que debe pedirse al reabastecer? No tiene sentido porque en muchos
--   casos es 0.
-- - Unidades en camino al cliente?

CREATE OR REPLACE FUNCTION generar_ordenes_compra()
RETURNS VOID AS $$
DECLARE
    lr_fila RECORD;
    li_id_prev INTEGER := 0;
    li_orderid INTEGER;
BEGIN
    FOR lr_fila IN
        SELECT productid, supplierid, reorderlevel
        FROM products
        WHERE
            NOT discontinued
            AND reorderlevel > 0 -- ¿0 quiere decir "no reabastecer"?
            -- Condición para reabastecer:
            AND (unitsinstock + unitsonorder) <= reorderlevel
        ORDER BY supplierid
    LOOP
        -- ¿Qué pasa con las órdenes repetidas?
        IF li_id_prev != lr_fila.supplierid THEN
            -- Nueva orden
            li_id_prev := lr_fila.supplierid;
            INSERT INTO supplier_orders (orderdate, supplierid)
            VALUES (CURRENT_DATE, lr_fila.supplierid)
            RETURNING orderid INTO li_orderid;
        END IF;
        -- Nuevo detalle
        INSERT INTO supplier_orderdetails
        -- ¿Cuántas unidades pedir?
        VALUES (li_orderid, lr_fila.productid, lr_fila.reorderlevel);
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

-- Prueba
SELECT generar_ordenes_compra();

-- ALTER SEQUENCE supplier_orders_orderid_seq
-- RESTART WITH 1;

-- I) Crear una función que calcule y despliegue por cada país destino de
-- ordenes (orders.shipcountry) y por un rango de tiempo ingresado por
-- parámetros la cantidad de productos diferentes que se vendieron y la cantidad
-- de clientes diferentes. Ejemplo de salida:
-- shipcountry productos clientes
-- Argentina   20        5
-- Austria     45        12
-- Belgium     9         2
-- ...         ...       ...
-- Los valores son solo ejemplos.

CREATE OR REPLACE FUNCTION ventas_por_pais(pd_desde DATE, pd_hasta DATE)
RETURNS TABLE (
    shipcountry VARCHAR(15),
    productos BIGINT,
    clientes BIGINT
) AS $$
BEGIN
    RETURN QUERY
        SELECT
            o.shipcountry,
            COUNT(DISTINCT p.productid) AS productos,
            COUNT(DISTINCT o.customerid) AS clientes
        FROM orders o
            JOIN orderdetails od USING(orderid)
            JOIN products p USING(productid)
        WHERE o.orderdate BETWEEN pd_desde AND pd_hasta
        GROUP BY o.shipcountry;
END;
$$ LANGUAGE PLPGSQL;

-- Prueba
SELECT * FROM ventas_por_pais('1997-01-01', '1997-12-31');

-- J) Inventar una única función que combine RETURN QUERY, recorrido de
-- resultados de SELECT y RETURN NEXT. Indicar, además del código, qué se espera
-- que devuelva la función inventada.

CREATE OR REPLACE FUNCTION return_query_next()
RETURNS TABLE(
    nombre VARCHAR(40),
    telefono VARCHAR(24),
    pais VARCHAR(15),
    rol TEXT
) AS $$
BEGIN
    RETURN QUERY
        SELECT companyname nombre, phone telefono, country pais, 'Cliente' rol
        FROM customers;
    RETURN QUERY
        SELECT companyname nombre, phone telefono, country pais, 'Proveedor' rol
        FROM suppliers;
    FOR nombre, telefono, rol IN
        SELECT companyname, phone, 'Transporte'
        FROM shippers
    LOOP
        -- Como 'shippers' no tiene 'country', se infiere a partir del teléfono.
        CASE
            WHEN telefono ILIKE '(50%' THEN
                pais := 'USA';
            WHEN telefono ILIKE '(17%' THEN
                pais := 'UK';
            -- ...
            ELSE
                pais := NULL;
        END CASE;
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE PLPGSQL;

-- La función devuelve una tabla con los nombres de todas las compañias de la
-- base de datos, su teléfono, su país y su rol (cliente, proveedor, transporte)
SELECT * FROM return_query_next();

