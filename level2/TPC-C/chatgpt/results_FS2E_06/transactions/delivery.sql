CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
IN in_w_id integer,
IN in_o_carrier_id integer,
IN in_ol_delivery_d timestamp
)
RETURNS integer[] AS
$$
DECLARE
v_d_id integer;
v_no_o_id integer;
v_o_c_id integer;
v_ol_sum numeric(12,2);
v_delivered_ids integer[] := ARRAY[]::integer[];
BEGIN
FOR v_d_id IN 1..10 LOOP
-- Find the oldest new order for this district
SELECT no_o_id
INTO v_no_o_id
FROM bmsql_new_order
WHERE no_w_id = in_w_id AND no_d_id = v_d_id
ORDER BY no_o_id
LIMIT 1
FOR UPDATE;


    IF NOT FOUND THEN
        -- no outstanding order for this district: skip
        CONTINUE;
    END IF;

    -- Remove the new-order entry (delete the selected row)
    DELETE FROM bmsql_new_order
    WHERE no_w_id = in_w_id AND no_d_id = v_d_id AND no_o_id = v_no_o_id;

    -- Retrieve the order's customer id and update the carrier on the order
    UPDATE bmsql_oorder o
    SET o_carrier_id = in_o_carrier_id
    WHERE o.o_w_id = in_w_id AND o.o_d_id = v_d_id AND o.o_id = v_no_o_id
    RETURNING o.o_c_id INTO v_o_c_id;

    -- Sum the order-line amounts for this order
    SELECT COALESCE(SUM(ol.ol_amount),0)
    INTO v_ol_sum
    FROM bmsql_order_line ol
    WHERE ol.ol_w_id = in_w_id AND ol.ol_d_id = v_d_id AND ol.ol_o_id = v_no_o_id;

    -- Update delivery date for each order-line of this order
    UPDATE bmsql_order_line ol
    SET ol_delivery_d = in_ol_delivery_d
    WHERE ol.ol_w_id = in_w_id AND ol.ol_d_id = v_d_id AND ol.ol_o_id = v_no_o_id;

    -- Update the customer's balance and delivery count
    UPDATE bmsql_customer c
    SET c_balance = c.c_balance + v_ol_sum,
        c_delivery_cnt = c.c_delivery_cnt + 1
    WHERE c.c_w_id = in_w_id AND c.c_d_id = v_d_id AND c.c_id = v_o_c_id;

    -- Record this delivered order id in the result array
    v_delivered_ids := array_append(v_delivered_ids, v_no_o_id);
END LOOP;

RETURN v_delivered_ids;


END;
$$
LANGUAGE plpgsql;
