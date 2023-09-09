create or replace function get_order_details_in_time_interval(
    pv_start_date date,
    pv_end_date date
)
returns table (
    companyname varchar(40),
    orderdate date,
    productid int,
    productname varchar(40),
    quantity int,
    unitprice numeric(10,2),
    subtotal numeric(10,2)
)
as 
$$
begin
    return query
    select
        c.companyname,
        o.orderdate,
        od.productid,
        p.productname,
        od.quantity,
        od.unitprice,
        (od.quantity * od.unitprice - od.discount) as subtotal
    from 
    	customers c
    	inner join orders o  using(customerid) 
    	inner join orderdetails od using(orderid) 
    	inner join products p using(productid)
    where 
        o.orderdate between pv_start_date and pv_end_date;
end;
$$
language plpgsql;

create or replace function get_order_details(pv_orderid int)
returns text
as $$
declare
    order_info text := '';
    product_row RECORD;
begin
    for product_row in (
        select p.productid, p.productname, od.unitprice, od.quantity
        from orderdetails od inner join products p using(productid)
        where od.orderid = pv_orderid
    ) loop
        order_info := order_info || product_row.productid || ' - ' || product_row.productname||
                      ' - ' || product_row.unitprice || ' - ' || product_row.quantity || ',';
    end loop;
    return order_info;
end;
$$ language plpgsql;

create or replace function delete_trim(pv_table_name varchar, pv_column_name varchar)
returns int as 
$$
declare contador integer := 0;
begin 
	execute 'update ' || pv_table_name || ' set ' || pv_column_name || ' = trim(' || pv_column_name || ') where not ' || pv_column_name || ' = trim(' || pv_column_name || ');';
	get diagnostics contador := ROW_COUNT;
	return contador;
end
$$
language plpgsql;
