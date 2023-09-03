CREATE OR REPLACE FUNCTION fn_productos(pv_producto VARCHAR)
RETURNS TABLE(ti_prod_id int, tv_title VARCHAR) AS
$$
BEGIN
	RETURN QUERY SELECT prod_id, title
	FROM products
	WHERE title ILIKE '%A%';
	-- preparación de variables a devolver
	ti_prod_id:=0;
	tv_title:='Producto no listado';
	RETURN NEXT;
END;
$$
LANGUAGE PLPGSQL;

select * from fn_productos('A') order by 2;

------

CREATE OR REPLACE FUNCTION fn_productos(pi_cat1 int, pi_cat2) 
RETURNS TABLE(
	ti_prod_id int,
	tv_title varchar,
	tn_price numeric(12,2)
	) as
$$
BEGIN
	SELECT prod_id, title, price
	INTO ti_prod_id, tv_title, tn_price
	FROM products
	WHERE category = pi_cat1;
	RETURN NEXT;
	SELECT prod_id, title, price
	INTO ti_prod_id, tv_title, tn_price
	FROM products
	WHERE category = pi_cat2;
	RETURN NEXT;
	RETURN;
END;
$$ 
LANGUAGE 'plpgsql';

select * from fn_ordenes('1980-01-01')
