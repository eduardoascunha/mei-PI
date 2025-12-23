CREATE OR REPLACE FUNCTION delivery_transaction(p_w_id integer, p_o_carrier_id integer, p_ol_delivery_d timestamp)
RETURNS integer[] AS
$$
DECLARE
d_id integer;
v_no_o_id integer;
v_o_c_id integer;
v_sum_amount numeric(12,2);
v_delivered_ids integer[] := '{}';
BEGIN
FOR d_id IN 1..10 LOOP
-- try to atomically select and remove the oldest new-order for this district
WITH sel AS (
SELECT no2.no_o_id, no2.ctid
FROM bmsql_new_order no2
WHERE no2.no_w_id = p_w_id
AND no2.no_d_id = d_id
ORDER BY no2.no_o_id
FOR UPDATE SKIP LOCKED
LIMIT 1
)
DELETE FROM bmsql_new_order no
USING sel
WHERE no.ctid = sel.ctid
RETURNING no.no_o_id INTO v_no_o_id;


IF v_no_o_id IS NULL THEN
  -- no outstanding order for this district; skip
  CONTINUE;
END IF;

-- update ORDER (oorder): set carrier and retrieve customer id
v_o_c_id := NULL;
UPDATE bmsql_oorder o
SET o_carrier_id = p_o_carrier_id
WHERE o.o_w_id = p_w_id
  AND o.o_d_id = d_id
  AND o.o_id = v_no_o_id
RETURNING o.o_c_id INTO v_o_c_id;

IF v_o_c_id IS NULL THEN
  -- This should not normally happen; continue to next district
  CONTINUE;
END IF;

-- sum order-line amounts for the order
SELECT COALESCE(SUM(ol.ol_amount),0) INTO v_sum_amount
FROM bmsql_order_line ol
WHERE ol.ol_w_id = p_w_id
  AND ol.ol_d_id = d_id
  AND ol.ol_o_id = v_no_o_id;

-- update all matching order-line delivery dates
UPDATE bmsql_order_line ol
SET ol_delivery_d = COALESCE(p_ol_delivery_d, clock_timestamp())
WHERE ol.ol_w_id = p_w_id
  AND ol.ol_d_id = d_id
  AND ol.ol_o_id = v_no_o_id;

-- update customer balance and delivery count
UPDATE bmsql_customer c
SET c_balance = c.c_balance + v_sum_amount,
    c_delivery_cnt = COALESCE(c.c_delivery_cnt,0) + 1
WHERE c.c_w_id = p_w_id
  AND c.c_d_id = d_id
  AND c.c_id = v_o_c_id;

-- record delivered order id
v_delivered_ids := array_append(v_delivered_ids, v_no_o_id);

-- reset loop variables for next iteration
v_no_o_id := NULL;
v_o_c_id := NULL;
v_sum_amount := 0;


END LOOP;

RETURN v_delivered_ids;
END;
$$
LANGUAGE plpgsql;
