CREATE OR REPLACE FUNCTION new_order_transaction(
p_w_id integer,
p_d_id integer,
p_c_id integer,
p_ol_supply_w_id integer[],
p_ol_i_id integer[],
p_ol_quantity integer[]
)
RETURNS TABLE(
w_tax decimal(4,4),
d_tax decimal(4,4),
o_id integer,
o_entry_d timestamp,
ol_cnt integer,
ol_amounts numeric(12,2)[],
total_amount numeric(12,2),
c_last varchar(16),
c_credit char(2),
c_discount decimal(4,4),
i_names varchar(24)[],
i_prices decimal(5,2)[],
s_quantities integer[],
brand_generic char[]
) LANGUAGE plpgsql AS
$$
DECLARE
v_ol_cnt integer;
v_now timestamp := clock_timestamp();
v_rolled_back boolean := false;

-- temporary vars used inside transaction block
v_w_tax decimal(4,4);
v_d_tax decimal(4,4);
v_o_id integer;
v_c_discount decimal(4,4);
v_c_last varchar(16);
v_c_credit char(2);
v_o_all_local integer;
v_line_no integer := 0;
v_sum_ol_amount numeric(12,2) := 0;

-- per-line temps
v_i_price decimal(5,2);
v_i_name varchar(24);
v_i_data varchar(50);
v_s_quantity integer;
v_s_data varchar(50);
v_s_dist_info char(24);
v_new_s_quantity integer;
v_orig_s_quantity integer;
v_ol_amount numeric(12,2);
v_supply_w_id integer;
v_i_id integer;
v_quantity integer;
v_dist_col text;
BEGIN
-- determine ol_cnt from supplied arrays
IF p_ol_i_id IS NULL OR p_ol_supply_w_id IS NULL OR p_ol_quantity IS NULL THEN
RAISE EXCEPTION 'Item arrays must not be null';
END IF;
v_ol_cnt := array_length(p_ol_i_id, 1);
IF v_ol_cnt IS DISTINCT FROM array_length(p_ol_supply_w_id, 1)
OR v_ol_cnt IS DISTINCT FROM array_length(p_ol_quantity, 1) THEN
RAISE EXCEPTION 'Input arrays must have same length';
END IF;

-- initialize return arrays
i_names := ARRAY[]::varchar(24)[];
i_prices := ARRAY[]::decimal(5,2)[];
s_quantities := ARRAY[]::integer[];
ol_amounts := ARRAY[]::numeric(12,2)[];
brand_generic := ARRAY[]::char[];

-- perform the entire TPC-C New-Order work inside a subtransaction block so we can rollback it
-- while still returning the assigned O_ID when an unused item causes rollback.
BEGIN
-- read warehouse tax
SELECT w.w_tax
INTO v_w_tax
FROM bmsql_warehouse w
WHERE w.w_id = p_w_id;
IF NOT FOUND THEN
RAISE EXCEPTION 'Warehouse % not found', p_w_id;
END IF;


-- read district tax and next_o_id, then increment next_o_id
SELECT d.d_tax, d.d_next_o_id
  INTO v_d_tax, v_o_id
FROM bmsql_district d
WHERE d.d_w_id = p_w_id AND d.d_id = p_d_id
FOR UPDATE;
IF NOT FOUND THEN
  RAISE EXCEPTION 'District % of warehouse % not found', p_d_id, p_w_id;
END IF;

UPDATE bmsql_district
  SET d_next_o_id = d_next_o_id + 1,
      d_ytd = d_ytd -- keep unchanged except next_o_id
WHERE d_w_id = p_w_id AND d_id = p_d_id;

-- read customer data
SELECT c.c_discount, c.c_last, c.c_credit
  INTO v_c_discount, v_c_last, v_c_credit
FROM bmsql_customer c
WHERE c.c_w_id = p_w_id AND c.c_d_id = p_d_id AND c.c_id = p_c_id
FOR SHARE;
IF NOT FOUND THEN
  RAISE EXCEPTION 'Customer %/%/% not found', p_w_id, p_d_id, p_c_id;
END IF;

-- compute o_all_local: assume true until remote found
v_o_all_local := 1;
FOR v_line_no IN 1..v_ol_cnt LOOP
  IF p_ol_supply_w_id[v_line_no] IS DISTINCT FROM p_w_id THEN
    v_o_all_local := 0;
    EXIT;
  END IF;
END LOOP;

-- insert into ORDER table (bmsql_oorder)
INSERT INTO bmsql_oorder(o_w_id,o_d_id,o_id,o_c_id,o_carrier_id,o_ol_cnt,o_all_local,o_entry_d)
VALUES (p_w_id, p_d_id, v_o_id, p_c_id, NULL, v_ol_cnt, v_o_all_local, v_now);

-- insert into NEW-ORDER table
INSERT INTO bmsql_new_order(no_w_id,no_d_id,no_o_id)
VALUES (p_w_id, p_d_id, v_o_id);

-- process each order-line
v_line_no := 0;
FOR v_line_no IN 1..v_ol_cnt LOOP
  v_supply_w_id := p_ol_supply_w_id[v_line_no];
  v_i_id := p_ol_i_id[v_line_no];
  v_quantity := p_ol_quantity[v_line_no];

  -- select item: if not found, MUST rollback entire transaction (per spec)
  SELECT i.i_price, i.i_name, i.i_data
    INTO v_i_price, v_i_name, v_i_data
  FROM bmsql_item i
  WHERE i.i_id = v_i_id;
  IF NOT FOUND THEN
    -- signal not-found to cause subtransaction rollback
    RAISE EXCEPTION 'ITEM_NOT_FOUND';
  END IF;

  -- select stock row for supply warehouse and item
  SELECT s.s_quantity, s.s_data,
         CASE WHEN p_d_id = 1 THEN s.s_dist_01
              WHEN p_d_id = 2 THEN s.s_dist_02
              WHEN p_d_id = 3 THEN s.s_dist_03
              WHEN p_d_id = 4 THEN s.s_dist_04
              WHEN p_d_id = 5 THEN s.s_dist_05
              WHEN p_d_id = 6 THEN s.s_dist_06
              WHEN p_d_id = 7 THEN s.s_dist_07
              WHEN p_d_id = 8 THEN s.s_dist_08
              WHEN p_d_id = 9 THEN s.s_dist_09
              WHEN p_d_id = 10 THEN s.s_dist_10
              ELSE s.s_dist_01 END
    INTO v_s_quantity, v_s_data, v_s_dist_info
  FROM bmsql_stock s
  WHERE s.s_w_id = v_supply_w_id AND s.s_i_id = v_i_id
  FOR UPDATE;
  IF NOT FOUND THEN
    -- per spec, if stock row missing treat as error (but typical TPC-C assume stock exists)
    RAISE EXCEPTION 'STOCK_NOT_FOUND';
  END IF;

  v_orig_s_quantity := v_s_quantity;

  -- compute new stock quantity per rules
  IF v_s_quantity > v_quantity + 10 THEN
    v_new_s_quantity := v_s_quantity - v_quantity;
  ELSE
    v_new_s_quantity := (v_s_quantity - v_quantity) + 91;
  END IF;

  -- update stock counters
  UPDATE bmsql_stock
    SET s_quantity = v_new_s_quantity,
        s_ytd = s_ytd + v_quantity,
        s_order_cnt = s_order_cnt + 1,
        s_remote_cnt = s_remote_cnt + (CASE WHEN v_supply_w_id <> p_w_id THEN 1 ELSE 0 END)
  WHERE s_w_id = v_supply_w_id AND s_i_id = v_i_id;

  -- compute ol_amount
  v_ol_amount := v_quantity * v_i_price;
  v_sum_ol_amount := v_sum_ol_amount + v_ol_amount;

  -- determine brand/generic
  IF position('ORIGINAL' in coalesce(v_i_data,'')) > 0 AND position('ORIGINAL' in coalesce(v_s_data,'')) > 0 THEN
    brand_generic := array_append(brand_generic, 'B'::char);
  ELSE
    brand_generic := array_append(brand_generic, 'G'::char);
  END IF;

  -- append arrays of outputs (I_NAME,I_PRICE,S_QUANTITY before update, OL_AMOUNT)
  i_names := array_append(i_names, left(v_i_name,24));
  i_prices := array_append(i_prices, v_i_price);
  s_quantities := array_append(s_quantities, v_orig_s_quantity);
  ol_amounts := array_append(ol_amounts, round(v_ol_amount::numeric,2));

  -- insert into order_line
  INSERT INTO bmsql_order_line(
    ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d, ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info
  ) VALUES (
    p_w_id, p_d_id, v_o_id, v_line_no, v_i_id, NULL, round(v_ol_amount::numeric,2), v_supply_w_id, v_quantity, v_s_dist_info
  );
END LOOP; -- each order-line

-- compute total amount
total_amount := round( (v_sum_ol_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax))::numeric, 2 );

-- set outputs for warehouse/district/customer and order
w_tax := v_w_tax;
d_tax := v_d_tax;
o_id := v_o_id;
o_entry_d := v_now;
ol_cnt := v_ol_cnt;
c_last := v_c_last;
c_credit := v_c_credit;
c_discount := v_c_discount;

-- normal completion of subtransaction


EXCEPTION WHEN OTHERS THEN
-- subtransaction will be rolled back automatically; capture if it's the item-not-found case
IF SQLSTATE = 'P0001' OR SQLERRM LIKE '%ITEM_NOT_FOUND%' THEN
v_rolled_back := true;
-- ensure we still return the assigned O_ID (v_o_id may have been set before error)
o_id := v_o_id;
o_entry_d := v_now;
w_tax := v_w_tax;
d_tax := v_d_tax;
c_last := v_c_last;
c_credit := v_c_credit;
c_discount := v_c_discount;
ol_cnt := v_ol_cnt;
-- clear arrays as per rollback (no order-line info should be returned)
i_names := ARRAY[]::varchar(24)[];
i_prices := ARRAY[]::decimal(5,2)[];
s_quantities := ARRAY[]::integer[];
ol_amounts := ARRAY[]::numeric(12,2)[];
brand_generic := ARRAY[]::char[];
total_amount := NULL;
-- swallow the exception to allow outer function to return values
ELSE
-- unexpected error: re-raise
RAISE;
END IF;
END;

-- return a single row with outputs
RETURN QUERY SELECT
w_tax,
d_tax,
o_id,
o_entry_d,
ol_cnt,
ol_amounts,
total_amount,
c_last,
c_credit,
c_discount,
i_names,
i_prices,
s_quantities,
brand_generic;

END;
$$;
