CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
IN in_w_id integer,
IN in_o_carrier_id integer,
IN in_ol_delivery_d timestamp
) RETURNS integer[] AS
$$
DECLARE
v_d integer;
v_no_o_id integer;
v_o_c_id integer;
v_ol_total numeric(18,2);
v_delivery timestamp := COALESCE(in_ol_delivery_d, CURRENT_TIMESTAMP);
v_result integer[] := ARRAY[]::integer[];
BEGIN
-- Process districts 1..10 for the given warehouse
FOR v_d IN 1..10 LOOP
-- Find the oldest new order (lowest no_o_id) for this district
SELECT no_o_id
INTO v_no_o_id
FROM bmsql_new_order
WHERE no_w_id = in_w_id
AND no_d_id = v_d
ORDER BY no_o_id
LIMIT 1;


    -- If no undelivered order for this district, skip it
    IF v_no_o_id IS NULL THEN
        CONTINUE;
    END IF;

    -- Delete the new_order entry for this order (remove from new-order list)
    DELETE FROM bmsql_new_order
     WHERE no_w_id = in_w_id
       AND no_d_id = v_d
       AND no_o_id = v_no_o_id;

    -- Select the order and update its carrier id
    SELECT o_c_id
      INTO v_o_c_id
      FROM bmsql_oorder
     WHERE o_w_id = in_w_id
       AND o_d_id = v_d
       AND o_id = v_no_o_id
     FOR UPDATE;

    IF FOUND THEN
        UPDATE bmsql_oorder
           SET o_carrier_id = in_o_carrier_id
         WHERE o_w_id = in_w_id
           AND o_d_id = v_d
           AND o_id = v_no_o_id;
    ELSE
        -- If order row no longer exists, skip this district
        CONTINUE;
    END IF;

    -- Sum all order-line amounts for this order
    SELECT COALESCE(SUM(ol_amount),0)
      INTO v_ol_total
      FROM bmsql_order_line
     WHERE ol_w_id = in_w_id
       AND ol_d_id = v_d
       AND ol_o_id = v_no_o_id;

    -- Update order-line delivery date for all lines of this order
    UPDATE bmsql_order_line
       SET ol_delivery_d = v_delivery
     WHERE ol_w_id = in_w_id
       AND ol_d_id = v_d
       AND ol_o_id = v_no_o_id;

    -- Update the customer's balance and delivery count
    UPDATE bmsql_customer
       SET c_balance = c_balance + v_ol_total,
           c_delivery_cnt = c_delivery_cnt + 1
     WHERE c_w_id = in_w_id
       AND c_d_id = v_d
       AND c_id = v_o_c_id;

    -- Record delivered order id for output
    v_result := array_append(v_result, v_no_o_id);

    -- reset v_no_o_id for next iteration
    v_no_o_id := NULL;
END LOOP;

RETURN v_result;


END;
$$
LANGUAGE plpgsql;
