CREATE OR REPLACE FUNCTION delivery(
    w_id_in integer,
    o_carrier_id_in integer,
    ol_delivery_d_in timestamp
) RETURNS integer[] AS $$
DECLARE
    d_id integer;
    o_id integer;
    c_id integer;
    ol_total decimal(12, 2);
    delivered_o_ids integer[] := '{}';
BEGIN
    FOR d_id IN 1..10 LOOP
        -- Find the oldest undelivered order for this district
        SELECT no_o_id
        INTO o_id
        FROM bmsql_new_order
        WHERE no_w_id = w_id_in AND no_d_id = d_id
        ORDER BY no_o_id ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        -- If no order was found, skip to the next district
        IF o_id IS NULL THEN
            CONTINUE;
        END IF;

        -- Delete the new order record
        DELETE FROM bmsql_new_order
        WHERE no_w_id = w_id_in AND no_d_id = d_id AND no_o_id = o_id;

        -- Update the order with the carrier ID and get the customer ID
        UPDATE bmsql_oorder
        SET o_carrier_id = o_carrier_id_in
        WHERE o_w_id = w_id_in AND o_d_id = d_id AND o_id = o_id
        RETURNING o_c_id INTO c_id;

        -- Update order lines with the delivery date and get the total amount
        WITH updated_ol AS (
            UPDATE bmsql_order_line
            SET ol_delivery_d = ol_delivery_d_in
            WHERE ol_w_id = w_id_in AND ol_d_id = d_id AND ol_o_id = o_id
            RETURNING ol_amount
        )
        SELECT SUM(updated_ol.ol_amount)
        INTO ol_total
        FROM updated_ol;

        -- Update the customer's balance and delivery count
        UPDATE bmsql_customer
        SET c_balance = c_balance + ol_total,
            c_delivery_cnt = c_delivery_cnt + 1
        WHERE c_w_id = w_id_in AND c_d_id = d_id AND c_id = c_id;

        -- Add the delivered order ID to our result array
        delivered_o_ids := array_append(delivered_o_ids, o_id);

    END LOOP;

    RETURN delivered_o_ids;
END;
$$ LANGUAGE plpgsql;