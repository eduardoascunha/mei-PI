CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
    IN in_w_id integer,
    IN in_o_carrier_id integer,
    IN in_ol_delivery_d timestamp
) RETURNS TABLE(delivered_o_id integer) AS $$
DECLARE
    d_id integer;
    v_o_id integer;
    v_c_id integer;
    v_ol_total decimal(12, 2);
BEGIN
    FOR d_id IN 1..10 LOOP
        -- Find the oldest, undelivered order for this district
        -- Use FOR UPDATE SKIP LOCKED to handle concurrency
        SELECT no_o_id INTO v_o_id
        FROM bmsql_new_order
        WHERE no_w_id = in_w_id AND no_d_id = d_id
        ORDER BY no_o_id ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        -- If no order was found, skip to the next district
        IF NOT FOUND THEN
            CONTINUE;
        END IF;

        -- Delete the new_order row
        DELETE FROM bmsql_new_order
        WHERE no_w_id = in_w_id AND no_d_id = d_id AND no_o_id = v_o_id;

        -- Update the order with the carrier ID and get the customer ID
        UPDATE bmsql_oorder
        SET o_carrier_id = in_o_carrier_id
        WHERE o_w_id = in_w_id AND o_d_id = d_id AND o_id = v_o_id
        RETURNING o_c_id INTO v_c_id;

        -- Update the order lines with the delivery date and calculate the total amount
        WITH updated_ol AS (
            UPDATE bmsql_order_line
            SET ol_delivery_d = in_ol_delivery_d
            WHERE ol_w_id = in_w_id AND ol_d_id = d_id AND ol_o_id = v_o_id
            RETURNING ol_amount
        )
        SELECT sum(ol_amount) INTO v_ol_total FROM updated_ol;

        -- Update the customer's balance and delivery count
        UPDATE bmsql_customer
        SET c_balance = c_balance + v_ol_total,
            c_delivery_cnt = c_delivery_cnt + 1
        WHERE c_w_id = in_w_id AND c_d_id = d_id AND c_id = v_c_id;

        -- Return the delivered order ID for this district
        delivered_o_id := v_o_id;
        RETURN NEXT;

    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;