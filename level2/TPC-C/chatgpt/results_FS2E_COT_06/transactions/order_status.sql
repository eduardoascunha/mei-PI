CREATE OR REPLACE FUNCTION bmsql_proc_order_status(
IN in_w_id integer,
IN in_d_id integer,
IN in_c_id integer,
IN in_c_last varchar(16),
OUT out_c_id integer,
OUT out_c_first varchar(16),
OUT out_c_middle char(2),
OUT out_c_balance decimal(12,2),
OUT out_o_id integer,
OUT out_o_entry_d timestamp,
OUT out_o_carrier_id integer,
OUT out_ol_supply_w_id integer[],
OUT out_ol_i_id integer[],
OUT out_ol_quantity integer[],
OUT out_ol_amount decimal(12,2)[],
OUT out_ol_delivery_d timestamp[]
) AS
$$
DECLARE
var_n integer;
var_offset integer;
rec_order record;
rec_ol record;
idx integer := 1;
BEGIN
-- Initialize outputs with defaults and padded arrays of length 15
out_c_id := 0;
out_c_first := NULL;
out_c_middle := NULL;
out_c_balance := 0.00;
out_o_id := 0;
out_o_entry_d := NULL;
out_o_carrier_id := NULL;
out_ol_supply_w_id := array_fill(0, ARRAY[15]);
out_ol_i_id := array_fill(0, ARRAY[15]);
out_ol_quantity := array_fill(0, ARRAY[15]);
out_ol_amount := array_fill(0.0::numeric(12,2), ARRAY[15]);
out_ol_delivery_d := array_fill(NULL::timestamp, ARRAY[15]);


-- Determine customer by last name or by id
IF in_c_id IS NULL OR in_c_id = 0 THEN
    -- Use last name selection
    SELECT COUNT(*) INTO var_n
    FROM bmsql_customer c
    WHERE c.c_w_id = in_w_id
      AND c.c_d_id = in_d_id
      AND c.c_last = in_c_last;

    IF var_n = 0 THEN
        -- No customer found; return defaults
        RETURN;
    END IF;

    var_offset := (var_n - 1) / 2; -- floor((n-1)/2) gives ceil(n/2)-1

    SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
    INTO out_c_id, out_c_first, out_c_middle, out_c_balance
    FROM bmsql_customer c
    WHERE c.c_w_id = in_w_id
      AND c.c_d_id = in_d_id
      AND c.c_last = in_c_last
    ORDER BY c.c_first ASC
    OFFSET var_offset LIMIT 1;
ELSE
    -- Use customer id selection
    SELECT c.c_id, c.c_first, c.c_middle, c.c_balance
    INTO out_c_id, out_c_first, out_c_middle, out_c_balance
    FROM bmsql_customer c
    WHERE c.c_w_id = in_w_id
      AND c.c_d_id = in_d_id
      AND c.c_id = in_c_id;
    IF NOT FOUND THEN
        -- No customer found; return defaults
        RETURN;
    END IF;
END IF;

-- Find the most recent order for this customer
SELECT o.o_id, o.o_entry_d, o.o_carrier_id
INTO rec_order
FROM bmsql_oorder o
WHERE o.o_w_id = in_w_id
  AND o.o_d_id = in_d_id
  AND o.o_c_id = out_c_id
ORDER BY o.o_id DESC
LIMIT 1;

IF NOT FOUND THEN
    -- Customer has no orders; return customer info with empty order fields
    RETURN;
END IF;

out_o_id := rec_order.o_id;
out_o_entry_d := rec_order.o_entry_d;
out_o_carrier_id := rec_order.o_carrier_id;

-- Retrieve order lines for that order, fill arrays up to 15 entries
FOR rec_ol IN
    SELECT ol.ol_supply_w_id, ol.ol_i_id, ol.ol_quantity, ol.ol_amount, ol.ol_delivery_d
    FROM bmsql_order_line ol
    WHERE ol.ol_w_id = in_w_id
      AND ol.ol_d_id = in_d_id
      AND ol.ol_o_id = out_o_id
    ORDER BY ol.ol_number
LOOP
    EXIT WHEN idx > 15;
    out_ol_supply_w_id[idx] := rec_ol.ol_supply_w_id;
    out_ol_i_id[idx] := rec_ol.ol_i_id;
    out_ol_quantity[idx] := rec_ol.ol_quantity;
    out_ol_amount[idx] := rec_ol.ol_amount;
    out_ol_delivery_d[idx] := rec_ol.ol_delivery_d;
    idx := idx + 1;
END LOOP;

-- Remaining positions (if any) are already padded with defaults from initialization

RETURN;


END;
$$
LANGUAGE plpgsql;
