CREATE OR REPLACE FUNCTION delivery_transaction(
p_w_id integer,
p_o_carrier_id integer,
p_ol_delivery_d timestamp
) RETURNS integer[] AS
$$
DECLARE
delivered_oids integer[] := ARRAY[]::integer[];
v_d_id integer;
v_o_id integer;
v_o_c_id integer;
v_sum_amount numeric(12,2);
v_delivery_ts timestamp := COALESCE(p_ol_delivery_d, now());
BEGIN
-- For each district 1..10 attempt to deliver the oldest new-order (lowest NO_O_ID)
FOR v_d_id IN 1..10 LOOP
-- Find the oldest undelivered order for this district (if any), using FOR UPDATE SKIP LOCKED to avoid conflicts
SELECT no.no_o_id
INTO v_o_id
FROM bmsql_new_order no
WHERE no.no_w_id = p_w_id
AND no.no_d_id = v_d_id
ORDER BY no.no_o_id ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- If no outstanding new order for this district, skip
IF NOT FOUND THEN
  CONTINUE;
END IF;

-- Delete the selected new-order row (the oldest undelivered order)
DELETE FROM bmsql_new_order no
WHERE no.no_w_id = p_w_id
  AND no.no_d_id = v_d_id
  AND no.no_o_id = v_o_id;

-- Retrieve the customer id from the order and update the order's carrier id
SELECT o.o_c_id
  INTO v_o_c_id
FROM bmsql_oorder o
WHERE o.o_w_id = p_w_id
  AND o.o_d_id = v_d_id
  AND o.o_id = v_o_id
FOR UPDATE;

IF NOT FOUND THEN
  -- If order row missing unexpectedly, skip this district
  CONTINUE;
END IF;

UPDATE bmsql_oorder o
SET o_carrier_id = p_o_carrier_id
WHERE o.o_w_id = p_w_id
  AND o.o_d_id = v_d_id
  AND o.o_id = v_o_id;

-- Sum the order-line amounts and set delivery date for each order-line
SELECT COALESCE(SUM(ol.ol_amount), 0::numeric) INTO v_sum_amount
FROM bmsql_order_line ol
WHERE ol.ol_w_id = p_w_id
  AND ol.ol_d_id = v_d_id
  AND ol.ol_o_id = v_o_id;

UPDATE bmsql_order_line ol
SET ol_delivery_d = v_delivery_ts
WHERE ol.ol_w_id = p_w_id
  AND ol.ol_d_id = v_d_id
  AND ol.ol_o_id = v_o_id;

-- Update the customer's balance and delivery count
UPDATE bmsql_customer c
SET c_balance = c.c_balance + v_sum_amount,
    c_delivery_cnt = c.c_delivery_cnt + 1
WHERE c.c_w_id = p_w_id
  AND c.c_d_id = v_d_id
  AND c.c_id = v_o_c_id;

-- Record delivered order id in result array
delivered_oids := array_append(delivered_oids, v_o_id);

END LOOP;

RETURN delivered_oids;
END;
$$ LANGUAGE plpgsql;
