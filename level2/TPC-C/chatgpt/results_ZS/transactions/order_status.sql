CREATE OR REPLACE FUNCTION bmsql_order_status(
in_w_id integer,
in_d_id integer,
in_c_id integer DEFAULT NULL,
in_c_last varchar(16) DEFAULT NULL
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
selected_c_id integer;
sel_first varchar(16);
sel_middle char(2);
sel_balance numeric(12,2);

found_o_id integer;
found_o_entry timestamp;
found_o_carrier integer;

tmp_supply integer[];
tmp_i_ids integer[];
tmp_qty integer[];
tmp_amt numeric[];
tmp_del timestamp[];

ids integer[];
n integer;
idx integer;

supply_arr integer[15];
i_arr integer[15];
qty_arr integer[15];
amt_arr numeric[15];
del_arr timestamp[15];
BEGIN
-- 1) Find customer (by number or by last name)
IF in_c_id IS NOT NULL AND in_c_id > 0 THEN
SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
INTO selected_c_id, sel_first, sel_middle, sel_balance
FROM bmsql_customer c
WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = in_c_id;
ELSE
-- select all customer ids with matching last name ordered by first name,
-- choose the middle one (ceil(n/2))
SELECT array_agg(c.c_id ORDER BY c.c_first)
INTO ids
FROM bmsql_customer c
WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_last = in_c_last;


IF ids IS NOT NULL THEN
  n := array_length(ids, 1);
  idx := (n + 1) / 2; -- integer division yields ceil for odd, floor for even due to integer math; (n+1)/2 is correct for ceil
  selected_c_id := ids[idx];
  SELECT c.c_first, c.c_middle, c.c_balance
    INTO sel_first, sel_middle, sel_balance
  FROM bmsql_customer c
  WHERE c.c_w_id = in_w_id AND c.c_d_id = in_d_id AND c.c_id = selected_c_id;
ELSE
  selected_c_id := NULL;
END IF;


END IF;

-- prepare default empty arrays
supply_arr := array_fill(0, ARRAY[15]);
i_arr     := array_fill(0, ARRAY[15]);
qty_arr   := array_fill(0, ARRAY[15]);
amt_arr   := array_fill(0::numeric, ARRAY[15]);
del_arr   := array_fill(NULL::timestamp, ARRAY[15]);

IF selected_c_id IS NULL THEN
-- no customer found: return row with nulls and padded arrays
RETURN QUERY SELECT
NULL::integer, NULL::varchar, NULL::char(2), NULL::numeric,
NULL::integer, NULL::timestamp, NULL::integer,
supply_arr, i_arr, qty_arr, amt_arr, del_arr;
RETURN;
END IF;

-- 2) Find the most recent order for that customer
SELECT o.o_id, o.o_entry_d, o.o_carrier_id
INTO found_o_id, found_o_entry, found_o_carrier
FROM bmsql_oorder o
WHERE o.o_w_id = in_w_id AND o.o_d_id = in_d_id AND o.o_c_id = selected_c_id
ORDER BY o.o_id DESC
LIMIT 1;

IF found_o_id IS NULL THEN
-- customer has no orders: return customer info and empty (padded) arrays
RETURN QUERY SELECT
selected_c_id, sel_first, sel_middle, sel_balance,
NULL::integer, NULL::timestamp, NULL::integer,
supply_arr, i_arr, qty_arr, amt_arr, del_arr;
RETURN;
END IF;

-- 3) Retrieve order-line rows for that order (ordered by ol_number)
SELECT
array_agg(ol.ol_supply_w_id ORDER BY ol.ol_number),
array_agg(ol.ol_i_id       ORDER BY ol.ol_number),
array_agg(ol.ol_quantity   ORDER BY ol.ol_number),
array_agg(ol.ol_amount     ORDER BY ol.ol_number),
array_agg(ol.ol_delivery_d ORDER BY ol.ol_number)
INTO tmp_supply, tmp_i_ids, tmp_qty, tmp_amt, tmp_del
FROM bmsql_order_line ol
WHERE ol.ol_w_id = in_w_id AND ol.ol_d_id = in_d_id AND ol.ol_o_id = found_o_id;

IF tmp_i_ids IS NULL THEN
n := 0;
ELSE
n := array_length(tmp_i_ids, 1);
END IF;

-- initialize padded arrays (already initialized above, but reassign to ensure types)
supply_arr := array_fill(0, ARRAY[15]);
i_arr     := array_fill(0, ARRAY[15]);
qty_arr   := array_fill(0, ARRAY[15]);
amt_arr   := array_fill(0::numeric, ARRAY[15]);
del_arr   := array_fill(NULL::timestamp, ARRAY[15]);

-- copy up to 15 elements from retrieved arrays into fixed-size arrays
IF n > 0 THEN
FOR idx IN 1..LEAST(n, 15) LOOP
supply_arr[idx] := tmp_supply[idx];
i_arr[idx]      := tmp_i_ids[idx];
qty_arr[idx]    := tmp_qty[idx];
amt_arr[idx]    := tmp_amt[idx];
del_arr[idx]    := tmp_del[idx];
END LOOP;
END IF;

-- return the single result row
RETURN QUERY SELECT
selected_c_id, sel_first, sel_middle, sel_balance,
found_o_id, found_o_entry, found_o_carrier,
supply_arr, i_arr, qty_arr, amt_arr, del_arr;

RETURN;
END;
$$;
