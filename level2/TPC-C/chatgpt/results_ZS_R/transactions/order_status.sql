CREATE OR REPLACE FUNCTION bmsql_order_status(
p_w_id   integer,
p_d_id   integer,
p_c_id   integer DEFAULT NULL,
p_c_last varchar(16) DEFAULT NULL
)
RETURNS TABLE(
c_id integer,
c_first varchar(16),
c_middle char(2),
c_balance numeric(12,2),
o_id integer,
o_entry_d timestamp,
o_carrier_id integer,
ol_supply_w_id integer[],
ol_i_id integer[],
ol_quantity integer[],
ol_amount numeric[],
ol_delivery_d timestamp[]
)
LANGUAGE plpgsql
AS $$
DECLARE
v_c_count integer;
v_pos integer;
v_idx integer := 0;
v_ol_supply integer[] := array_fill(0, ARRAY[15]);
v_ol_i integer[] := array_fill(0, ARRAY[15]);
v_ol_qty integer[] := array_fill(0, ARRAY[15]);
v_ol_amt numeric[] := array_fill(0.0::numeric, ARRAY[15]);
v_ol_del timestamp[] := array_fill(NULL::timestamp, ARRAY[15]);
rec_order_line RECORD;
BEGIN
-- initialize outputs to null/defaults
c_id := NULL;
c_first := NULL;
c_middle := NULL;
c_balance := NULL;
o_id := NULL;
o_entry_d := NULL;
o_carrier_id := NULL;
ol_supply_w_id := v_ol_supply;
ol_i_id := v_ol_i;
ol_quantity := v_ol_qty;
ol_amount := v_ol_amt;
ol_delivery_d := v_ol_del;

-- 1) Find customer by number or by last name (choose median by first name)
IF p_c_id IS NOT NULL THEN
-- Case 1: selected by customer number
SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
INTO c_id, c_first, c_middle, c_balance
FROM bmsql_customer c
WHERE c.c_w_id = p_w_id
AND c.c_d_id = p_d_id
AND c.c_id = p_c_id;
ELSE
-- Case 2: selected by last name: find count and pick middle one ordered by c_first asc
SELECT count(*) INTO v_c_count
FROM bmsql_customer c
WHERE c.c_w_id = p_w_id
AND c.c_d_id = p_d_id
AND c.c_last = p_c_last;


IF v_c_count > 0 THEN
  v_pos := (v_c_count + 1) / 2; -- integer division yields ceil for positive ints in PG when using integer math? ensure integer
  -- Use OFFSET (v_pos-1)
  EXECUTE format(
    'SELECT c.c_id, c.c_first, c.c_middle, c.c_balance FROM bmsql_customer c WHERE c.c_w_id = $1 AND c.c_d_id = $2 AND c.c_last = $3 ORDER BY c.c_first ASC LIMIT 1 OFFSET %s',
    v_pos - 1
  )
  INTO c_id, c_first, c_middle, c_balance
  USING p_w_id, p_d_id, p_c_last;
ELSE
  -- customer not found by last name: leave customer fields null
  c_id := NULL;
END IF;


END IF;

-- If no customer found, return a single row with defaults (as per terminal behavior)
IF c_id IS NULL THEN
RETURN QUERY SELECT c_id, c_first, c_middle, c_balance, o_id, o_entry_d, o_carrier_id, ol_supply_w_id, ol_i_id, ol_quantity, ol_amount, ol_delivery_d;
RETURN;
END IF;

-- 2) Find the most recent order for that customer
SELECT o.o_id, o.o_entry_d, o.o_carrier_id
INTO o_id, o_entry_d, o_carrier_id
FROM bmsql_oorder o
WHERE o.o_w_id = p_w_id
AND o.o_d_id = p_d_id
AND o.o_c_id = c_id
ORDER BY o.o_id DESC
LIMIT 1;

-- If no order found, return customer info and empty/padded order-line arrays
IF o_id IS NULL THEN
RETURN QUERY SELECT c_id, c_first, c_middle, c_balance, o_id, o_entry_d, o_carrier_id, ol_supply_w_id, ol_i_id, ol_quantity, ol_amount, ol_delivery_d;
RETURN;
END IF;

-- 3) Retrieve all order-line rows for that order and populate arrays (up to 15 entries; pad remaining)
v_idx := 0;
FOR rec_order_line IN
SELECT ol.ol_supply_w_id, ol.ol_i_id, ol.ol_quantity, ol.ol_amount, ol.ol_delivery_d
FROM bmsql_order_line ol
WHERE ol.ol_w_id = o_id::integer * 0 + p_w_id  -- trick to ensure use of p_w_id variable and qualify
AND ol.ol_d_id = p_d_id
AND ol.ol_o_id = o_id
ORDER BY ol.ol_number ASC
LOOP
v_idx := v_idx + 1;
EXIT WHEN v_idx > 15;
v_ol_supply[v_idx] := rec_order_line.ol_supply_w_id;
v_ol_i[v_idx] := rec_order_line.ol_i_id;
v_ol_qty[v_idx] := rec_order_line.ol_quantity;
v_ol_amt[v_idx] := rec_order_line.ol_amount;
v_ol_del[v_idx] := rec_order_line.ol_delivery_d;
END LOOP;

-- assign arrays to output vars
ol_supply_w_id := v_ol_supply;
ol_i_id := v_ol_i;
ol_quantity := v_ol_qty;
ol_amount := v_ol_amt;
ol_delivery_d := v_ol_del;

-- return the single-row result
RETURN QUERY SELECT c_id, c_first, c_middle, c_balance, o_id, o_entry_d, o_carrier_id, ol_supply_w_id, ol_i_id, ol_quantity, ol_amount, ol_delivery_d;
END;
$$;
