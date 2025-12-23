CREATE OR REPLACE FUNCTION bmsql_proc_delivery(
    IN in_w_id integer,
    IN in_o_carrier_id integer,
    IN in_ol_delivery_d timestamp,
    OUT delivered_o_id integer[]
)
AS $$
DECLARE
    d_id integer;
    o_id_to_deliver integer;
    c_id_for_order integer;
    ol_amount_total decimal(12, 2);
BEGIN
    delivered_o_id := ARRAY[]::integer[];

    FOR d_id IN 1..10 LOOP
        -- Find the oldest new order for this district
        -- Using FOR UPDATE SKIP LOCKED to avoid blocking on a busy district
        -- and allow other delivery transactions to proceed with other districts.
        SELECT no_o_id
        INTO o_id_to_deliver
        FROM bmsql_new_order
        WHERE no_w_id = in_w_id AND no_d_id = d_id
        ORDER BY no_o_id ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        -- If no order was found for this district, skip to the next one
        IF NOT FOUND THEN
            CONTINUE;
        END IF;

        -- Delete the new order record
        DELETE FROM bmsql_new_order
        WHERE no_w_id = in_w_id AND no_d_id = d_id AND no_o_id = o_id_to_deliver;

        -- Update the order and get the customer ID
        UPDATE bmsql_oorder
        SET o_carrier_id = in_o_carrier_id
        WHERE o_w_id = in_w_id AND o_d_id = d_id AND o_id = o_id_to_deliver
        RETURNING o_c_id INTO c_id_for_order;

        -- Update order lines and calculate the total amount
        WITH updated_lines AS (
            UPDATE bmsql_order_line
            SET ol_delivery_d = in_ol_delivery_d
            WHERE ol_w_id = in_w_id AND ol_d_id = d_id AND ol_o_id = o_id_to_deliver
            RETURNING ol_amount
        )
        SELECT sum(ol.ol_amount)
        INTO ol_amount_total
        FROM updated_lines AS ol;

        -- Update the customer's balance and delivery count
        UPDATE bmsql_customer
        SET c_balance = c_balance + ol_amount_total,
            c_delivery_cnt = c_delivery_cnt + 1
        WHERE c_w_id = in_w_id AND c_d_id = d_id AND c_id = c_id_for_order;

        -- Add the delivered order ID to our result array
        delivered_o_id := array_append(delivered_o_id, o_id_to_deliver);

    END LOOP;
END;
$$ LANGUAGE plpgsql;