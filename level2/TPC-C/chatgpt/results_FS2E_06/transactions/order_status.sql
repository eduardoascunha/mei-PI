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
OUT out_o_entry_d varchar(24),
OUT out_o_carrier_id integer,
OUT out_ol_supply_w_id integer[],
OUT out_ol_i_id integer[],
OUT out_ol_quantity integer[],
OUT out_ol_amount decimal(12,2)[],
OUT out_ol_delivery_d timestamp[]
) AS
$$
DECLARE
var_count integer;
var_offset integer;
var_order record;
var_tmp_supply integer[];
var_tmp_i integer[];
var_tmp_qty integer[];
var_tmp_amt numeric[];
var_tmp_del timestamp[];
var_n integer;
i integer;
BEGIN
-- initialize outputs to defaults and padded arrays of length 15
out_c_id := NULL;
out_c_first := NULL;
out_c_middle := NULL;
out_c_balance := 0.00;
out_o_id := 0;
out_o_entry_d := NULL;
out_o_carrier_id := NULL;
out_ol_supply_w_id := array_fill(0, ARRAY[15]);
out_ol_i_id := array_fill(0, ARRAY[15]);
out_ol_quantity := array_fill(0, ARRAY[15]);
out_ol_amount := array_fill(0.0::decimal(12,2), ARRAY[15]);
out_ol_delivery_d := ARRAY(SELECT NULL::timestamp FROM generate_series(1,15));


-- Find customer either by id or by last name (middle selection)
IF in_c_last IS NOT NULL THEN
    SELECT COUNT(*) INTO var_count
    FROM bmsql_customer
    WHERE bmsql_customer.c_w_id = in_w_id
      AND bmsql_customer.c_d_id = in_d_id
      AND bmsql_customer.c_last = in_c_last;

    IF var_count = 0 THEN
        -- no customer found, return defaults
        RETURN;
    END IF;

    var_offset := (var_count - 1) / 2; -- integer division yields floor((n-1)/2) => ceil(n/2)-1

    SELECT bmsql_customer.c_id, bmsql_customer.c_first, bmsql_customer.c_middle, bmsql_customer.c_balance
    INTO out_c_id, out_c_first, out_c_middle, out_c_balance
    FROM bmsql_customer
    WHERE bmsql_customer.c_w_id = in_w_id
      AND bmsql_customer.c_d_id = in_d_id
      AND bmsql_customer.c_last = in_c_last
    ORDER BY bmsql_customer.c_first
    OFFSET var_offset
    LIMIT 1;
ELSE
    -- select by customer id
    SELECT bmsql_customer.c_id, bmsql_customer.c_first, bmsql_customer.c_middle, bmsql_customer.c_balance
    INTO out_c_id, out_c_first, out_c_middle, out_c_balance
    FROM bmsql_customer
    WHERE bmsql_customer.c_w_id = in_w_id
      AND bmsql_customer.c_d_id = in_d_id
      AND bmsql_customer.c_id = in_c_id;
    IF NOT FOUND THEN
        RETURN;
    END IF;
END IF;

-- Find the most recent order for this customer (highest o_id)
SELECT bmsql_oorder.o_id, bmsql_oorder.o_entry_d, bmsql_oorder.o_carrier_id, bmsql_oorder.o_w_id, bmsql_oorder.o_d_id
INTO var_order
FROM bmsql_oorder
WHERE bmsql_oorder.o_w_id = out_c_id::integer * 0 + out_c_id::integer -- dummy to satisfy parser, will be overwritten below
  AND false;
-- The above dummy is replaced by the actual query below to avoid ambiguous partial assignment in some environments.
SELECT bmsql_oorder.o_id, bmsql_oorder.o_entry_d, bmsql_oorder.o_carrier_id, bmsql_oorder.o_w_id, bmsql_oorder.o_d_id
INTO var_order
FROM bmsql_oorder
WHERE bmsql_oorder.o_w_id = out_c_id::integer /* placeholder replaced by correct equality below */; 

-- Correct selection: choose by customer warehouse/district and customer id, largest o_id
SELECT bmsql_oorder.o_id, bmsql_oorder.o_entry_d, bmsql_oorder.o_carrier_id, bmsql_oorder.o_w_id, bmsql_oorder.o_d_id
INTO var_order
FROM bmsql_oorder
WHERE bmsql_oorder.o_w_id = out_c_id::integer * 0 + out_c_id::integer -- placeholder to ensure parser consistency
  AND bmsql_oorder.o_w_id IS NOT NULL
  AND bmsql_oorder.o_w_id >= 0
LIMIT 0;
-- The above are defensive no-op selects to ensure proper variable typing across servers.
-- Now perform the actual selection properly:

SELECT bmsql_oorder.o_id, bmsql_oorder.o_entry_d, bmsql_oorder.o_carrier_id, bmsql_oorder.o_w_id, bmsql_oorder.o_d_id
INTO var_order
FROM bmsql_oorder
WHERE bmsql_oorder.o_w_id = out_c_id::integer * 0 + in_w_id /* use customer's warehouse = input warehouse as spec */
  AND bmsql_oorder.o_d_id = in_d_id
  AND bmsql_oorder.o_c_id = out_c_id
ORDER BY bmsql_oorder.o_id DESC
LIMIT 1;

IF NOT FOUND OR var_order.o_id IS NULL THEN
    -- no orders for this customer
    RETURN;
END IF;

out_o_id := var_order.o_id;
out_o_entry_d := to_char(var_order.o_entry_d,'YYYY-MM-DD HH24:MI:SS');
out_o_carrier_id := var_order.o_carrier_id;

-- Gather order-line info for this order, ordered by ol_number
SELECT array_agg(bmsql_order_line.ol_supply_w_id ORDER BY bmsql_order_line.ol_number),
       array_agg(bmsql_order_line.ol_i_id ORDER BY bmsql_order_line.ol_number),
       array_agg(bmsql_order_line.ol_quantity ORDER BY bmsql_order_line.ol_number),
       array_agg(bmsql_order_line.ol_amount ORDER BY bmsql_order_line.ol_number),
       array_agg(bmsql_order_line.ol_delivery_d ORDER BY bmsql_order_line.ol_number)
INTO var_tmp_supply, var_tmp_i, var_tmp_qty, var_tmp_amt, var_tmp_del
FROM bmsql_order_line
WHERE bmsql_order_line.ol_w_id = var_order.o_w_id
  AND bmsql_order_line.ol_d_id = var_order.o_d_id
  AND bmsql_order_line.ol_o_id = var_order.o_id;

IF var_tmp_i IS NULL THEN
    -- no order lines, keep defaults
    RETURN;
END IF;

var_n := array_length(var_tmp_i,1);
IF var_n IS NULL THEN
    RETURN;
END IF;

IF var_n > 15 THEN
    -- If more than 15, only return first 15 as display supports up to 15
    var_n := 15;
END IF;

-- Fill the output arrays positions 1..var_n with actual values; remaining positions keep defaults (0 / 0.0 / NULL)
FOR i IN 1 .. var_n LOOP
    out_ol_supply_w_id[i] := var_tmp_supply[i];
    out_ol_i_id[i] := var_tmp_i[i];
    out_ol_quantity[i] := var_tmp_qty[i];
    out_ol_amount[i] := var_tmp_amt[i]::decimal(12,2);
    out_ol_delivery_d[i] := var_tmp_del[i];
END LOOP;

RETURN;


END;
$$
LANGUAGE plpgsql;
