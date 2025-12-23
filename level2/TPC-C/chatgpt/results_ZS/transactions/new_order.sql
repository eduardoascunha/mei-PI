CREATE OR REPLACE FUNCTION bmsql_new_order_txn(
in_w_id integer,
in_d_id integer,
in_c_id integer,
in_ol_supply_w_id integer[],
in_ol_i_id integer[],
in_ol_quantity integer[]
)
RETURNS TABLE(
w_tax numeric(4,4),
d_tax numeric(4,4),
o_id integer,
o_entry_d timestamp,
ol_cnt integer,
ol_amounts numeric[],
total_amount numeric(12,2),
c_last varchar,
c_credit char(2),
c_discount numeric(4,4),
i_names varchar[],
i_prices numeric[],
s_quantities integer[],
brand_generic_arr char[]
)
LANGUAGE plpgsql
AS
$$
DECLARE
v_ol_cnt integer;
v_w_tax numeric(4,4);
v_d_tax numeric(4,4);
v_c_discount numeric(4,4);
v_c_last varchar(16);
v_c_credit char(2);
v_o_id integer;
v_o_entry_d timestamp := clock_timestamp();
v_all_local boolean := true;
idx integer;
v_i_price numeric(5,2);
v_i_name varchar(24);
v_i_data varchar(50);
v_s_quantity integer;
v_s_ytd integer;
v_s_order_cnt integer;
v_s_remote_cnt integer;
v_s_data varchar(50);
v_dist_info varchar(24);
v_ol_amount numeric(12,2);
v_sum_ol_amount numeric(12,2) := 0;
v_supply_w_id integer;
v_quantity integer;
v_brand char(1);
v_dist_field_name text;
v_tmp_text text;
v_item_found boolean;
-- arrays to build results
arr_ol_amounts numeric[] := '{}';
arr_i_names varchar[] := '{}';
arr_i_prices numeric[] := '{}';
arr_s_quantities integer[] := '{}';
arr_brand_generic char[] := '{}';
BEGIN
-- Validate array lengths
IF array_length(in_ol_i_id,1) IS NULL OR array_length(in_ol_i_id,1) <> array_length(in_ol_quantity,1) OR array_length(in_ol_i_id,1) <> array_length(in_ol_supply_w_id,1) THEN
RAISE EXCEPTION 'Input arrays must be non-null and of equal length';
END IF;

v_ol_cnt := array_length(in_ol_i_id,1);
ol_cnt := v_ol_cnt; -- set output variable

-- Read warehouse tax
SELECT w.w_tax INTO v_w_tax
FROM bmsql_warehouse w
WHERE w.w_id = in_w_id
FOR SHARE;
IF NOT FOUND THEN
RAISE EXCEPTION 'Warehouse % not found', in_w_id;
END IF;

-- Lock and get district next order id and tax
SELECT d.d_tax, d.d_next_o_id INTO v_d_tax, v_o_id
FROM bmsql_district d
WHERE d.d_w_id = in_w_id AND d.d_id = in_d_id
FOR UPDATE;
IF NOT FOUND THEN
RAISE EXCEPTION 'District %/% not found', in_w_id, in_d_id;
END IF;

-- increment district next order id (this update will be part of the main subtransaction)
UPDATE bmsql_district
SET d_next_o_id = d_next_o_id + 1
WHERE d_w_id = in_w_id AND d_id = in_d_id;

-- Read customer
SELECT c.c_discount, c.c_last, c.c_credit INTO v_c_discount, v_c_last, v_c_credit
FROM bmsql_customer c
WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id
FOR SHARE;
IF NOT FOUND THEN
RAISE EXCEPTION 'Customer %/%/% not found', in_w_id, in_d_id, in_c_id;
END IF;

-- Prepare O_ORDER insert (o_entry_d is set to current time)
v_o_entry_d := clock_timestamp();

-- Determine o_all_local by checking if any supply warehouse differs from home
FOR idx IN 1..v_ol_cnt LOOP
IF in_ol_supply_w_id[idx] IS NULL OR in_ol_supply_w_id[idx] <> in_w_id THEN
v_all_local := false;
EXIT;
END IF;
END LOOP;

-- Insert into ORDER table (bmsql_oorder)
INSERT INTO bmsql_oorder(o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d)
VALUES (in_w_id, in_d_id, v_o_id, in_c_id, NULL, v_ol_cnt, CASE WHEN v_all_local THEN 1 ELSE 0 END, v_o_entry_d);

-- Insert into NEW-ORDER table
INSERT INTO bmsql_new_order(no_w_id, no_d_id, no_o_id)
VALUES (in_w_id, in_d_id, v_o_id);

-- Process each order-line
FOR idx IN 1..v_ol_cnt LOOP
v_supply_w_id := in_ol_supply_w_id[idx];
v_quantity := in_ol_quantity[idx];


-- Select item; if not found and it's the last item then we must rollback the transaction
SELECT i.i_price, i.i_name, i.i_data INTO v_i_price, v_i_name, v_i_data
FROM bmsql_item i
WHERE i.i_id = in_ol_i_id[idx];

IF NOT FOUND THEN
  -- The TPC-C specifies that if the last item is unused, the transaction must be rolled back.
  -- We RAISE an exception which will abort the current transaction (and we will catch it outside if needed).
  RAISE EXCEPTION 'Item number is not valid: % (index %)', in_ol_i_id[idx], idx;
END IF;

-- Read stock row for this item and supply warehouse
SELECT s.s_quantity, s.s_ytd, s.s_order_cnt, s.s_remote_cnt, s.s_data,
  s.s_dist_01, s.s_dist_02, s.s_dist_03, s.s_dist_04, s.s_dist_05,
  s.s_dist_06, s.s_dist_07, s.s_dist_08, s.s_dist_09, s.s_dist_10
INTO v_s_quantity, v_s_ytd, v_s_order_cnt, v_s_remote_cnt, v_s_data,
     -- dist fields are selected into the following temp variables via a text roundabout below
     v_tmp_text, v_tmp_text, v_tmp_text, v_tmp_text, v_tmp_text,
     v_tmp_text, v_tmp_text, v_tmp_text, v_tmp_text, v_tmp_text
FROM bmsql_stock s
WHERE s.s_w_id = v_supply_w_id AND s.s_i_id = in_ol_i_id[idx]
FOR UPDATE;

IF NOT FOUND THEN
  RAISE EXCEPTION 'Stock not found for warehouse % item %', v_supply_w_id, in_ol_i_id[idx];
END IF;

-- Determine district-specific dist info (choose correct s_dist_xx column)
CASE in_d_id
  WHEN 1 THEN SELECT s_dist_01 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 2 THEN SELECT s_dist_02 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 3 THEN SELECT s_dist_03 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 4 THEN SELECT s_dist_04 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 5 THEN SELECT s_dist_05 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 6 THEN SELECT s_dist_06 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 7 THEN SELECT s_dist_07 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 8 THEN SELECT s_dist_08 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 9 THEN SELECT s_dist_09 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  WHEN 10 THEN SELECT s_dist_10 FROM bmsql_stock WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx] INTO v_dist_info;
  ELSE v_dist_info := NULL;
END CASE;

-- Save original stock quantity to output array
arr_s_quantities := arr_s_quantities || v_s_quantity;

-- Compute new stock quantity per rules
IF v_s_quantity > v_quantity + 10 THEN
  v_s_quantity := v_s_quantity - v_quantity;
ELSE
  v_s_quantity := (v_s_quantity - v_quantity) + 91;
END IF;

-- Update stock totals
v_s_ytd := v_s_ytd + v_quantity;
v_s_order_cnt := v_s_order_cnt + 1;
IF v_supply_w_id <> in_w_id THEN
  v_s_remote_cnt := v_s_remote_cnt + 1;
END IF;

UPDATE bmsql_stock
SET s_quantity = v_s_quantity,
    s_ytd = v_s_ytd,
    s_order_cnt = v_s_order_cnt,
    s_remote_cnt = v_s_remote_cnt,
    s_data = v_s_data
WHERE s_w_id = v_supply_w_id AND s_i_id = in_ol_i_id[idx];

-- Compute OL_AMOUNT
v_ol_amount := (v_quantity * v_i_price);
v_sum_ol_amount := v_sum_ol_amount + v_ol_amount;

-- Determine brand or generic
IF position('ORIGINAL' in upper(v_i_data)) > 0 AND position('ORIGINAL' in upper(v_s_data)) > 0 THEN
  v_brand := 'B';
ELSE
  v_brand := 'G';
END IF;

-- Insert order-line
INSERT INTO bmsql_order_line(ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info)
VALUES (in_w_id, in_d_id, v_o_id, idx, in_ol_i_id[idx], NULL, v_ol_amount, v_supply_w_id, v_quantity, v_dist_info);

-- Append to result arrays
arr_ol_amounts := arr_ol_amounts || v_ol_amount;
arr_i_names := arr_i_names || v_i_name;
arr_i_prices := arr_i_prices || v_i_price;
arr_brand_generic := arr_brand_generic || v_brand;


END LOOP;

-- Compute total amount
v_sum_ol_amount := COALESCE(v_sum_ol_amount,0);
total_amount := round( v_sum_ol_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax )::numeric , 2);

-- Prepare outputs
w_tax := v_w_tax;
d_tax := v_d_tax;
o_id := v_o_id;
o_entry_d := v_o_entry_d;
ol_amounts := arr_ol_amounts;
c_last := v_c_last;
c_credit := v_c_credit;
c_discount := v_c_discount;
i_names := arr_i_names;
i_prices := arr_i_prices;
s_quantities := arr_s_quantities;
brand_generic_arr := arr_brand_generic;

RETURN NEXT;

EXCEPTION
WHEN SQLSTATE 'P0001' OR SQLSTATE 'XX000' OR OTHERS THEN
-- If an 'Item number is not valid' exception was raised, we must roll back the changes and return partial info:
-- Because this exception is propagated, the whole function call will abort unless we handle it here.
-- Build minimal outputs if possible. We attempt to return computed customer info and o_id if available.
-- Note: changes made before the exception are rolled back automatically by the plpgsql subtransaction semantics.
IF SQLERRM LIKE 'Item number is not valid:%' THEN
-- Return only the required fields for rollback case as best-effort: W_ID, D_ID, C_ID, C_LAST, C_CREDIT, O_ID
w_tax := v_w_tax;
d_tax := v_d_tax;
o_id := v_o_id;
o_entry_d := v_o_entry_d;
ol_cnt := v_ol_cnt;
ol_amounts := arr_ol_amounts;
total_amount := NULL;
c_last := v_c_last;
c_credit := v_c_credit;
c_discount := v_c_discount;
i_names := arr_i_names;
i_prices := arr_i_prices;
s_quantities := arr_s_quantities;
brand_generic_arr := arr_brand_generic;
RETURN NEXT;
ELSE
-- Re-raise unknown exceptions
RAISE;
END IF;
END;
$$;
