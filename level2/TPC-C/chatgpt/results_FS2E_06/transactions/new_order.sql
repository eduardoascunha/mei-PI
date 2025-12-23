CREATE OR REPLACE FUNCTION bmsql_proc_new_order(
IN in_w_id integer,
IN in_d_id integer,
IN in_c_id integer,
IN in_ol_supply_w_id integer[],
IN in_ol_i_id integer[],
IN in_ol_quantity integer[],
OUT out_w_tax decimal(4,4),
OUT out_d_tax decimal(4,4),
OUT out_o_id integer,
OUT out_o_entry_d timestamp,
OUT out_ol_cnt integer,
OUT out_ol_amount decimal(12,2)[],
OUT out_total_amount decimal(12,2),
OUT out_c_last varchar(16),
OUT out_c_credit char(2),
OUT out_c_discount decimal(4,4),
OUT out_i_name varchar(24)[],
OUT out_i_price decimal(5,2)[],
OUT out_s_quantity integer[],
OUT out_brand_generic char[]
) AS
$$
DECLARE
v_w_record RECORD;
v_d_record RECORD;
v_c_record RECORD;
v_ol_idx integer;
v_item_price decimal(5,2);
v_item_name varchar(24);
v_item_data varchar(50);
v_stock RECORD;
v_s_dist_info char(24);
v_ol_amount decimal(12,2);
v_sum_ol_amount numeric := 0;
v_all_local integer := 1;
v_ol_cnt integer;
v_s_quantity_before integer;
BEGIN
-- Input validation: array lengths must match
IF in_ol_i_id IS NULL OR in_ol_supply_w_id IS NULL OR in_ol_quantity IS NULL THEN
RAISE EXCEPTION 'Item arrays must not be null';
END IF;
IF array_length(in_ol_i_id,1) IS NULL THEN
RAISE EXCEPTION 'Item array must have at least one element';
END IF;
v_ol_cnt := array_length(in_ol_i_id,1);
IF v_ol_cnt <> array_length(in_ol_supply_w_id,1) OR v_ol_cnt <> array_length(in_ol_quantity,1) THEN
RAISE EXCEPTION 'Input arrays lengths do not match';
END IF;
out_ol_cnt := v_ol_cnt;


-- 1) Get warehouse tax
SELECT w.w_tax INTO v_w_record
FROM bmsql_warehouse AS w
WHERE w.w_id = in_w_id;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Warehouse % not found', in_w_id;
END IF;
out_w_tax := v_w_record.w_tax;

-- 2) Get district tax and next_o_id (lock row and increment)
SELECT d.d_next_o_id, d.d_tax INTO v_d_record
FROM bmsql_district AS d
WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id
FOR UPDATE;
IF NOT FOUND THEN
    RAISE EXCEPTION 'District %/% not found', in_w_id, in_d_id;
END IF;
out_d_tax := v_d_record.d_tax;

-- assign order id as current d_next_o_id and increment d_next_o_id
out_o_id := v_d_record.d_next_o_id;
UPDATE bmsql_district AS d
SET d_next_o_id = v_d_record.d_next_o_id + 1
WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id;

-- 3) Get customer info
SELECT c.c_discount, c.c_last, c.c_credit
INTO v_c_record
FROM bmsql_customer AS c
WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer %/%/% not found', in_w_id, in_d_id, in_c_id;
END IF;
out_c_discount := v_c_record.c_discount;
out_c_last := v_c_record.c_last;
out_c_credit := v_c_record.c_credit;

-- 4) Insert into ORDER (oorder) and NEW-ORDER
out_o_entry_d := clock_timestamp();

INSERT INTO bmsql_oorder (o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
VALUES (in_w_id, in_d_id, out_o_id, in_c_id, NULL, v_ol_cnt, 1, out_o_entry_d);

INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
VALUES (in_w_id, in_d_id, out_o_id);

-- Prepare output arrays
out_ol_amount := array_fill(0::decimal(12,2), ARRAY[v_ol_cnt]);
out_i_name := array_fill(''::varchar(24), ARRAY[v_ol_cnt]);
out_i_price := array_fill(0::decimal(5,2), ARRAY[v_ol_cnt]);
out_s_quantity := array_fill(0::integer, ARRAY[v_ol_cnt]);
out_brand_generic := array_fill(''::char, ARRAY[v_ol_cnt]);

-- 5) For each order-line
FOR v_ol_idx IN 1..v_ol_cnt LOOP
    -- fetch item (throws not-found -> rollback)
    SELECT i.i_price, i.i_name, i.i_data
    INTO v_item_price, v_item_name, v_item_data
    FROM bmsql_item AS i
    WHERE i.i_id = in_ol_i_id[v_ol_idx];

    IF NOT FOUND THEN
        -- Signal not found - this will cause the entire transaction to rollback.
        RAISE EXCEPTION 'Item number % is not valid; order id %', in_ol_i_id[v_ol_idx], out_o_id;
    END IF;

    -- fetch stock row FOR UPDATE
    SELECT s.s_quantity, s.s_ytd, s.s_order_cnt, s.s_remote_cnt, s.s_data,
           s.s_dist_01, s.s_dist_02, s.s_dist_03, s.s_dist_04, s.s_dist_05,
           s.s_dist_06, s.s_dist_07, s.s_dist_08, s.s_dist_09, s.s_dist_10
    INTO v_stock
    FROM bmsql_stock AS s
    WHERE s.s_w_id = in_ol_supply_w_id[v_ol_idx] AND s.s_i_id = in_ol_i_id[v_ol_idx]
    FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Stock row not found for item % at warehouse %', in_ol_i_id[v_ol_idx], in_ol_supply_w_id[v_ol_idx];
    END IF;

    -- record quantity before update for output
    v_s_quantity_before := v_stock.s_quantity;
    out_s_quantity[v_ol_idx] := v_s_quantity_before;

    -- determine dist info column based on district number
    CASE in_d_id
        WHEN 1 THEN v_s_dist_info := v_stock.s_dist_01;
        WHEN 2 THEN v_s_dist_info := v_stock.s_dist_02;
        WHEN 3 THEN v_s_dist_info := v_stock.s_dist_03;
        WHEN 4 THEN v_s_dist_info := v_stock.s_dist_04;
        WHEN 5 THEN v_s_dist_info := v_stock.s_dist_05;
        WHEN 6 THEN v_s_dist_info := v_stock.s_dist_06;
        WHEN 7 THEN v_s_dist_info := v_stock.s_dist_07;
        WHEN 8 THEN v_s_dist_info := v_stock.s_dist_08;
        WHEN 9 THEN v_s_dist_info := v_stock.s_dist_09;
        WHEN 10 THEN v_s_dist_info := v_stock.s_dist_10;
        ELSE v_s_dist_info := NULL;
    END CASE;

    -- update stock quantity per rule
    IF v_stock.s_quantity > in_ol_quantity[v_ol_idx] + 10 THEN
        v_stock.s_quantity := v_stock.s_quantity - in_ol_quantity[v_ol_idx];
    ELSE
        v_stock.s_quantity := (v_stock.s_quantity - in_ol_quantity[v_ol_idx]) + 91;
    END IF;

    -- update stock aggregates
    v_stock.s_ytd := v_stock.s_ytd + in_ol_quantity[v_ol_idx];
    v_stock.s_order_cnt := v_stock.s_order_cnt + 1;
    IF in_ol_supply_w_id[v_ol_idx] <> in_w_id THEN
        v_stock.s_remote_cnt := v_stock.s_remote_cnt + 1;
        v_all_local := 0;
    END IF;

    -- persist stock changes
    UPDATE bmsql_stock AS s
    SET s_quantity = v_stock.s_quantity,
        s_ytd = v_stock.s_ytd,
        s_order_cnt = v_stock.s_order_cnt,
        s_remote_cnt = v_stock.s_remote_cnt
    WHERE s.s_w_id = in_ol_supply_w_id[v_ol_idx] AND s.s_i_id = in_ol_i_id[v_ol_idx];

    -- compute line amount
    v_ol_amount := in_ol_quantity[v_ol_idx] * v_item_price;
    out_ol_amount[v_ol_idx] := v_ol_amount;
    v_sum_ol_amount := v_sum_ol_amount + v_ol_amount;

    -- brand/generic determination
    IF position('ORIGINAL' IN v_item_data) > 0 AND position('ORIGINAL' IN v_stock.s_data) > 0 THEN
        out_brand_generic[v_ol_idx] := 'B';
    ELSE
        out_brand_generic[v_ol_idx] := 'G';
    END IF;

    -- fill item name and price outputs
    out_i_name[v_ol_idx] := v_item_name;
    out_i_price[v_ol_idx] := v_item_price;

    -- insert order line
    INSERT INTO bmsql_order_line (ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
    VALUES (
        in_w_id,
        in_d_id,
        out_o_id,
        v_ol_idx,
        in_ol_i_id[v_ol_idx],
        NULL,
        v_ol_amount,
        in_ol_supply_w_id[v_ol_idx],
        in_ol_quantity[v_ol_idx],
        v_s_dist_info
    );
END LOOP;

-- 6) If any remote supply found, update o_all_local in oorder
IF v_all_local = 0 THEN
    UPDATE bmsql_oorder AS o
    SET o_all_local = 0
    WHERE o.o_w_id = in_w_id AND o.o_d_id = in_d_id AND o.o_id = out_o_id;
END IF;

-- 7) compute total amount
out_total_amount := (v_sum_ol_amount * (1 - out_c_discount) * (1 + out_w_tax + out_d_tax))::decimal(12,2);

-- done
RETURN;


END;
$$
LANGUAGE plpgsql;
